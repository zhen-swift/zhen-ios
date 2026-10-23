import Foundation
import Testing
import ZhenCore
@testable import Zhen

@Suite("How devices read and sort in the list")
struct DeviceItemTests {
  private func item(_ address: String, name: String? = nil) -> DeviceItem {
    let ip = IPv4Address(address)!
    let facts = HostFacts(
      ip: ip,
      allNames: name.map { [NameCandidate(value: $0, source: .mdns)] } ?? [],
      ttl: 64,
      discoveredVia: [.probeReply]
    )
    let device = Device(observing: facts, in: IPv4Network("192.168.50.0/24")!)
    return DeviceItem(id: address, device: device, isOnline: true)
  }

  @Test("Named devices first, alphabetically; then the unnamed ones by address")
  func order() {
    let items = [item("192.168.50.9"), item("192.168.50.3", name: "Zebra"), item("192.168.50.20", name: "Archive")]
    #expect(items.sorted(by: DeviceItem.listOrder).map(\.address) == ["192.168.50.20", "192.168.50.3", "192.168.50.9"])
  }

  @Test("Addresses sort as numbers, not strings: .9 before .10")
  func addressOrder() {
    let items = [item("192.168.50.10"), item("192.168.50.9")]
    #expect(items.sorted(by: DeviceItem.addressOrder).map(\.address) == ["192.168.50.9", "192.168.50.10"])
  }

  @Test("An unnamed device still says what is known")
  func subtitle() {
    let subtitle = item("192.168.50.9").subtitle
    #expect(subtitle.contains(DeviceItem.Words.respondsToPing))
    #expect(subtitle.contains(DeviceItem.Words.osHint(.unixLike)))
  }

  @Test("Search finds a device by name and by address")
  func search() {
    let archive = item("192.168.50.32", name: "Archive")
    #expect(archive.matches("arch"))
    #expect(archive.matches("50.32"))
    #expect(!archive.matches("printer"))
    #expect(archive.matches("  "))
  }
}
