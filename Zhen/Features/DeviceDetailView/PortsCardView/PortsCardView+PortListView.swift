import SwiftUI
import ZhenCore

extension DeviceDetailView.PortsCardView {
  /// The ports: a summary, the open ones, and the rest behind a disclosure.
  struct PortListView: View {
    let ports: [PortObservation]
    let canScan: Bool
    let onScanPorts: () -> Void
    @State private var showsOthers = false

    var body: some View {
      if ports.isEmpty {
        HStack {
          Text(.noPortScanYet)
            .font(.subheadline)
            .foregroundStyle(.textSecondary)
          Spacer()
          Button(.scanPortsEllipsis, action: onScanPorts)
            .disabled(!canScan)
            .accessibilityIdentifier("cardScanPortsButton")
        }
        .padding(.spacing.large)
      } else {
        VStack(alignment: .leading, spacing: .spacing.medium) {
          SummaryView(summary: PortSummary(ports))
          if open.isEmpty {
            Text(.noneOfNPortsWasOpen(ports.count))
              .font(.subheadline)
              .foregroundStyle(.textSecondary)
              .accessibilityIdentifier("noOpenPorts")
          } else {
            Grid(
              alignment: .leadingFirstTextBaseline,
              horizontalSpacing: .spacing.large,
              verticalSpacing: .spacing.medium
            ) {
              ForEach(open, id: \.self) { port in
                PortRowView(port: port)
              }
            }
          }
          if !others.isEmpty {
            DisclosureGroup(isExpanded: $showsOthers) {
              OthersView(ports: others)
            } label: {
              Text(.notOpenCount(others.count))
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
            }
            .accessibilityIdentifier("otherPortsDisclosure")
          }
        }
        .padding(.spacing.large)
      }
    }

    private var open: [PortObservation] { ports.filter { $0.state == .open } }
    private var others: [PortObservation] { ports.filter { $0.state != .open } }
  }
}
