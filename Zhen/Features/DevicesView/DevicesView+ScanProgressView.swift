import SwiftUI

extension DevicesView {
  /// The row a running scan puts at the top of the list: how many have answered so far.
  ///
  /// A count, not a bar: the sweep's length depends on who answers and when, and a bar
  /// that guessed would be a claim the scan cannot back.
  struct ScanProgressView: View {
    @Environment(NetworkModel.self) private var model

    var body: some View {
      HStack(spacing: .spacing.medium) {
        ProgressView()
        VStack(alignment: .leading, spacing: .spacing.xxSmall) {
          Text(.scanningThisNetwork)
            .font(.body)
            .foregroundStyle(.textPrimary)
          Text(.devicesAnsweredSoFar(model.liveFound))
            .font(.subheadline)
            .monospacedDigit()
            .contentTransition(.numericText())
            .foregroundStyle(.textSecondary)
        }
      }
      .padding(.vertical, .spacing.xxSmall)
      .animation(.snappy, value: model.liveFound)
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("scanProgress")
    }
  }
}
