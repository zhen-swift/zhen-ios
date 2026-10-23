import Darwin
import Foundation
import ZhenCore

/// What this iPad's sandbox allows, checked one call at a time.
///
/// The engine's iPadOS composition was decided from SDK headers and from what is reported
/// about the sandbox (zhen-core `Docs/IPADOS.md`). These are the questions only a device
/// answers: each check makes the call the engine — or a feature cut from it — would make,
/// and records what came back. None sends anything on the network.
nonisolated struct CapabilityCheck: Identifiable, Sendable {
  enum Verdict: Sendable {
    /// Behaved as the composition assumes.
    case asAssumed
    /// Did not: worth reporting.
    case surprise
  }

  let id: String
  let title: LocalizedStringResource
  /// What came back, as measured — a count, an errno, a value.
  let outcome: String
  let verdict: Verdict
  /// What the composition assumes, so a surprise reads without the source.
  let assumption: LocalizedStringResource
}

nonisolated enum CapabilityProbe {
  /// Every check, off the main actor.
  @concurrent
  static func run() async -> [CapabilityCheck] {
    [icmpSocket(), descriptorLimit(), routeTable(), neighborTable(), hardwareAddress(), bonjourDeclared()]
  }

  /// The ICMP sweep's socket.
  static func icmpSocket() -> CapabilityCheck {
    let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP)
    let error = errno
    if fd >= 0 { close(fd) }
    return CapabilityCheck(
      id: "icmpSocket", title: .checkIcmpSocket,
      outcome: fd >= 0 ? String(localized: .checkOpened) : describe(error),
      verdict: fd >= 0 ? .asAssumed : .surprise,
      assumption: .checkIcmpSocketAssumption
    )
  }

  /// How many descriptors the process may hold; the connect scan's width follows it.
  static func descriptorLimit() -> CapabilityCheck {
    var limits = rlimit()
    guard getrlimit(RLIMIT_NOFILE, &limits) == 0 else {
      return CapabilityCheck(
        id: "descriptorLimit", title: .checkDescriptorLimit, outcome: describe(errno),
        verdict: .surprise, assumption: .checkDescriptorLimitAssumption
      )
    }
    return CapabilityCheck(
      id: "descriptorLimit", title: .checkDescriptorLimit,
      // RLIM_INFINITY is a macro Swift does not import; it is the largest signed 64-bit value.
      outcome: "\(limits.rlim_cur) / \(limits.rlim_max >= rlim_t(Int64.max) ? "∞" : String(limits.rlim_max))",
      verdict: limits.rlim_cur >= 256 ? .asAssumed : .surprise,
      assumption: .checkDescriptorLimitAssumption
    )
  }

  /// The routing table, which macOS reads to pick the interface. iPadOS ranks interfaces
  /// by kind instead; a readable table would let it ask the route as macOS does.
  static func routeTable() -> CapabilityCheck {
    let size = sysctlSize([CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_DUMP, 0])
    return CapabilityCheck(
      id: "routeTable", title: .checkRouteTable,
      outcome: size.map { String(localized: .checkBytes($0)) } ?? describe(errno),
      verdict: .asAssumed,
      assumption: .checkRouteTableAssumption
    )
  }

  /// The ARP table. Empty, or unreadable, is what the composition assumes.
  static func neighborTable() -> CapabilityCheck {
    let rtfLLInfo: Int32 = 0x400  // RTF_LLINFO; <net/route.h> is not in the iOS SDK
    let size = sysctlSize([CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, rtfLLInfo])
    return CapabilityCheck(
      id: "neighborTable", title: .checkNeighborTable,
      outcome: size.map { String(localized: .checkBytes($0)) } ?? describe(errno),
      verdict: (size ?? 0) == 0 ? .asAssumed : .surprise,
      assumption: .checkNeighborTableAssumption
    )
  }

  /// Whether interfaces report a real hardware address or iOS's placeholder.
  static func hardwareAddress() -> CapabilityCheck {
    var head: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&head) == 0, let first = head else {
      return CapabilityCheck(
        id: "hardwareAddress", title: .checkHardwareAddress, outcome: describe(errno),
        verdict: .surprise, assumption: .checkHardwareAddressAssumption
      )
    }
    defer { freeifaddrs(head) }
    var found: String?
    var cursor: UnsafeMutablePointer<ifaddrs>? = first
    while let entry = cursor, found == nil {
      defer { cursor = entry.pointee.ifa_next }
      guard let address = entry.pointee.ifa_addr, address.pointee.sa_family == AF_LINK,
            String(cString: entry.pointee.ifa_name) == "en0" else { continue }
      let raw = UnsafeRawPointer(address)
      let nameLength = Int(raw.load(fromByteOffset: 5, as: UInt8.self))
      guard raw.load(fromByteOffset: 6, as: UInt8.self) == 6 else { continue }
      found = (0..<6)
        .map { String(format: "%02x", raw.load(fromByteOffset: 8 + nameLength + $0, as: UInt8.self)) }
        .joined(separator: ":")
    }
    let placeholder = found == "02:00:00:00:00:00"
    return CapabilityCheck(
      id: "hardwareAddress", title: .checkHardwareAddress,
      outcome: found ?? String(localized: .checkNone),
      verdict: placeholder || found == nil ? .asAssumed : .surprise,
      assumption: .checkHardwareAddressAssumption
    )
  }

  /// Whether every Bonjour type the browser asks for is declared; one that is not browses
  /// to silence, which looks exactly like a device that is not there.
  static func bonjourDeclared() -> CapabilityCheck {
    let declared = Bundle.main.object(forInfoDictionaryKey: "NSBonjourServices") as? [String] ?? []
    let missing = BonjourVocabulary.browsedTypes.filter { !declared.contains($0) }
    return CapabilityCheck(
      id: "bonjourDeclared", title: .checkBonjourDeclared,
      outcome: missing.isEmpty
        ? String(localized: .checkAllDeclared(BonjourVocabulary.browsedTypes.count))
        : missing.joined(separator: ", "),
      verdict: missing.isEmpty ? .asAssumed : .surprise,
      assumption: .checkBonjourDeclaredAssumption
    )
  }

  /// A sysctl's size in bytes, or nil with errno set.
  private static func sysctlSize(_ name: [Int32]) -> Int? {
    var mib = name
    var size = 0
    guard sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0) == 0 else { return nil }
    return size
  }

  private static func describe(_ code: Int32) -> String {
    "\(String(cString: strerror(code))) (errno \(code))"
  }
}
