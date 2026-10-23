import SwiftUI
import ZhenCore

extension DeviceDetailView.PortsCardView {
  /// The ports that did not answer open, compactly.
  struct OthersView: View {
    let ports: [PortObservation]

    var body: some View {
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 140), alignment: .leading)],
        alignment: .leading,
        spacing: .spacing.small
      ) {
        ForEach(ports, id: \.self) { port in
          HStack(spacing: .spacing.xSmall) {
            Text(verbatim: "\(port.port)/\(port.proto.rawValue)")
              .font(.caption.monospaced())
              .foregroundStyle(.textPrimary)
            Text(DeviceDetailView.label(for: port.state))
              .font(.caption)
              .foregroundStyle(.textTertiary)
          }
          .accessibilityElement(children: .combine)
        }
      }
      .padding(.top, .spacing.small)
    }
  }
}
