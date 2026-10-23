import Foundation
import Testing
import ZhenCore
@testable import Zhen

@Suite("Launch arguments, and the Info.plist the engine needs")
struct AppEnvironmentTests {
  @Test("A plain launch is live; -UITesting and -ShowcaseData are fixtures")
  func dataSource() {
    #expect(AppEnvironment.parse(arguments: [], environment: [:], now: .now).dataSource == .live)
    #expect(AppEnvironment.parse(arguments: ["-UITesting"], environment: [:], now: .now).dataSource == .fixture)
    #expect(AppEnvironment.parse(arguments: ["-ShowcaseData"], environment: [:], now: .now).dataSource == .fixture)
  }

  @Test("The unit-test host never opens the real history")
  func testHost() {
    let environment = AppEnvironment.parse(
      arguments: [], environment: ["XCTestConfigurationFilePath": "/tmp/x"], now: .now
    )
    #expect(environment.usesFixtures)
  }

  @Test("-Fixture picks the variant; -ScanPace the fixture scanner's pace")
  func variantAndPace() {
    let environment = AppEnvironment.parse(
      arguments: ["-UITesting", "-Fixture", "empty", "-ScanPace", "5"], environment: [:], now: .now
    )
    #expect(environment.fixtureVariant == .empty)
    #expect(environment.scanPace == .milliseconds(5))
  }

  // A browsed Bonjour type that is not declared returns nothing, silently — it looks
  // exactly like a device that is not there. Fix: Scripts/generate-bonjour-services.sh.
  @Test("Every Bonjour type the engine browses is declared in the built Info.plist")
  func bonjourDeclared() throws {
    let declared = try #require(Bundle.main.object(forInfoDictionaryKey: "NSBonjourServices") as? [String])
    #expect(declared == BonjourVocabulary.browsedTypes)
  }

  @Test("The Local Network purpose string is there")
  func localNetwork() {
    let purpose = Bundle.main.object(forInfoDictionaryKey: "NSLocalNetworkUsageDescription") as? String
    #expect(purpose?.isEmpty == false)
  }
}
