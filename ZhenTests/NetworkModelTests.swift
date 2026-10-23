import Foundation
import Testing
import ZhenCore
@testable import Zhen

/// The model against the fixture scanner: what a scan and a port scan do to what the app
/// shows, and the rule that only one runs at a time.
@Suite("The network model")
struct NetworkModelTests {
  private func loaded(_ variant: FixtureNetwork.Variant = .network) async -> NetworkModel {
    let model = NetworkModel(environment: .preview(variant, pace: .zero))
    await model.load()
    return model
  }

  private func device(named name: String, in model: NetworkModel) throws -> DeviceItem {
    try #require(model.devices.first { $0.name == name })
  }

  @Test("Loading the fixture shows the network an iPad would find")
  func load() async {
    let model = await loaded()
    #expect(model.hasLoaded)
    #expect(model.devices.count == 14)
    #expect(model.devices.allSatisfy { $0.device.mac == nil && $0.device.vendor == nil })
    #expect(model.interface?.network.description == "192.168.50.0/24")
  }

  @Test("A never-scanned launch has no devices and no run")
  func empty() async {
    let model = await loaded(.empty)
    #expect(model.devices.isEmpty)
    #expect(model.latestRun == nil)
  }

  @Test("A port scan of one device: running, then the ports it asked about, in history too")
  func portScanOne() async throws {
    let model = await loaded()
    let archive = try device(named: "Archive", in: model)
    let spec = try PortSpec.parse("22,443,445,U:53")

    model.scanPorts([archive.id], spec: spec, budget: .seconds(20))
    #expect(model.isBusy)
    #expect(model.portScans[archive.id]?.state == .running(probes: 4))

    await model.performPortScan()
    #expect(!model.isBusy)
    let scan = try #require(model.portScans[archive.id])
    #expect(scan.state == .finished)
    let summary = PortSummary(scan.ports)
    #expect(summary.open == 2)      // 443 and 445, as the capture has them
    #expect(summary.closed == 2)    // 22/tcp, and 53/udp: Archive serves no DNS
    #expect(scan.ports.contains { $0.port == 53 && $0.proto == .udp })
    // Folded into history, not only into this session.
    let reloaded = try device(named: "Archive", in: model)
    #expect(reloaded.device.ports.contains { $0.port == 443 && $0.state == .open })
  }

  @Test("UDP answers come back where the fixture network serves them")
  func udp() async throws {
    let model = await loaded()
    let pihole = try device(named: "PIHOLE", in: model)
    model.scanPorts([pihole.id], spec: PortSpec([], udp: [53, 123]), budget: .seconds(20))
    await model.performPortScan()
    let ports = try #require(model.portScans[pihole.id]?.ports)
    #expect(ports.first { $0.port == 53 }?.state == .open)
    #expect(ports.first { $0.port == 53 }?.service?.name == "dns")
    #expect(ports.first { $0.port == 123 }?.state == .closed)
  }

  // The screenshots of the first build showed PIHOLE's row at "4 open" and its card at 3:
  // the card showed only this session's scan, the row history's merge.
  @Test("The card and the row agree on the open count after a scan")
  func rowAndCardAgree() async throws {
    let model = await loaded()
    let pihole = try device(named: "PIHOLE", in: model)
    model.scanPorts([pihole.id], spec: try PortSpec.parse("22,80,U:53,123"), budget: .seconds(20))
    await model.performPortScan()
    let after = try device(named: "PIHOLE", in: model)
    #expect(PortSummary(model.ports(for: after)).open == after.openPortCount)
    #expect(model.ports(for: after).contains { $0.port == 123 && $0.state == .closed })
  }

  @Test("Several devices in one port scan each get their own result")
  func portScanSeveral() async throws {
    let model = await loaded()
    let ids = try ["Archive", "Office Printer", "Hue Bridge"].map { try device(named: $0, in: model).id }
    model.scanPorts(ids, spec: .commonServices, budget: .seconds(20))
    #expect(ids.allSatisfy { model.portScans[$0]?.isRunning == true })
    await model.performPortScan()
    for id in ids {
      #expect(model.portScans[id]?.state == .finished)
    }
  }

  @Test("One scan at a time: nothing starts while a port scan runs")
  func busy() async throws {
    let model = await loaded()
    let archive = try device(named: "Archive", in: model)
    let printer = try device(named: "Office Printer", in: model)
    model.scanPorts([archive.id], spec: .commonServices, budget: .seconds(20))
    let target = model.portScanTarget

    model.startScan()
    #expect(model.scanToken == nil)
    model.scanPorts([printer.id], spec: .commonServices, budget: .seconds(20))
    #expect(model.portScanTarget == target)
    #expect(model.portScans[printer.id] == nil)

    model.stopScanning()
    #expect(!model.isBusy)
  }

  @Test("A scan counts arrivals as they come, and ends with history reloaded")
  func scan() async {
    let model = await loaded(.empty)
    model.startScan()
    #expect(model.isScanning)
    await model.performScan()
    #expect(!model.isScanning)
    #expect(model.liveFound == 14)
    #expect(model.devices.count == 14)
    #expect(model.latestRun != nil)
  }

  @Test("A device with no IPv4 address is not port-scanned")
  func noIPv4() async {
    let model = await loaded()
    model.scanPorts(["no-such-device"], spec: .commonServices, budget: .seconds(20))
    #expect(model.portScanTarget == nil)
  }
}
