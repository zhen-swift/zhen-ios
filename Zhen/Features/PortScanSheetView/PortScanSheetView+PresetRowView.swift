import SwiftUI

extension PortScanSheetView {
  /// One preset: its name, and a checkmark when it is the choice.
  struct PresetRowView: View {
    let title: LocalizedStringResource
    let preset: PortChoice.Preset
    @Binding var choice: PortChoice

    var body: some View {
      Button {
        choice.preset = preset
      } label: {
        HStack {
          Text(title)
            .foregroundStyle(.textPrimary)
          Spacer()
          if choice.preset == preset {
            Image(systemName: "checkmark")
              .foregroundStyle(.accent)
              .fontWeight(.semibold)
          }
        }
        .contentShape(.rect)
      }
      .accessibilityAddTraits(choice.preset == preset ? .isSelected : [])
      .accessibilityIdentifier("preset-\(preset.rawValue)")
      .sensoryFeedback(.selection, trigger: choice.preset)
    }
  }
}
