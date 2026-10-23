import SwiftUI
import ZhenCore

/// What this iPad lets the scanner do, checked rather than assumed.
///
/// The interface and the engine's capabilities, then a handful of checks of the sandbox
/// itself — the questions zhen-core's `Docs/IPADOS.md` says only a device can answer.
/// Shareable as text, for a bug report or a pull request.
struct DiagnosticsView: View {
  @Environment(NetworkModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  @State private var checks: [CapabilityCheck] = []

  var body: some View {
    NavigationStack {
      List {
        Section(.thisIPad) {
          LabeledContent {
            Text(verbatim: model.interface.map { "\($0.name) · \($0.address) · \($0.network)" } ?? "—")
              .font(.callout.monospaced())
          } label: {
            Text(.interface)
          }
          LabeledContent {
            Text(model.capabilities.names.joined(separator: ", "))
              .font(.callout.monospaced())
          } label: {
            Text(.engine)
          }
        }
        Section {
          if checks.isEmpty {
            ProgressView()
          }
          ForEach(checks) { check in
            CheckRowView(check: check)
          }
        } header: {
          Text(.sandboxChecks)
        } footer: {
          Text(.sandboxChecksFooter)
        }
      }
      .navigationTitle(Text(.diagnostics))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(.done) { dismiss() }
        }
        ToolbarItem(placement: .primaryAction) {
          ShareLink(item: report)
            .disabled(checks.isEmpty)
        }
      }
      .task { checks = await CapabilityProbe.run() }
    }
  }

  /// The checks as plain text, one per line.
  private var report: String {
    let lines = checks.map { check in
      let mark = check.verdict == .asAssumed ? "ok" : "SURPRISE"
      return "- \(mark): \(String(localized: check.title)) — \(check.outcome)"
    }
    let header = "Zhen for iPad · \(model.capabilities.names.joined(separator: ", "))"
    return ([header] + lines).joined(separator: "\n")
  }
}

#Preview("Diagnostics") {
  PreviewContainer { DiagnosticsView() }
}
