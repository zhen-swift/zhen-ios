import SwiftUI

extension RootView {
  /// What the root presents over everything.
  enum Sheet: Identifiable, Hashable {
    /// Scan the ports of these devices.
    case portScan([DeviceItem.ID])
    /// What this iPad's sandbox allows.
    case diagnostics

    var id: Self { self }
  }
}
