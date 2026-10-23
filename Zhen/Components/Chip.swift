import SwiftUI

/// A short tag beside a name or a port: `3 open`, `TLS certificate`, `BONJOUR`.
struct Chip: View {
  let title: LocalizedStringResource
  let style: Style

  init(_ title: LocalizedStringResource, style: Style = .neutral) {
    self.title = title
    self.style = style
  }

  var body: some View {
    Text(title)
      .font(style.font)
      .textCase(style.textCase)
      .foregroundStyle(style.foreground)
      .padding(.horizontal, .spacing.small)
      .padding(.vertical, .spacing.xxSmall)
      .background(style.fill, in: .rect(cornerRadius: .cornerRadius.small))
  }
}

#Preview("Chips — dark") {
  ChipPreview().preferredColorScheme(.dark)
}

#Preview("Chips — light") {
  ChipPreview().preferredColorScheme(.light)
}

#Preview("Chips — increased contrast") {
  ChipPreview()
    .preferredColorScheme(.dark)
    .environment(\._colorSchemeContrast, .increased)
}

private struct ChipPreview: View {
  var body: some View {
    VStack(alignment: .leading, spacing: .spacing.medium) {
      HStack(spacing: .spacing.small) {
        Text(verbatim: "443/tcp").font(.callout.monospaced()).foregroundStyle(.textPrimary)
        Chip(.openCount(3), style: .accent)
      }
      HStack(spacing: .spacing.small) {
        Text(verbatim: "https").foregroundStyle(.textTertiary)
        Chip(.evidenceTLS)
      }
    }
    .padding(.spacing.xLarge)
    .background(.surface)
  }
}
