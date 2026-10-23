import SwiftUI

/// The whole app: devices in the sidebar, the selected device — or devices — beside them.
///
/// A split view on a regular-width iPad, a stack when the app is narrow (Slide Over, a
/// third of Split View). One layout, adapting by size class; there is no separate iPad path
/// because there is no other path.
struct RootView: View {
  @State private var selection: Set<DeviceItem.ID> = []
  @State private var sheet: Sheet?

  var body: some View {
    NavigationSplitView {
      DevicesView(selection: $selection, sheet: $sheet)
    } detail: {
      NavigationStack {
        DetailColumnView(selection: selection, sheet: $sheet)
      }
    }
    .sheet(item: $sheet) { sheet in
      switch sheet {
      case .portScan(let ids):
        PortScanSheetView(ids: ids)
      case .diagnostics:
        DiagnosticsView()
      }
    }
  }
}

#Preview("Root — network") {
  PreviewContainer { RootView() }
}

#Preview("Root — never scanned") {
  PreviewContainer(.empty) { RootView() }
}
