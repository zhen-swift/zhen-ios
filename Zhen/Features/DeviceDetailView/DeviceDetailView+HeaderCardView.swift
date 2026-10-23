import SwiftUI

extension DeviceDetailView {
  /// Name, presence, address, and how sure the app is of the identity.
  struct HeaderCardView: View {
    let item: DeviceItem
    @ScaledMetric(relativeTo: .title2) private var tile = IconSize.xLarge

    var body: some View {
      Card {
        HStack(alignment: .center, spacing: .spacing.large) {
          Image(systemName: symbol)
            .font(.title2)
            .foregroundStyle(.accent)
            .frame(width: tile, height: tile)
            .background(.surfaceField, in: .rect(cornerRadius: .cornerRadius.xLarge))
            .accessibilityHidden(true)
          VStack(alignment: .leading, spacing: .spacing.xSmall) {
            Text(item.name ?? String(localized: .unidentifiedDevice))
              .font(.title2.bold())
              .foregroundStyle(.textPrimary)
            HStack(spacing: .spacing.small) {
              StatusDot(item.isOnline ? .online : .offline)
              if item.isOnline {
                Text(.onlineNow)
              } else {
                Text(.lastSeen(item.lastSeen.formatted(.relative(presentation: .named))))
              }
            }
            .font(.subheadline)
            .foregroundStyle(.textSecondary)
            Text(item.address)
              .font(.callout.monospaced())
              .foregroundStyle(.textSecondary)
              .textSelection(.enabled)
          }
          Spacer(minLength: .spacing.small)
          VStack(alignment: .trailing, spacing: .spacing.xSmall) {
            SignalMeter(item.device.identification)
            Text(DeviceDetailView.word(for: item.device.identification))
              .font(.caption)
              .foregroundStyle(.textSecondary)
          }
          .accessibilityElement(children: .combine)
        }
        .padding(.spacing.large)
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("deviceHeader")
    }

    /// A glyph for the kind of device, from the little that is known; a generic one
    /// otherwise. Not an identification — the words beside it are.
    private var symbol: String {
      switch item.device.osHint {
      case .windows: "pc"
      case .networkDevice: "wifi.router"
      case .unixLike, .none: "network"
      }
    }
  }
}
