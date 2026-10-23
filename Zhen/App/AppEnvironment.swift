import Foundation

/// What this launch was asked to be, read once from the process and injected.
///
/// The house rules' one reader of `ProcessInfo`: nothing else in the app looks at launch
/// arguments or the environment. Tests and previews select fixtures here, so they never see
/// or touch the history this iPad has kept.
nonisolated struct AppEnvironment: Sendable {
  /// Where devices, events and scans come from.
  enum DataSource: Sendable, Equatable {
    /// The app's history file and the real network.
    case live
    /// The invented fixture network, in memory, and a scanner that replays it.
    case fixture
  }

  var dataSource: DataSource
  /// `-UITesting`: fixtures, and a fixture scanner fast enough for a test to wait on.
  var isUITesting: Bool
  /// `-ShowcaseData`: fixtures at a pace a person can watch.
  var isShowcase: Bool
  /// `-Fixture empty`: which fixture network a fixture launch seeds.
  var fixtureVariant: FixtureNetwork.Variant
  /// How long the fixture scanner waits between events. `-ScanPace <milliseconds>`.
  var scanPace: Duration
  /// The process environment, for `HistoryLocation`.
  var processEnvironment: [String: String]
  /// When this launch began; the fixture network is laid out relative to it.
  var launchedAt: Date

  var usesFixtures: Bool { dataSource == .fixture }

  /// Parses launch arguments. Unknown arguments are ignored: UIKit and XCTest add their own.
  static func parse(arguments: [String], environment: [String: String], now: Date) -> AppEnvironment {
    func value(after flag: String) -> String? {
      guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
        return nil
      }
      return arguments[index + 1]
    }
    // The unit-test host is this app, launched with no arguments. Without this it would open
    // the real history file — tests must never see real data.
    let unitTestHost = environment["XCTestConfigurationFilePath"] != nil
      || environment["XCTestBundlePath"] != nil
    let uiTesting = arguments.contains("-UITesting") || unitTestHost
    let showcase = arguments.contains("-ShowcaseData")
    let defaultPace = uiTesting ? 20 : 150
    let pace = value(after: "-ScanPace").flatMap(Int.init) ?? defaultPace

    return AppEnvironment(
      dataSource: uiTesting || showcase ? .fixture : .live,
      isUITesting: uiTesting,
      isShowcase: showcase,
      fixtureVariant: value(after: "-Fixture").flatMap(FixtureNetwork.Variant.init(rawValue:)) ?? .network,
      scanPace: .milliseconds(pace),
      processEnvironment: environment,
      launchedAt: now
    )
  }

  /// This process's launch, parsed once.
  static let current = parse(
    arguments: ProcessInfo.processInfo.arguments,
    environment: ProcessInfo.processInfo.environment,
    now: .now
  )
}
