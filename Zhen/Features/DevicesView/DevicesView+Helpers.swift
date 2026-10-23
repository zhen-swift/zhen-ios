import SwiftUI
import ZhenCore

extension DevicesView {
  /// The devices the latest run saw, matching the search.
  var online: [DeviceItem] {
    model.devices.filter { $0.isOnline && $0.matches(search) }.sorted(by: DeviceItem.listOrder)
  }

  /// The devices history holds that the latest run did not see, most recently seen first.
  var seenBefore: [DeviceItem] {
    model.devices.filter { !$0.isOnline && $0.matches(search) }.sorted { $0.lastSeen > $1.lastSeen }
  }

  /// What the last scan this session reported going wrong.
  var notes: [Degradation] { model.lastDegradations }
}

private struct RowActions: ViewModifier {
  let item: DeviceItem
  @Binding var sheet: RootView.Sheet?
  let isBusy: Bool

  func body(content: Content) -> some View {
    content
      .swipeActions(edge: .trailing) {
        scanPortsButton
          .tint(.accent)
      }
      .contextMenu {
        scanPortsButton
      }
  }

  private var scanPortsButton: some View {
    Button(.scanPortsEllipsis, systemImage: "network.badge.shield.half.filled") {
      sheet = .portScan([item.id])
    }
    .disabled(isBusy || item.ipv4 == nil)
  }
}

extension View {
  /// Swipe and context-menu actions for one device row.
  func rowActions(for item: DeviceItem, sheet: Binding<RootView.Sheet?>, isBusy: Bool) -> some View {
    modifier(RowActions(item: item, sheet: sheet, isBusy: isBusy))
  }
}
