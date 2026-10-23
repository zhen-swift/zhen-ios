import SwiftUI

extension DiagnosticsView {
  /// One check: what was tried, what came back, and what was expected.
  struct CheckRowView: View {
    let check: CapabilityCheck

    var body: some View {
      VStack(alignment: .leading, spacing: .spacing.xSmall) {
        Label {
          Text(check.title)
            .font(.headline)
            .foregroundStyle(.textPrimary)
        } icon: {
          StatusDot(check.verdict == .asAssumed ? .online : .warning)
        }
        Text(check.outcome)
          .font(.callout.monospaced())
          .foregroundStyle(.textPrimary)
          .textSelection(.enabled)
        Text(check.assumption)
          .font(.footnote)
          .foregroundStyle(.textSecondary)
      }
      .padding(.vertical, .spacing.xxSmall)
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("check-\(check.id)")
    }
  }
}
