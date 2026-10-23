import SwiftUI
import ZhenCore

extension PortScanSheetView {
  /// How many probes, and the longest the scan may take.
  ///
  /// The budget is a ceiling, not a forecast: on a home network most ports answer or are
  /// refused in milliseconds, and the scan ends when every port has.
  struct EstimateSectionView: View {
    let spec: PortSpec?
    let hosts: Int

    private static let duration = Duration.UnitsFormatStyle(
      allowedUnits: [.minutes, .seconds], width: .abbreviated
    )

    var body: some View {
      if let spec {
        Section {
          LabeledContent {
            Text(PortChoice.probes(for: spec, hosts: hosts).formatted())
              .monospacedDigit()
          } label: {
            Text(.probes)
          }
          LabeledContent {
            Text(PortChoice.budget(for: spec, hosts: hosts).formatted(Self.duration))
              .monospacedDigit()
          } label: {
            Text(.atMost)
          }
        } footer: {
          Text(.estimateFooter)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("portScanEstimate")
      }
    }
  }
}
