import SwiftUI
import ZhenCore

extension DeviceDetailView {
  /// Every name the device gave, by the source that gave it. The first is the one shown.
  struct KnownByCardView: View {
    let item: DeviceItem

    var body: some View {
      Card(.knownBy, caption: String(localized: .knownByCaption)) {
        VStack(alignment: .leading, spacing: .spacing.medium) {
          if names.isEmpty {
            Text(.noNameGiven)
              .font(.subheadline)
              .foregroundStyle(.textSecondary)
          } else {
            ForEach(names.enumerated(), id: \.offset) { index, candidate in
              HStack(alignment: .firstTextBaseline, spacing: .spacing.small) {
                VStack(alignment: .leading, spacing: .spacing.xxSmall) {
                  Text(candidate.value)
                    .font(.body)
                    .foregroundStyle(index == 0 ? .textPrimary : .textSecondary)
                    .textSelection(.enabled)
                  if let model = candidate.model {
                    Text(model)
                      .font(.caption)
                      .foregroundStyle(.textSecondary)
                  }
                }
                Spacer(minLength: .spacing.small)
                Chip(DeviceDetailView.label(for: candidate.source), style: index == 0 ? .accent : .neutral)
              }
              .accessibilityElement(children: .combine)
            }
          }
        }
        .padding(.spacing.large)
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("knownByCard")
    }

    /// Distinct names, best first.
    private var names: [NameCandidate] {
      var seen: Set<String> = []
      return item.device.names.sorted().filter { seen.insert("\($0.source.rawValue)|\($0.value)").inserted }
    }
  }
}
