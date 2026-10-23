import Foundation
import Testing
import ZhenCore
import ZhenScan
@testable import Zhen

@Suite("What a finished port probe amounts to for one device")
struct PortScanTests {
  private let address = IPv4Address("192.168.50.32")!

  private func outcome(_ ports: [PortObservation], _ outcome: Outcome = .complete) -> PortProbeOutcome {
    .finished(CompletedPortScan(
      result: PortScanResult(ports: [.v4(address): ports], outcome: outcome),
      events: []
    ))
  }

  @Test("Ports that answered are kept, stamped with the address, in canonical order")
  func finished() {
    let scan = PortScan.result(
      of: outcome([PortObservation(port: 445, state: .open), PortObservation(port: 22, state: .closed)]),
      for: address, isOnline: true
    )
    #expect(scan.state == .finished)
    #expect(scan.ports.map(\.port) == [22, 445])
    #expect(scan.ports.allSatisfy { $0.address == .v4(address) })
  }

  @Test("An offline device's address may be another device's: its answers are not shown")
  func offline() {
    let scan = PortScan.result(of: outcome([PortObservation(port: 22, state: .open)]), for: address, isOnline: false)
    guard case .failed(let reason) = scan.state else {
      Issue.record("expected a failure, got \(scan.state)")
      return
    }
    #expect(reason.contains("192.168.50.32"))
    #expect(scan.ports.isEmpty)
  }

  @Test("Nothing answered says so, and a stop says it was stopped")
  func silent() {
    if case .failed(let reason) = PortScan.result(of: outcome([]), for: address, isOnline: true).state {
      #expect(reason.contains("did not answer"))
    } else {
      Issue.record("silence read as success")
    }
    if case .failed(let reason) = PortScan.result(of: outcome([], .cancelled), for: address, isOnline: true).state {
      #expect(reason.contains("Stopped"))
    } else {
      Issue.record("a stop read as success")
    }
  }

  @Test("No interface is the engine's sentence, not an empty result")
  func unavailable() {
    let degradation = Degradation(stage: .setup, reason: "No network interface", recoverable: true)
    let scan = PortScan.result(of: .unavailable(degradation), for: address, isOnline: true)
    #expect(scan.state == .failed("No network interface"))
  }

  @Test("The summary counts every state")
  func summary() {
    let summary = PortSummary([
      PortObservation(port: 1, state: .open),
      PortObservation(port: 2, state: .closed),
      PortObservation(port: 3, state: .closed),
      PortObservation(port: 4, state: .filtered),
      PortObservation(port: 5, proto: .udp, state: .openFiltered),
    ])
    #expect(summary == PortSummary.counts(open: 1, closed: 2, filtered: 1, openFiltered: 1))
    #expect(summary.total == 5)
  }
}

extension PortSummary {
  /// A summary from counts, for comparing against.
  static func counts(open: Int, closed: Int, filtered: Int, openFiltered: Int) -> PortSummary {
    var summary = PortSummary([])
    summary.open = open
    summary.closed = closed
    summary.filtered = filtered
    summary.openFiltered = openFiltered
    return summary
  }
}
