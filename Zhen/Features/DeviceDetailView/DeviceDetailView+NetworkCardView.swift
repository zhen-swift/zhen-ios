import SwiftUI
import ZhenCore

extension DeviceDetailView {
  /// Addresses, the hop count and round trip, how it was found, and when.
  struct NetworkCardView: View {
    let item: DeviceItem

    var body: some View {
      Card(.network) {
        Grid(
          alignment: .leadingFirstTextBaseline,
          horizontalSpacing: .spacing.large,
          verticalSpacing: .spacing.medium
        ) {
          KeyValueRowView(title: .addresses, value: addresses, monospaced: true)
          if let ttl = item.device.ttl {
            KeyValueRowView(title: .ttl, value: ttlText(ttl), monospaced: false)
          }
          if let rtt = item.device.rtt {
            KeyValueRowView(title: .roundTrip, value: milliseconds(rtt.millis), monospaced: false)
          }
          KeyValueRowView(title: .foundBy, value: foundBy, monospaced: false)
          KeyValueRowView(title: .firstSeen, value: moment(item.firstSeen), monospaced: false)
          KeyValueRowView(title: .lastSeenTitle, value: moment(item.lastSeen), monospaced: false)
        }
        .padding(.spacing.large)
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("networkCard")
    }

    private var addresses: String {
      item.device.addresses.sorted().map(\.description).joined(separator: "\n")
    }

    private var foundBy: String {
      item.device.discoveredVia
        .map { String(localized: DeviceDetailView.label(for: $0)) }
        .joined(separator: ", ")
    }

    private func milliseconds(_ value: Double) -> String {
      String(localized: .millisecondsValue(value.formatted(.number.precision(.fractionLength(1)))))
    }

    private func moment(_ date: Date) -> String {
      date.formatted(date: .abbreviated, time: .shortened)
    }

    /// The TTL, and the operating-system family it suggests. A hint, and said as one.
    private func ttlText(_ ttl: UInt8) -> String {
      guard let hint = item.device.osHint else { return "\(ttl)" }
      return "\(ttl) · " + String(localized: .suggests(DeviceItem.Words.osHint(hint)))
    }
  }
}
