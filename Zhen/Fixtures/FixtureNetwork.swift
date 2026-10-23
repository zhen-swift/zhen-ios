import Foundation
import ZhenCore

/// The invented home network that previews, UI tests and `-ShowcaseData` use.
///
/// `showcase-network.json` is zhen-app's invented network — nobody's real home — captured
/// as a Mac sees it. An iPad sees less, and a fixture that showed an iPad more than it can
/// find would be a screenshot of a feature that does not exist. So each device is rebuilt
/// through core's own `Device(observing:)` from only what an iPad would have observed: no
/// hardware address and no vendor (iPadOS withholds the neighbour table), no UPnP names (no
/// SSDP without the multicast entitlement), and no host the ARP cache alone supplied.
nonisolated enum FixtureNetwork {
  /// Which network a fixture launch replays. `-Fixture empty`.
  enum Variant: String, Sendable, CaseIterable {
    /// The invented home network.
    case network
    /// Nothing has ever been scanned.
    case empty
  }

  enum LoadError: Error, Equatable {
    case missing
    case unreadable(String)
  }

  /// The capture, as a Mac recorded it.
  static func capture(in bundle: Bundle = .main) throws(LoadError) -> ScanReport {
    guard let url = bundle.url(forResource: "showcase-network", withExtension: "json") else {
      throw .missing
    }
    do {
      return try ScanReport.makeDecoder().decode(ScanReport.self, from: Data(contentsOf: url))
    } catch {
      throw .unreadable(String(describing: error))
    }
  }

  /// The capture as an iPad would have recorded it, finishing `ago` before `now`.
  static func ipadReport(from capture: ScanReport, now: Date, ago: Duration = .seconds(300)) -> ScanReport {
    let finished = Timestamp(now.addingTimeInterval(-Double(ago.components.seconds)))
    let started = Timestamp(millisecondsSinceEpoch: finished.millisecondsSinceEpoch - 6_000)
    let firstSeen = Timestamp(millisecondsSinceEpoch: finished.millisecondsSinceEpoch - 3 * 86_400_000)
    let network = capture.run.target

    let devices = capture.devices.compactMap { device -> Device? in
      guard let ip = device.ipv4Addresses.first else { return nil }
      let via = Set(device.discoveredVia).subtracting([.neighborTable, .arpReply, .neighborResolved])
      // A host only the ARP cache knew about is a host an iPad never finds.
      guard !via.isEmpty else { return nil }
      let facts = HostFacts(
        ip: ip,
        allNames: device.names.filter { $0.source != .ssdp },
        reverseDNS: device.reverseDNS,
        dhcpHostname: device.dhcpHostname,
        ttl: device.ttl,
        rtt: device.rtt,
        ports: device.ports.filter { $0.address == nil || $0.address == .v4(ip) },
        discoveredVia: via
      )
      return Device(observing: facts, in: network, firstSeen: firstSeen, lastSeen: finished)
    }

    var run = capture.run
    run.id = UUID()
    run.startedAt = started
    run.finishedAt = finished
    // The engine an iPad has: no neighbour table claimed.
    run.engine = EngineDescriptor(
      name: "darwin-unprivileged", kind: .unprivileged,
      capabilities: [.icmpSweep, .connectScan, .bannerProbe]
    )
    return ScanReport(run: run, devices: devices, degradations: [])
  }

  /// What a fixture launch seeds its store with.
  static func history(_ variant: Variant, capture: ScanReport, now: Date) -> [ScanReport] {
    switch variant {
    case .network: [ipadReport(from: capture, now: now)]
    case .empty: []
    }
  }

  /// The interface the fixture network is scanned from.
  static func interface(for capture: ScanReport) -> NetworkInterface {
    NetworkInterface(
      name: capture.run.interface,
      address: IPv4Address(raw: capture.run.target.networkAddress.raw | 0x16),  // .22, this iPad
      network: capture.run.target
    )
  }
}

nonisolated extension Timestamp {
  /// A wall-clock instant as core stores it, to the millisecond.
  init(_ date: Date) {
    self.init(millisecondsSinceEpoch: Int64((date.timeIntervalSince1970 * 1000).rounded()))
  }
}
