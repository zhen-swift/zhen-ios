import SwiftUI
import ZhenCore

extension PortScanSheetView {
  /// What the choice amounts to, or why it does not parse.
  struct ChoiceFooterView: View {
    let choice: PortChoice

    var body: some View {
      switch choice.spec {
      case .failure(let error) where !choice.custom.trimmingCharacters(in: .whitespaces).isEmpty:
        Text(error.message)
          .foregroundStyle(.statusWarningText)
          .accessibilityIdentifier("portSpecError")
      case .failure:
        Text(.customPortsHelp)
      case .success(let spec):
        Text(.specSummary(spec.ports.count, spec.udpPorts.count))
          .accessibilityIdentifier("portSpecSummary")
      }
    }
  }
}
