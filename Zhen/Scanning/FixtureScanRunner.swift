import Foundation
import ZhenCore
import ZhenScan

/// Replays the invented network, at a pace, as the engine would report it.
///
/// It goes through the same `HistoryStore` calls the engine does — `record` for a scan,
/// `recordPorts` for a probe — so what a test or a preview sees afterwards is what history
/// would hold, not a second idea of it.
nonisolated struct FixtureScanRunner: ScanRunning {
  let store: any HistoryStore
  let capture: ScanReport
  let pace: Duration
  let clock: any Clock<Duration>

  func interface() async -> NetworkInterface? { FixtureNetwork.interface(for: capture) }

  func capabilities() async -> EngineCapabilities { [.icmpSweep, .connectScan, .bannerProbe] }

  func run(_ request: ScanRequest, progress: ProgressSink) async -> ScanOutcome {
    let started = Timestamp.now
    let fresh = FixtureNetwork.ipadReport(from: capture, now: .now, ago: .zero)
    let network = fresh.run.target
    var stages: [StageTiming] = []
    var found: [Device] = []

    progress(.stageStarted(.discovery))
    for (index, device) in fresh.devices.enumerated() {
      guard await pause() else { break }
      found.append(device)
      progress(.hostFound(Self.facts(device)))
      progress(.stageProgress(.discovery, completed: index + 1, total: fresh.devices.count))
    }
    stages.append(StageTiming(stage: .discovery, elapsedMillis: Self.elapsed(since: started)))
    progress(.stageFinished(stages[stages.count - 1]))

    let known = await store.firstSeen(for: found.map(Self.facts), in: network)
    let probed = Set(request.ports.targets(among: found.compactMap(\.ipv4Addresses.first), known: known))

    var run = fresh.run
    run.startedAt = started
    run.finishedAt = .now
    run.outcome = Task.isCancelled ? .cancelled : .complete
    run.timing = Timing(
      stages: stages,
      counters: ProbeCounterSnapshot(probesSent: 0, repliesSeen: 0, peakConcurrency: 0, inFlight: 0)
    )
    let report = ScanReport(
      run: run,
      devices: found.map { device in
        var seen = device
        // Ports only where this scan's port stage reached; history keeps older ones.
        if let address = seen.ipv4Addresses.first, probed.contains(address) {
          seen.ports = Self.observations(for: device, at: address, spec: .commonServices)
        } else {
          seen.ports = []
        }
        return seen
      }
    )
    return .finished(CompletedScan(report: report, events: await store.record(report)))
  }

  func probePorts(_ request: PortProbeRequest, progress: ProgressSink) async -> PortProbeOutcome {
    let fresh = FixtureNetwork.ipadReport(from: capture, now: .now, ago: .zero)
    progress(.stageStarted(.deepScan))
    var ports: [IPAddress: [PortObservation]] = [:]
    for case .v4(let address) in request.addresses {
      guard await pause() else { break }
      guard let device = fresh.devices.first(where: { $0.ipv4Addresses.contains(address) }) else { continue }
      ports[.v4(address)] = Self.observations(for: device, at: address, spec: request.spec)
    }
    let result = PortScanResult(
      ports: ports,
      usedCapabilities: request.spec.udpPorts.isEmpty
        ? [.connectScan, .bannerProbe]
        : [.connectScan, .bannerProbe, .udpScan],
      outcome: Task.isCancelled ? .cancelled : .complete
    )
    let events = await store.recordPorts(result, targeted: request.addresses, at: .now)
    return .finished(CompletedPortScan(result: result, events: events))
  }

  /// What a probe of `spec` finds on a fixture device.
  ///
  /// TCP: the capture's open ports where the spec asks for them, and `closed` for every
  /// other port asked about. UDP: a few invented answers a home network plausibly gives —
  /// DNS on the hosts serving it over TCP, Bonjour on the Apple devices, NetBIOS on the
  /// Windows one — and `closed` elsewhere, which is what an ICMP port-unreachable says.
  static func observations(for device: Device, at address: IPv4Address, spec: PortSpec) -> [PortObservation] {
    let open = Dictionary(
      device.ports.filter { $0.proto == .tcp && $0.state == .open }.map { ($0.port, $0) },
      uniquingKeysWith: { first, _ in first }
    )
    let tcp = spec.ports.map { port in
      var observation = open[port] ?? PortObservation(port: port, proto: .tcp, state: .closed)
      observation.address = .v4(address)
      return observation
    }
    let udpOpen = udpAnswers(for: device)
    let udp = spec.udpPorts.map { port in
      PortObservation(
        port: port, proto: .udp, state: udpOpen[port] == nil ? .closed : .open,
        service: udpOpen[port], address: .v4(address)
      )
    }
    return (tcp + udp).sorted(by: PortObservation.canonicalOrder)
  }

  private static func udpAnswers(for device: Device) -> [UInt16: ServiceIdentity] {
    var answers: [UInt16: ServiceIdentity] = [:]
    if device.ports.contains(where: { $0.port == 53 && $0.state == .open }) {
      answers[53] = ServiceIdentity(name: "dns", evidence: .protocolHandshake)
    }
    if device.names.contains(where: { $0.source == .mdns }) {
      answers[5353] = ServiceIdentity(name: "mdns", evidence: .protocolHandshake)
    }
    if device.names.contains(where: { $0.source == .netbios }) {
      answers[137] = ServiceIdentity(name: "netbios-ns", evidence: .protocolHandshake)
    }
    return answers
  }

  private func pause() async -> Bool {
    do {
      try await clock.sleep(for: pace)
      return true
    } catch {
      return false
    }
  }

  private static func elapsed(since start: Timestamp) -> Double {
    Double(Timestamp.now.millisecondsSinceEpoch - start.millisecondsSinceEpoch)
  }

  static func facts(_ device: Device) -> HostFacts {
    HostFacts(
      ip: device.ipv4Addresses.first ?? IPv4Address(raw: 0),
      allNames: device.names,
      ttl: device.ttl,
      rtt: device.rtt,
      discoveredVia: Set(device.discoveredVia)
    )
  }
}
