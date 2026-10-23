import XCTest

/// The robots: what a person does, by accessibility identifier, never by label (AGENTS.md).
/// A test reads as a sequence of intentions; the queries live here. Main-actor isolated,
/// as XCUIElement is from Xcode 26.6's SDK on.
@MainActor
struct DevicesRobot {
  let app: XCUIApplication

  @discardableResult
  func waitForList(file: StaticString = #filePath, line: UInt = #line) -> Self {
    XCTAssertTrue(app.buttons["scanButton"].waitForExistence(timeout: 10), "no scan button", file: file, line: line)
    return self
  }

  func row(_ address: String) -> XCUIElement {
    app.descendants(matching: .any)["deviceRow-\(address)"].firstMatch
  }

  @discardableResult
  func open(_ address: String, file: StaticString = #filePath, line: UInt = #line) -> DetailRobot {
    let row = row(address)
    XCTAssertTrue(row.waitForExistence(timeout: 10), "no row for \(address)", file: file, line: line)
    row.tap()
    return DetailRobot(app: app)
  }

  @discardableResult
  func select(_ addresses: [String]) -> Self {
    app.buttons["selectButton"].tap()
    for address in addresses { row(address).tap() }
    return self
  }

  func scanPortsOfSelection() -> PortScanRobot {
    app.buttons["scanSelectedPortsButton"].tap()
    return PortScanRobot(app: app)
  }

  @discardableResult
  func scanFromEmptyState(file: StaticString = #filePath, line: UInt = #line) -> Self {
    let button = app.buttons["emptyScanButton"]
    XCTAssertTrue(button.waitForExistence(timeout: 10), "no empty-state scan", file: file, line: line)
    button.tap()
    return self
  }
}

@MainActor
struct DetailRobot {
  let app: XCUIApplication

  func openPort(_ port: Int, _ proto: String = "tcp") -> XCUIElement {
    app.descendants(matching: .any)["openPort-\(port)-\(proto)"].firstMatch
  }

  var portsCard: XCUIElement { app.descendants(matching: .any)["portsCard"].firstMatch }

  func scanPorts() -> PortScanRobot {
    app.buttons["scanPortsButton"].tap()
    return PortScanRobot(app: app)
  }
}

@MainActor
struct PortScanRobot {
  let app: XCUIApplication

  @discardableResult
  func custom(_ spec: String) -> Self {
    app.buttons["preset-custom"].tap()
    let field = app.textFields["customPortsField"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText(spec)
    return self
  }

  var startButton: XCUIElement { app.buttons["startPortScanButton"] }
  var specError: XCUIElement { app.descendants(matching: .any)["portSpecError"].firstMatch }

  @discardableResult
  func start() -> DetailRobot {
    startButton.tap()
    return DetailRobot(app: app)
  }
}

extension XCTestCase {
  /// The app on the fixture network, fast.
  @MainActor
  func launch(_ extra: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-UITesting"] + extra
    app.launch()
    return app
  }

  /// Keeps a screenshot with the test's result, for reading what the test saw.
  @MainActor
  func snapshot(_ app: XCUIApplication, _ name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
