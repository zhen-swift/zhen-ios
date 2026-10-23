import SwiftUI

extension DeviceDetailView.PortsCardView {
  /// A port scan in flight: an honest spinner, how many probes, and for how long.
  ///
  /// No percentage: the engine does not report one, and a bar drawn from elapsed time
  /// would claim a progress nothing measured.
  struct RunningView: View {
    let probes: Int
    let since: Date
    let host: String

    var body: some View {
      HStack(spacing: .spacing.medium) {
        ProgressView()
        VStack(alignment: .leading, spacing: .spacing.xxSmall) {
          Text(.checkingPortsOn(probes, host))
            .font(.subheadline)
            .foregroundStyle(.textPrimary)
          Text(timerInterval: since...Date.distantFuture, countsDown: false)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.textSecondary)
        }
      }
      .padding(.spacing.large)
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("portScanRunning")
    }
  }
}
