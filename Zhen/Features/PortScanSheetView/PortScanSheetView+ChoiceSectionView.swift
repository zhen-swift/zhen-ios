import SwiftUI
import ZhenCore

extension PortScanSheetView {
  /// The preset, or a spec typed by hand, checked as it is typed.
  ///
  /// Rows rather than a `Picker`: each is a button with its own identifier and the
  /// selected trait, which an inline picker's rows do not expose to UI tests.
  struct ChoiceSectionView: View {
    @Binding var choice: PortChoice
    @FocusState private var editing: Bool

    var body: some View {
      Section {
        PresetRowView(title: .presetCommon, preset: .common, choice: $choice)
        PresetRowView(title: .presetCommonWithUDP, preset: .commonWithUDP, choice: $choice)
        PresetRowView(title: .presetCustom, preset: .custom, choice: $choice)

        if choice.preset == .custom {
          TextField(text: $choice.custom, prompt: Text(verbatim: "22,80,443,8000-8100,U:53")) {
            Text(.customPorts)
          }
          .font(.body.monospaced())
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .keyboardType(.asciiCapable)
          .focused($editing)
          .onAppear { editing = true }
          .accessibilityIdentifier("customPortsField")
        }
      } header: {
        Text(.ports)
      } footer: {
        ChoiceFooterView(choice: choice)
      }
    }
  }
}
