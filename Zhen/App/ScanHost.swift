import SwiftUI

/// Where the work runs: one `.task(id:)` per kind of scan, keyed on its token.
///
/// A new token starts the work; a cleared one — Stop — cancels it, as does the scene going
/// away. The model only ever asks for work; this is the one place it is done, so nothing
/// starts a scan from an unstructured `Task` that nobody can stop.
private struct ScanHost: ViewModifier {
  let model: NetworkModel

  func body(content: Content) -> some View {
    content
      .task { await model.load() }
      .task(id: model.scanToken) { await model.performScan() }
      .task(id: model.portScanTarget) { await model.performPortScan() }
      .keepsScreenAwake(model.isBusy)
  }
}

extension View {
  /// Runs the model's scans for as long as this view is on screen.
  func scanHost(_ model: NetworkModel) -> some View {
    modifier(ScanHost(model: model))
  }
}
