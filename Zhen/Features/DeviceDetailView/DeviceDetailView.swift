import SwiftUI

/// One device: who it is, which ports it answers on, what it calls itself, and how it was
/// found. Scan Ports is here and in the row's swipe action, and asks which ports first.
struct DeviceDetailView: View {
  @Environment(NetworkModel.self) private var model
  let id: DeviceItem.ID
  @Binding var sheet: RootView.Sheet?

  var body: some View {
    if let item = model.device(id) {
      ScrollView {
        VStack(alignment: .leading, spacing: .spacing.large) {
          HeaderCardView(item: item)
          PortsCardView(
            item: item,
            scan: model.portScans[item.id],
            ports: model.ports(for: item),
            canScan: !model.isBusy && item.ipv4 != nil,
            onScanPorts: { sheet = .portScan([item.id]) }
          )
          KnownByCardView(item: item)
          NetworkCardView(item: item)
        }
        .padding(.spacing.xLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(.surface)
      .navigationTitle(item.name ?? item.address)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(.scanPortsEllipsis, systemImage: "network.badge.shield.half.filled") {
            sheet = .portScan([item.id])
          }
          .disabled(model.isBusy || item.ipv4 == nil)
          .accessibilityIdentifier("scanPortsButton")
        }
        ToolbarItem(placement: .secondaryAction) {
          ShareLink(item: Self.json(item.device), preview: SharePreview(item.name ?? item.address))
        }
      }
    } else {
      ContentUnavailableView {
        Label(.deviceNotFound, systemImage: "questionmark.circle")
      } description: {
        Text(.deviceNotFoundDescription)
      }
    }
  }
}

#Preview("Device — named, with ports") {
  PreviewContainer { model in
    NavigationStack {
      DeviceDetailView(id: model.devices.first { $0.name == "Archive" }?.id ?? "", sheet: .constant(nil))
    }
  }
}

#Preview("Device — unidentified") {
  PreviewContainer { model in
    NavigationStack {
      DeviceDetailView(id: model.devices.first { $0.name == nil }?.id ?? "", sheet: .constant(nil))
    }
  }
}
