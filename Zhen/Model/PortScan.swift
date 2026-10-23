import Foundation
import ZhenCore
import ZhenScan

/// One device's port scan, as this session ran it.
nonisolated struct PortScan: Equatable, Sendable {
  enum State: Equatable, Sendable {
    /// Probing `probes` ports.
    case running(probes: Int)
    case finished
    /// It ran and found nothing to report; the sentence says what happened.
    case failed(String)
  }

  var state: State
  /// Everything it observed, closed and filtered included. While running, the previous
  /// session scan's, if any.
  var ports: [PortObservation]
  /// When it started, or when it finished once it has.
  var at: Date

  var isRunning: Bool {
    if case .running = state { true } else { false }
  }

  /// What a finished probe of one address amounts to.
  ///
  /// `isOnline` is whether the latest run saw the device. An offline device's address may
  /// belong to another device now; whatever answers there is not known to be this one, so
  /// its ports are not shown as this device's — and core, which has no hardware address in
  /// a port answer to check, refuses to record them for it too.
  static func result(of outcome: PortProbeOutcome, for address: IPv4Address, isOnline: Bool) -> PortScan {
    switch outcome {
    case .unavailable(let degradation):
      return PortScan(state: .failed(degradation.reason), ports: [], at: .now)
    case .finished(let scan):
      guard isOnline else {
        let reason = String(localized: .offlineSoPortsNotItsOwn(address.description))
        return PortScan(state: .failed(reason), ports: [], at: .now)
      }
      let ports = (scan.result.ports[.v4(address)] ?? []).map { observation in
        var stamped = observation
        if stamped.address == nil { stamped.address = .v4(address) }
        return stamped
      }
      if !ports.isEmpty {
        return PortScan(state: .finished, ports: ports.sorted(by: PortObservation.canonicalOrder), at: .now)
      }
      let reason = scan.result.outcome == .cancelled
        ? String(localized: .stoppedBeforeAnyPortAnswered)
        : String(localized: .didNotAnswerThisTimeSo(address.description))
      return PortScan(state: .failed(reason), ports: [], at: .now)
    }
  }
}

/// The devices a port scan is for, and what it asks. A new value is a new scan.
nonisolated struct PortScanTarget: Hashable, Sendable {
  struct Member: Hashable, Sendable {
    let id: DeviceItem.ID
    let address: IPv4Address
    /// Whether the latest run saw the device: an offline device's address may be another's.
    let isOnline: Bool
  }

  let members: [Member]
  let spec: PortSpec
  let budget: Duration
  let token = UUID()
}

/// How a device's ports read, counted by state.
nonisolated struct PortSummary: Equatable, Sendable {
  var open = 0
  var closed = 0
  var filtered = 0
  var openFiltered = 0

  init(_ ports: [PortObservation]) {
    for port in ports {
      switch port.state {
      case .open: open += 1
      case .closed: closed += 1
      case .filtered: filtered += 1
      case .openFiltered: openFiltered += 1
      }
    }
  }

  var total: Int { open + closed + filtered + openFiltered }
}
