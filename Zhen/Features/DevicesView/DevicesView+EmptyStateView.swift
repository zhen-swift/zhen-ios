import SwiftUI

extension DevicesView {
  /// What the list says when it has nothing to list, and why.
  ///
  /// Three different nothings: no scan yet, a scan where nothing answered, and a search
  /// that matched nothing. The second is the one that matters — on an iPad the usual cause
  /// is the Local Network permission, which cannot be queried, so the copy says "probably"
  /// and offers the way to check.
  struct EmptyStateView: View {
    @Environment(NetworkModel.self) private var model
    @Environment(\.openURL) private var openURL
    let search: String
    let hasMatches: Bool

    var body: some View {
      if !model.hasLoaded {
        ProgressView()
      } else if hasMatches || model.isScanning {
        EmptyView()
      } else if !search.isEmpty, !model.devices.isEmpty {
        ContentUnavailableView.search(text: search)
      } else if model.latestRun == nil {
        ContentUnavailableView {
          Label(.noScanYet, systemImage: "dot.radiowaves.left.and.right")
        } description: {
          Text(.noScanYetDescription)
        } actions: {
          Button(.scanThisNetwork) { model.startScan() }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("emptyScanButton")
        }
      } else {
        ContentUnavailableView {
          Label(.nothingAnswered, systemImage: "wifi.exclamationmark")
        } description: {
          Text(.nothingAnsweredDescription)
        } actions: {
          Button(.scanAgain) { model.startScan() }
            .buttonStyle(.borderedProminent)
          if let url = SystemSettings.appSettings {
            Button(.openSettings) { openURL(url) }
              .accessibilityIdentifier("openSettingsButton")
          }
        }
      }
    }
  }
}
