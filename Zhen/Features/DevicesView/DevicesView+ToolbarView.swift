import SwiftUI

extension DevicesView {
  /// Scan or Stop, the scan's options, Select, and Diagnostics.
  struct ToolbarView: ToolbarContent {
    @Environment(NetworkModel.self) private var model
    @Binding var selection: Set<DeviceItem.ID>
    @Binding var sheet: RootView.Sheet?

    var body: some ToolbarContent {
      ToolbarItem(placement: .topBarLeading) {
        EditButton()
          .accessibilityIdentifier("selectButton")
      }
      ToolbarItem(placement: .primaryAction) {
        if model.isBusy {
          Button(.stop, systemImage: "stop.fill", role: .cancel) { model.stopScanning() }
            .accessibilityIdentifier("stopButton")
        } else {
          // The plain tap is the plain scan; the menu holds the variants that also check
          // ports, which are slower and deliberate.
          Menu {
            Button(.scanAndCheckPortsOfNewDevices) { model.startScan(ports: .newHosts) }
            Button(.scanAndCheckPortsOfEveryDevice) { model.startScan(ports: .everyHost) }
          } label: {
            Label(.scan, systemImage: "dot.radiowaves.left.and.right")
          } primaryAction: {
            model.startScan()
          }
          .accessibilityIdentifier("scanButton")
        }
      }
      ToolbarItem(placement: .secondaryAction) {
        Button(.diagnostics, systemImage: "stethoscope") { sheet = .diagnostics }
          .accessibilityIdentifier("diagnosticsButton")
      }
    }
  }
}
