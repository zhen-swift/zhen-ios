import Testing
import ZhenCore
@testable import Zhen

@Suite("Choosing ports: the engine's sets and the engine's grammar")
struct PortChoiceTests {
  @Test("Common services is the engine's own set, TCP only")
  func common() throws {
    let spec = try PortChoice(preset: .common).spec.get()
    #expect(spec == .commonServices)
    #expect(spec.udpPorts.isEmpty)
  }

  @Test("Common services and UDP adds the UDP ports the engine has real probes for")
  func commonWithUDP() throws {
    let spec = try PortChoice(preset: .commonWithUDP).spec.get()
    #expect(spec.ports == PortSpec.commonServices.ports)
    #expect(spec.udpPorts == [53, 123, 137, 161, 1900, 5353])
  }

  @Test("A custom spec is parsed by the engine: lists, ranges, UDP, names")
  func custom() throws {
    let spec = try PortChoice(preset: .custom, custom: "22,80,8000-8002,U:53,ssh").spec.get()
    #expect(spec.ports.contains(22))
    #expect(spec.ports.contains(8001))
    #expect(spec.udpPorts == [53])
  }

  @Test("A spec that does not parse carries the engine's sentence")
  func invalid() {
    guard case .failure(let error) = PortChoice(preset: .custom, custom: "80-").spec else {
      Issue.record("80- parsed")
      return
    }
    #expect(!error.message.isEmpty)
  }

  @Test("The budget is the CLI's 20 s for small scans, and grows with the probe count")
  func budget() {
    #expect(PortChoice.budget(for: .commonServices, hosts: 1) == .seconds(20))
    let wide = PortSpec(Array(1...10_000))
    #expect(PortChoice.budget(for: wide, hosts: 4) > .seconds(20))
    #expect(PortChoice.budget(for: PortSpec(Array(1...65_535)), hosts: 254) == .seconds(900))
  }

  @Test("Every port on one host asks first; common ports on a /24 does not")
  func confirmation() {
    let everything = PortSpec(Array(1...65_535))
    #expect(PortChoice.probes(for: everything, hosts: 1) > PortChoice.confirmationThreshold)
    #expect(PortChoice.probes(for: .commonServices, hosts: 254) < PortChoice.confirmationThreshold)
  }
}
