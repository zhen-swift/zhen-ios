import SwiftUI

extension DeviceDetailView {
  /// A title and its value, as one grid row.
  struct KeyValueRowView: View {
    let title: LocalizedStringResource
    let value: String
    let monospaced: Bool

    var body: some View {
      GridRow {
        Text(title)
          .font(.subheadline)
          .foregroundStyle(.textSecondary)
          .gridColumnAlignment(.trailing)
        Text(value)
          .font(monospaced ? .callout.monospaced() : .callout)
          .foregroundStyle(.textPrimary)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .accessibilityElement(children: .combine)
    }
  }
}
