import SwiftUI

extension DevicesView {
  /// Status, name, what is known — and how many ports are open, when that is known.
  ///
  /// An unidentified device is a normal row: its address in the name's place, then the
  /// facts there are. Never a dash, never error styling.
  struct RowView: View {
    let item: DeviceItem
    let isScanningPorts: Bool

    var body: some View {
      HStack(spacing: .spacing.medium) {
        StatusDot(item.isOnline ? .online : .offline)
        VStack(alignment: .leading, spacing: .spacing.xxSmall) {
          Text(item.name ?? item.address)
            .font(.body)
            .foregroundStyle(.textPrimary)
            .lineLimit(1)
          Text(secondLine)
            .font(.subheadline)
            .foregroundStyle(.textSecondary)
            .lineLimit(2)
        }
        Spacer(minLength: .spacing.small)
        if isScanningPorts {
          ProgressView()
            .controlSize(.small)
        } else if item.openPortCount > 0 {
          Chip(.openCount(item.openPortCount))
        }
      }
      .padding(.vertical, .spacing.xxSmall)
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("deviceRow-\(item.address)")
    }

    /// The address under a name; what is known under an address.
    private var secondLine: String {
      let facts = item.subtitle
      if item.name == nil { return facts.isEmpty ? String(localized: .unidentifiedDevice) : facts }
      return facts.isEmpty ? item.address : "\(item.address) · \(facts)"
    }
  }
}
