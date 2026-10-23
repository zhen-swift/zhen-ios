import Foundation
import ZhenCore

/// One device as the list shows it: a `Device` flattened into what its row displays and
/// sorts by.
///
/// Identity is the strongest key core would file the device under — a Bonjour instance,
/// a DHCP name, then the lease — never the address alone, which moves. On an iPad there is
/// no hardware address, so the lease is reached more often than on a Mac.
nonisolated struct DeviceItem: Identifiable, Hashable, Sendable {
  typealias ID = String

  let id: ID
  let device: Device
  /// Whether the most recent run saw it. Presence is a fact about a run, not a device.
  let isOnline: Bool

  /// The name to show, or nil for an unidentified device.
  var name: String? { device.displayName }

  /// The address a person reads: the IPv4 one when there is one.
  var address: String {
    if let v4 = device.ipv4Addresses.first { return v4.description }
    let full = device.primaryAddress.description
    return full.split(separator: "%").first.map(String.init) ?? full
  }

  var ipv4: IPv4Address? { device.ipv4Addresses.first }

  /// What is known, said plainly — for an unidentified device this line is the row's
  /// whole worth, so it never says nothing.
  var subtitle: String {
    var parts: [String] = []
    if let model = device.displayModel { parts.append(model) }
    if let hint = device.osHint { parts.append(Words.osHint(hint)) }
    let via = Set(device.discoveredVia)
    if via.contains(.localInterface) {
      parts.append(Words.thisIPad)
    } else if via.contains(.probeReply) {
      parts.append(Words.respondsToPing)
    }
    return parts.joined(separator: " · ")
  }

  var openPortCount: Int { device.openPorts.count }
  var lastSeen: Date { Date(timeIntervalSince1970: device.lastSeen.timeIntervalSince1970) }
  var firstSeen: Date { Date(timeIntervalSince1970: device.firstSeen.timeIntervalSince1970) }

  /// Whether a search term finds this device: by name, by what is known, by address.
  func matches(_ term: String) -> Bool {
    let term = term.trimmingCharacters(in: .whitespaces)
    guard !term.isEmpty else { return true }
    return [name ?? "", subtitle, address].contains { $0.localizedStandardContains(term) }
  }

  /// Named devices alphabetically, then the unidentified ones by address.
  static func listOrder(_ lhs: DeviceItem, _ rhs: DeviceItem) -> Bool {
    switch (lhs.name, rhs.name) {
    case let (left?, right?):
      return left.localizedStandardCompare(right) == .orderedAscending
    case (.some, .none):
      return true
    case (.none, .some):
      return false
    case (.none, .none):
      return addressOrder(lhs, rhs)
    }
  }

  /// Core's own address order, numeric — never the string's.
  static func addressOrder(_ lhs: DeviceItem, _ rhs: DeviceItem) -> Bool {
    lhs.device.primaryAddress < rhs.device.primaryAddress
  }
}

nonisolated extension DeviceItem {
  /// The words every row repeats, looked up once.
  enum Words {
    static let thisIPad = String(localized: .thisIPad)
    static let respondsToPing = String(localized: .respondsToPing)

    static func osHint(_ hint: OSHint) -> String {
      switch hint {
      case .unixLike: String(localized: .osHintUnixLike)
      case .windows: String(localized: .osHintWindows)
      case .networkDevice: String(localized: .osHintNetworkDevice)
      }
    }
  }

  /// The stable key for a device: core's strongest identifier for it.
  static func identity(of device: Device, in network: IPv4Network?) -> ID {
    if let network, let key = HostIdentifier.candidates(for: device, in: network).first {
      return "\(key.kind.rawValue):\(key.value)"
    }
    return "address:\(device.primaryAddress)"
  }

  /// Rows for a store's devices, with identities made unique.
  static func rows(from stored: [StoredDevice], network: IPv4Network?) -> [DeviceItem] {
    var seen: [ID: Int] = [:]
    return stored.map { entry in
      var id = identity(of: entry.device, in: network)
      seen[id, default: 0] += 1
      if let count = seen[id], count > 1 { id += "#\(count)" }
      return DeviceItem(id: id, device: entry.device, isOnline: entry.isPresent)
    }
  }
}
