import UIKit

/// Where the Settings app keeps this app's own page.
///
/// The Local Network permission is on it. iPadOS offers no way to ask whether the
/// permission was granted, so the app can only infer a denial and point here.
enum SystemSettings {
  static var appSettings: URL? { URL(string: UIApplication.openSettingsURLString) }
}
