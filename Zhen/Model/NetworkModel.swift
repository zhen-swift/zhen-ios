import Foundation
import Observation
import ZhenCore
import ZhenScan

/// The network as this app knows it: the devices in history, the latest run, the scan in
/// progress, and the port scans run this session.
///
/// One per app, owned by the `App` with `@State`. The work itself runs from the root view's
/// `.task(id:)`s (`ScanHost`), so leaving the scene or pressing Stop cancels it.
@Observable
final class NetworkModel {
  let environment: AppEnvironment
  @ObservationIgnored let store: any HistoryStore
  @ObservationIgnored private let runner: any ScanRunning

  private(set) var devices: [DeviceItem] = []
  private(set) var latestRun: ScanRun?
  /// What went wrong in the latest scan this session. A run the app did not watch — one
  /// recorded before this launch — has none known, rather than a stale list.
  private(set) var lastDegradations: [Degradation] = []
  private(set) var hasLoaded = false
  /// The interface scans go out of, once known.
  private(set) var interface: NetworkInterface?
  /// What the engine can do on this iPad.
  private(set) var capabilities: EngineCapabilities = []

  /// The scan in progress. A new token is a new scan; nil is none.
  private(set) var scanToken: UUID?
  private(set) var scanRequest = ScanRequest()
  /// Hosts reported while the scan runs. Display only: the list comes from history.
  private(set) var liveFound = 0
  /// What the running scan has reported going wrong so far.
  private(set) var liveDegradations: [Degradation] = []

  /// Port scans run this session, by device: whether one is running, what it observed, and
  /// why one found nothing. What it found is folded into history, which the card shows.
  private(set) var portScans: [DeviceItem.ID: PortScan] = [:]
  /// The port scan in flight. The root's `.task(id:)` runs it.
  private(set) var portScanTarget: PortScanTarget?

  init(environment: AppEnvironment) {
    self.environment = environment
    switch environment.dataSource {
    case .live:
      let url = HistoryLocation.resolve(environment: environment.processEnvironment)
      let store: any HistoryStore = url.map { LogHistoryStore(url: $0) } ?? InMemoryHistoryStore()
      self.store = store
      self.runner = LiveScanRunner(store: store)
    case .fixture:
      let store = InMemoryHistoryStore()
      self.store = store
      let capture = (try? FixtureNetwork.capture()) ?? ScanReport(run: Self.emptyRun)
      self.runner = FixtureScanRunner(
        store: store, capture: capture, pace: environment.scanPace, clock: ContinuousClock()
      )
    }
  }

  /// A model over a given store and runner, for tests and previews.
  init(environment: AppEnvironment, store: any HistoryStore, runner: any ScanRunning) {
    self.environment = environment
    self.store = store
    self.runner = runner
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  /// Fills the model, seeding the fixture network first when this launch uses one.
  func load() async {
    if environment.usesFixtures, !hasLoaded, let capture = try? FixtureNetwork.capture() {
      let history = FixtureNetwork.history(
        environment.fixtureVariant, capture: capture, now: environment.launchedAt
      )
      for report in history {
        _ = await store.record(report)
      }
    }
    interface = await runner.interface()
    capabilities = await runner.capabilities()
    await reload()
    hasLoaded = true
  }

  /// Rereads history. Cheap: the store is an actor holding one ledger.
  func reload() async {
    let stored = await store.devices()
    latestRun = await store.latestRun()
    let network = latestRun?.target ?? interface?.network
    devices = DeviceItem.rows(from: stored, network: network)
  }

  func device(_ id: DeviceItem.ID) -> DeviceItem? {
    devices.first { $0.id == id }
  }

  // ── Scanning ───────────────────────────────────────────────────────────────

  var isScanning: Bool { scanToken != nil }

  /// Whether any scan is running. One at a time: a port scan and a sweep would share the
  /// descriptor budget, and a port scan of a host the sweep is about to find is a race.
  var isBusy: Bool { isScanning || portScanTarget != nil }

  /// Starts a scan; the root's `.task(id: scanToken)` runs it.
  func startScan(ports: PortStage = .off) {
    guard !isBusy else { return }
    scanRequest = ScanRequest(ports: ports)
    liveFound = 0
    liveDegradations = []
    scanToken = UUID()
  }

  /// Stops whichever scan is running. What had answered is kept either way.
  func stopScanning() {
    scanToken = nil
    portScanTarget = nil
  }

  /// Runs the scan `startScan` asked for.
  func performScan() async {
    guard let token = scanToken else { return }
    let (events, sink, finish) = ProbeStream.sinking(buffering: .progress)
    let watcher = Task { [weak self] in
      for await event in events {
        switch event {
        case .hostFound: self?.liveFound += 1
        case .degraded(let degradation): self?.liveDegradations.append(degradation)
        default: break
        }
      }
    }
    let outcome = await runner.run(scanRequest, progress: sink)
    finish()
    await watcher.value
    switch outcome {
    case .finished(let completed):
      lastDegradations = completed.report.degradations
      // History now holds ports at least as fresh as anything scanned this session.
      if scanRequest.ports != .off { portScans = [:] }
    case .unavailable(let degradation):
      lastDegradations = [degradation]
    }
    interface = await runner.interface() ?? interface
    await reload()
    if scanToken == token { scanToken = nil }
  }

  // ── Port scans ─────────────────────────────────────────────────────────────

  /// Scans the ports of chosen devices, without a sweep and without recording a run.
  ///
  /// Devices with no IPv4 address are skipped: the port engines' banners and the fold
  /// into history are by IPv4 address, and an iPad has no other way to reach them.
  func scanPorts(_ ids: [DeviceItem.ID], spec: PortSpec, budget: Duration) {
    guard !isBusy else { return }
    let members = ids.compactMap { id -> PortScanTarget.Member? in
      guard let item = device(id), let address = item.ipv4 else { return nil }
      return PortScanTarget.Member(id: id, address: address, isOnline: item.isOnline)
    }
    guard !members.isEmpty else { return }
    for member in members {
      portScans[member.id] = PortScan(
        state: .running(probes: spec.probeCount), ports: portScans[member.id]?.ports ?? [], at: .now
      )
    }
    portScanTarget = PortScanTarget(members: members, spec: spec, budget: budget)
  }

  /// Runs the port scan `scanPorts` asked for.
  ///
  /// A probe, not a run: zhen-core folds the ports into the devices history holds and
  /// leaves every other device as it was, so the result survives a relaunch.
  func performPortScan() async {
    guard let target = portScanTarget else { return }
    let outcome = await runner.probePorts(
      PortProbeRequest(
        addresses: target.members.map { .v4($0.address) }, spec: target.spec, budget: target.budget
      ),
      progress: .ignore
    )
    for member in target.members {
      portScans[member.id] = PortScan.result(of: outcome, for: member.address, isOnline: member.isOnline)
    }
    if portScanTarget == target { portScanTarget = nil }
    await reload()
  }

  /// The ports to show for a device: what history holds.
  ///
  /// History merges every scan's answers per port and transport — closed and filtered
  /// included — so it is the one list that agrees with the row's open count. A session
  /// scan adds only what history cannot say: that it is running, why it found nothing, and
  /// how many ports it checked.
  func ports(for item: DeviceItem) -> [PortObservation] {
    item.device.ports.sorted(by: PortObservation.canonicalOrder)
  }

  private static let emptyRun = ScanRun(
    id: UUID(),
    startedAt: Timestamp(millisecondsSinceEpoch: 0),
    target: IPv4Network(base: IPv4Address(raw: 0xC0A8_3200), prefix: 24),
    interface: "en0",
    engine: EngineDescriptor(name: "fixture", kind: .unprivileged, capabilities: []),
    outcome: .complete,
    timing: Timing(
      stages: [],
      counters: ProbeCounterSnapshot(probesSent: 0, repliesSeen: 0, peakConcurrency: 0, inFlight: 0)
    )
  )
}
