import SwiftUI

extension DeviceDetailView.PortsCardView {
  /// Counts by state, as chips.
  struct SummaryView: View {
    let summary: PortSummary

    var body: some View {
      HStack(spacing: .spacing.small) {
        Chip(.openCount(summary.open), style: summary.open > 0 ? .accent : .neutral)
        if summary.closed > 0 { Chip(.closedCount(summary.closed)) }
        if summary.filtered > 0 { Chip(.filteredCount(summary.filtered)) }
        if summary.openFiltered > 0 { Chip(.openFilteredCount(summary.openFiltered)) }
      }
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("portSummary")
    }
  }
}
