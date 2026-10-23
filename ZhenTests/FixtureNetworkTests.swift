import Foundation
import Testing
import ZhenCore
@testable import Zhen

/// The fixture must show an iPad's view of the network, never a Mac's: a screenshot of a
/// capability the iPad does not have is a screenshot of a feature that does not exist.
@Suite("The fixture network, as an iPad would see it")
struct FixtureNetworkTests {
  private func report() throws -> ScanReport {
    FixtureNetwork.ipadReport(from: try FixtureNetwork.capture(), now: .now)
  }

  @Test("No hardware addresses and no vendors: iPadOS withholds the neighbour table")
  func noHardware() throws {
    let devices = try report().devices
    #expect(!devices.isEmpty)
    #expect(devices.allSatisfy { $0.mac == nil && $0.vendor == nil })
  }

  @Test("No UPnP names: SSDP is off without the multicast entitlement")
  func noUPnP() throws {
    #expect(try report().devices.allSatisfy { device in device.names.allSatisfy { $0.source != .ssdp } })
  }

  @Test("No host the ARP cache alone supplied")
  func noNeighborOnlyHosts() throws {
    let capture = try FixtureNetwork.capture()
    let neighborOnly = capture.devices.filter { $0.discoveredVia.allSatisfy { $0 == .neighborTable } }
    #expect(!neighborOnly.isEmpty, "the capture should hold some, or this test proves nothing")
    let addresses = Set(try report().devices.flatMap(\.ipv4Addresses))
    #expect(neighborOnly.allSatisfy { !$0.ipv4Addresses.contains(where: addresses.contains) })
  }

  @Test("The engine named in the run claims nothing an iPad lacks")
  func engine() throws {
    let claimed = try report().run.engine.capabilities
    for absent: EngineCapabilities in [.arpSweep, .synScan, .osFingerprint, .neighborTable] {
      #expect(!claimed.contains(absent))
    }
  }
}
