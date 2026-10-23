import SwiftUI

/// A fixture model for previews: the invented network, in memory, loaded on appear.
///
/// One container, reused by every preview, so a preview never builds its own idea of the
/// app's state.
struct PreviewContainer<Content: View>: View {
  @State private var model: NetworkModel
  private let content: (NetworkModel) -> Content

  init(
    _ variant: FixtureNetwork.Variant = .network,
    @ViewBuilder content: @escaping (NetworkModel) -> Content
  ) {
    _model = State(initialValue: NetworkModel(environment: .preview(variant)))
    self.content = content
  }

  init(_ variant: FixtureNetwork.Variant = .network, @ViewBuilder content: @escaping () -> Content) {
    self.init(variant) { _ in content() }
  }

  var body: some View {
    content(model)
      .environment(model)
      .scanHost(model)
  }
}

extension AppEnvironment {
  /// A fixture launch, as a preview or a test makes one.
  static func preview(
    _ variant: FixtureNetwork.Variant = .network, pace: Duration = .milliseconds(100)
  ) -> AppEnvironment {
    AppEnvironment(
      dataSource: .fixture,
      isUITesting: false,
      isShowcase: true,
      fixtureVariant: variant,
      scanPace: pace,
      processEnvironment: [:],
      launchedAt: .now
    )
  }
}
