import SwiftUI

extension RootView {
  /// The detail column: nothing selected, one device, or several.
  struct DetailColumnView: View {
    let selection: Set<DeviceItem.ID>
    @Binding var sheet: RootView.Sheet?

    var body: some View {
      switch selection.count {
      case 0:
        ContentUnavailableView {
          Label(.selectADevice, systemImage: "sidebar.left")
        } description: {
          Text(.selectADeviceDescription)
        }
      case 1:
        if let id = selection.first {
          DeviceDetailView(id: id, sheet: $sheet)
        }
      default:
        MultiSelectionView(ids: Array(selection), sheet: $sheet)
      }
    }
  }
}
