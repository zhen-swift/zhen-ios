import SwiftUI
import ZhenCore

/// Which ports to check on the chosen devices, and how big that is, before it starts.
///
/// A preset is one tap. A custom spec is the engine's own grammar — `22,80,443`,
/// `8000-8100`, `U:53`, `ssh`, `!80` — checked as it is typed, with the engine's own
/// sentence when it does not parse. The probe count and the time budget are shown before
/// Scan, and a very large scan asks first.
struct PortScanSheetView: View {
  @Environment(NetworkModel.self) var model
  @Environment(\.dismiss) var dismiss
  let ids: [DeviceItem.ID]
  @State var choice = PortChoice()
  @State var confirmsLargeScan = false

  var body: some View {
    NavigationStack {
      Form {
        TargetsSectionView(items: items)
        ChoiceSectionView(choice: $choice)
        EstimateSectionView(spec: spec, hosts: items.count)
      }
      .navigationTitle(Text(.scanPorts))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(.cancel) { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(.scan) { start() }
            .disabled(spec == nil || items.isEmpty || model.isBusy)
            .accessibilityIdentifier("startPortScanButton")
        }
      }
      .confirmationDialog(
        Text(.largeScanTitle), isPresented: $confirmsLargeScan, titleVisibility: .visible
      ) {
        Button(.scanAnyway) { run() }
      } message: {
        Text(.largeScanMessage(probes))
      }
    }
    .presentationSizing(.form)
  }
}

#Preview("Scan ports — one device") {
  PreviewContainer { model in
    PortScanSheetView(ids: Array(model.devices.prefix(1).map(\.id)))
  }
}
