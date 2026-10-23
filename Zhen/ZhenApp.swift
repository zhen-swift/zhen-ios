import SwiftUI

@main
struct ZhenApp: App {
  @State private var model = NetworkModel(environment: .current)

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(model)
        .scanHost(model)
    }
  }
}
