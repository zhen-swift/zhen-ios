import Foundation
import ZhenCore

/// Which ports a person asked about, as the Scan Ports sheet holds it.
///
/// The presets are the engine's own sets, and a custom spec is parsed by the engine's own
/// parser (`PortSpec.parse`): this app never has a second idea of what `22,80,8000-8100`
/// or `U:53` means.
nonisolated struct PortChoice: Hashable, Sendable {
  enum Preset: String, CaseIterable, Identifiable, Sendable {
    /// `PortSpec.commonServices`: what a home network actually answers on.
    case common
    /// The common TCP set, plus the UDP services the engine has probes for.
    case commonWithUDP
    /// Typed by the person: lists, ranges, `U:` and `T:`, service names, `!` exclusions.
    case custom

    var id: String { rawValue }
  }

  var preset: Preset = .common
  var custom = ""

  /// The UDP ports the engine sends a real request to — DNS, NTP, NetBIOS, SNMPv3, SSDP and
  /// mDNS (zhen-core's `UDPPayloads`). Any other UDP port gets an empty datagram, and
  /// silence there proves nothing, so the preset does not ask.
  static let commonUDP: [UInt16] = [53, 123, 137, 161, 1900, 5353]

  /// Above this many probes a scan asks first. `zhen ports`'s threshold: above a /24 of
  /// common ports, below every port on one host.
  static let confirmationThreshold = 50_000

  /// The spec, or the parser's sentence about why there is none.
  var spec: Result<PortSpec, PortSpec.ParseError> {
    switch preset {
    case .common:
      return .success(.commonServices)
    case .commonWithUDP:
      return .success(PortSpec(PortSpec.commonServices.ports, udp: Self.commonUDP))
    case .custom:
      do {
        return .success(try PortSpec.parse(custom))
      } catch {
        return .failure(error)
      }
    }
  }

  /// How long a scan of `spec` across `hosts` hosts may take.
  ///
  /// `zhen ports`'s 20-second default, or longer when the probe count needs it: the floor
  /// is the number of rounds the engines need at their concurrency, each at most their
  /// per-host ceiling (600 ms TCP, one second UDP), and the budget allows half again.
  static func budget(for spec: PortSpec, hosts: Int) -> Duration {
    func rounds(_ probes: Int, _ concurrency: Int) -> Int { (probes + concurrency - 1) / concurrency }
    let tcp = rounds(spec.ports.count * hosts, 256)
    let udp = rounds(spec.udpPorts.count * hosts, 32)
    let floor = Duration.milliseconds(600) * tcp + Duration.seconds(1) * udp
    return min(max(.seconds(20), floor * 3 / 2), .seconds(900))
  }

  /// Every probe a scan of `spec` across `hosts` hosts sends, retransmits aside.
  static func probes(for spec: PortSpec, hosts: Int) -> Int { spec.probeCount * hosts }
}
