import Foundation
import ZhenCore

extension DeviceDetailView {
  /// The device as core records it, for Share: the same JSON a report carries.
  static func json(_ device: Device) -> String {
    let encoder = ScanReport.makeEncoder()
    encoder.outputFormatting.insert(.prettyPrinted)
    guard let data = try? encoder.encode(device) else { return "{}" }
    return String(decoding: data, as: UTF8.self)
  }

  /// How sure the app is of who a device is, in a word.
  static func word(for identification: Identification) -> LocalizedStringResource {
    switch identification {
    case .identified: .identified
    case .partial: .partial
    case .minimal: .minimal
    }
  }

  /// Where a name came from, said the way a person would.
  static func label(for source: NameSource) -> LocalizedStringResource {
    switch source {
    case .administrative: .sourceAdministrative
    case .mdns: .sourceBonjour
    case .ssdp: .sourceUPnP
    case .netbios: .sourceNetBIOS
    case .dns: .sourceReverseDNS
    }
  }

  /// How the scan came to know about a device.
  static func label(for source: DiscoverySource) -> LocalizedStringResource {
    switch source {
    case .probeReply: .viaProbeReply
    case .arpReply: .viaARPReply
    case .neighborResolved: .viaNeighborResolved
    case .neighborTable: .viaNeighborTable
    case .localInterface: .viaLocalInterface
    }
  }

  /// What a port's identity rests on.
  static func label(for evidence: ServiceEvidence) -> LocalizedStringResource {
    switch evidence {
    case .banner: .evidenceBanner
    case .tlsCertificate: .evidenceTLS
    case .protocolHandshake: .evidenceHandshake
    }
  }

  /// A port's state, as a word.
  static func label(for state: PortState) -> LocalizedStringResource {
    switch state {
    case .open: .portOpen
    case .closed: .portClosed
    case .filtered: .portFiltered
    case .openFiltered: .portOpenFiltered
    }
  }
}
