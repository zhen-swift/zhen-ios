import SwiftUI

/// The sidebar: every device history holds, online first, with the scan control above.
///
/// Selecting one opens it beside the list. Selecting several — Select, or a two-finger
/// drag — offers to scan their ports together.
struct DevicesView: View {
  @Environment(NetworkModel.self) var model
  @Binding var selection: Set<DeviceItem.ID>
  @Binding var sheet: RootView.Sheet?
  @State var search = ""

  var body: some View {
    List(selection: $selection) {
      if model.isScanning {
        Section {
          ScanProgressView()
        }
      }
      if !online.isEmpty {
        Section(.onlineSection) {
          ForEach(online) { item in
            RowView(item: item, isScanningPorts: model.portScans[item.id]?.isRunning == true)
              .tag(item.id)
              .rowActions(for: item, sheet: $sheet, isBusy: model.isBusy)
          }
        }
      }
      if !seenBefore.isEmpty {
        Section(.seenBeforeSection) {
          ForEach(seenBefore) { item in
            RowView(item: item, isScanningPorts: model.portScans[item.id]?.isRunning == true)
              .tag(item.id)
              .rowActions(for: item, sheet: $sheet, isBusy: model.isBusy)
          }
        }
      }
      if !notes.isEmpty, !model.isScanning {
        NotesSectionView(degradations: notes)
      }
    }
    .listStyle(.sidebar)
    .overlay { EmptyStateView(search: search, hasMatches: !online.isEmpty || !seenBefore.isEmpty) }
    .searchable(text: $search, prompt: Text(.searchDevices))
    .navigationTitle(Text(.devices))
    .navigationBarTitleDisplayMode(.large)
    .toolbar { ToolbarView(selection: $selection, sheet: $sheet) }
  }
}

#Preview("Devices — network") {
  PreviewContainer {
    NavigationStack {
      DevicesView(selection: .constant([]), sheet: .constant(nil))
    }
  }
}

#Preview("Devices — never scanned") {
  PreviewContainer(.empty) {
    NavigationStack {
      DevicesView(selection: .constant([]), sheet: .constant(nil))
    }
  }
}
