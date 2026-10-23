import SwiftUI
import ZhenCore

extension DeviceDetailView.PortsCardView {
  /// One open port: number and transport, what it is, and what says so.
  struct PortRowView: View {
    let port: PortObservation

    var body: some View {
      GridRow {
        Text(verbatim: "\(port.port)/\(port.proto.rawValue)")
          .font(.callout.monospaced())
          .foregroundStyle(.textPrimary)
        VStack(alignment: .leading, spacing: .spacing.xxSmall) {
          Text(port.service?.name ?? "—")
            .font(.callout)
            .foregroundStyle(.textPrimary)
          if let detail {
            Text(detail)
              .font(.caption)
              .foregroundStyle(.textSecondary)
              .lineLimit(2)
              .textSelection(.enabled)
          }
        }
        .gridColumnAlignment(.leading)
        if let evidence = port.service?.evidence {
          Chip(DeviceDetailView.label(for: evidence))
        } else {
          Color.clear.frame(width: 0, height: 0)
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("openPort-\(port.port)-\(port.proto.rawValue)")
    }

    /// Product and version, the certificate's subject, or the banner itself — kept apart
    /// from the name, as the engine reports them.
    private var detail: String? {
      guard let service = port.service else { return nil }
      let product = [service.product, service.version].compactMap { $0 }.joined(separator: " ")
      let parts = [product.isEmpty ? nil : product, service.tlsSubject].compactMap { $0 }
      if !parts.isEmpty { return parts.joined(separator: " · ") }
      return service.banner?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }
}
