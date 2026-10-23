import SwiftUI
import ZhenCore

extension PortScanSheetView {
  /// The chosen devices that can be scanned: those with an IPv4 address.
  var items: [DeviceItem] {
    ids.compactMap(model.device).filter { $0.ipv4 != nil }.sorted(by: DeviceItem.listOrder)
  }

  /// The spec, when the choice parses.
  var spec: PortSpec? { try? choice.spec.get() }

  var probes: Int { spec.map { PortChoice.probes(for: $0, hosts: items.count) } ?? 0 }

  /// Asks first when the scan is very large; starts it otherwise.
  func start() {
    if probes > PortChoice.confirmationThreshold {
      confirmsLargeScan = true
    } else {
      run()
    }
  }

  func run() {
    guard let spec else { return }
    model.scanPorts(items.map(\.id), spec: spec, budget: PortChoice.budget(for: spec, hosts: items.count))
    dismiss()
  }
}
