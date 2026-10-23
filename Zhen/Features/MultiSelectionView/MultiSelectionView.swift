import SwiftUI

/// Several devices selected: who they are, and one action — scan their ports together.
struct MultiSelectionView: View {
  @Environment(NetworkModel.self) private var model
  let ids: [DeviceItem.ID]
  @Binding var sheet: RootView.Sheet?

  var body: some View {
    let items = ids.compactMap(model.device).sorted(by: DeviceItem.listOrder)
    let scannable = items.filter { $0.ipv4 != nil }
    ContentUnavailableView {
      Label(.nDevicesSelected(items.count), systemImage: "checklist")
    } description: {
      Text(items.map { $0.name ?? $0.address }.formatted(.list(type: .and)))
    } actions: {
      Button(.scanPortsOfSelected) { sheet = .portScan(scannable.map(\.id)) }
        .buttonStyle(.borderedProminent)
        .disabled(model.isBusy || scannable.isEmpty)
        .accessibilityIdentifier("scanSelectedPortsButton")
    }
  }
}

#Preview("Several selected") {
  PreviewContainer { model in
    NavigationStack {
      MultiSelectionView(ids: Array(model.devices.prefix(3).map(\.id)), sheet: .constant(nil))
    }
  }
}
