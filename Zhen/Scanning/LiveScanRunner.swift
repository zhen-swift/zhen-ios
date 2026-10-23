import Foundation
import ZhenCore
import ZhenScan

/// The engine, for real: zhen-core's `ScanRunner` over this app's history.
///
/// A runner is built per request rather than kept. Building one reads the interface list,
/// and an iPad changes networks under a long-lived app — a runner made at launch would scan
/// the Wi-Fi it was opened on, not the one it is on now.
actor LiveScanRunner: ScanRunning {
  private let store: any HistoryStore

  init(store: any HistoryStore) {
    self.store = store
  }

  func interface() async -> NetworkInterface? {
    try? await runner().interface
  }

  func capabilities() async -> EngineCapabilities {
    (try? await runner().descriptor.capabilities) ?? []
  }

  func run(_ request: ScanRequest, progress: ProgressSink) async -> ScanOutcome {
    do {
      let runner = try await runner()
      return .finished(await runner.run(budget: request.budget, ports: request.ports, progress: progress))
    } catch {
      let degradation = Self.noInterface(error)
      progress(.degraded(degradation))
      return .unavailable(degradation)
    }
  }

  func probePorts(_ request: PortProbeRequest, progress: ProgressSink) async -> PortProbeOutcome {
    do {
      let runner = try await runner()
      return .finished(await runner.probePorts(
        request.addresses, spec: request.spec, budget: request.budget, progress: progress
      ))
    } catch {
      return .unavailable(Self.noInterface(error))
    }
  }

  /// No capture device to ask for on iPadOS; `.directOnly` says so explicitly.
  private func runner() async throws(PlatformError) -> ScanRunner {
    try await ScanRunner(store: store, capture: .directOnly)
  }

  private static func noInterface(_ error: PlatformError) -> Degradation {
    Degradation(
      stage: .setup,
      reason: String(localized: .noInterfaceForScanning(String(describing: error))),
      recoverable: true
    )
  }
}
