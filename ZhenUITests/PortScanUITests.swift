import XCTest

/// The flows this app exists for: open a device, see its ports, scan the ports you choose
/// on the devices you choose.
final class PortScanUITests: XCTestCase {
  override func setUp() {
    continueAfterFailure = false
  }

  @MainActor
  func testOpeningADeviceShowsItsPorts() {
    let app = launch()
    let detail = DevicesRobot(app: app).waitForList().open("192.168.50.32")
    XCTAssertTrue(detail.portsCard.waitForExistence(timeout: 5))
    XCTAssertTrue(detail.openPort(443).exists)
    XCTAssertTrue(detail.openPort(445).exists)
    snapshot(app, "detail-archive")
  }

  @MainActor
  func testCustomTCPAndUDPScanOfOneDevice() {
    let app = launch()
    let sheet = DevicesRobot(app: app).waitForList().open("192.168.50.50").scanPorts()
    sheet.custom("22,80,U:53,123")
    snapshot(app, "sheet-custom")
    let detail = sheet.start()
    XCTAssertTrue(detail.openPort(53, "udp").waitForExistence(timeout: 10), "UDP 53 did not come back open")
    XCTAssertTrue(detail.openPort(22).exists)
    snapshot(app, "detail-pihole-after-scan")
  }

  @MainActor
  func testASpecThatDoesNotParseCannotStart() {
    let app = launch()
    let sheet = DevicesRobot(app: app).waitForList().open("192.168.50.32").scanPorts()
    sheet.custom("80-")
    XCTAssertTrue(sheet.specError.waitForExistence(timeout: 5))
    XCTAssertFalse(sheet.startButton.isEnabled)
  }

  @MainActor
  func testScanningThePortsOfSeveralDevices() {
    let app = launch()
    let devices = DevicesRobot(app: app).waitForList()
    devices.select(["192.168.50.30", "192.168.50.32", "192.168.50.35"])
    snapshot(app, "several-selected")
    devices.scanPortsOfSelection().start()
    // Each device's row shows its open count once the scan is done.
    let printer = devices.row("192.168.50.30")
    XCTAssertTrue(printer.waitForExistence(timeout: 10))
    XCTAssertFalse(app.descendants(matching: .any)["portScanRunning"].waitForExistence(timeout: 2))
  }

  @MainActor
  func testANeverScannedLaunchScansFromTheEmptyState() {
    let app = launch(["-Fixture", "empty"])
    snapshot(app, "empty")
    let devices = DevicesRobot(app: app).scanFromEmptyState()
    XCTAssertTrue(devices.row("192.168.50.32").waitForExistence(timeout: 20))
    snapshot(app, "after-first-scan")
  }
}
