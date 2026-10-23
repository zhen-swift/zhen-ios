import SwiftUI
import UIKit

/// Keeps the screen on while a scan runs.
///
/// iPadOS suspends an app whose screen locks, and a suspended scan is not a slow scan, it
/// is a stopped one. There is no background mode for this work, so the honest fix is to
/// keep the app in front for the length of a scan — and only that long.
private struct KeepsScreenAwake: ViewModifier {
  let isActive: Bool

  func body(content: Content) -> some View {
    content
      .onChange(of: isActive, initial: true) { _, active in
        UIApplication.shared.isIdleTimerDisabled = active
      }
      .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
  }
}

extension View {
  /// Disables the idle timer while `isActive` holds.
  func keepsScreenAwake(_ isActive: Bool) -> some View {
    modifier(KeepsScreenAwake(isActive: isActive))
  }
}
