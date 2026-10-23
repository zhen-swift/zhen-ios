import SwiftUI
import ZhenCore

extension DevicesView {
  /// What the last scan reported going wrong, in the engine's own sentences.
  ///
  /// Core writes each one as a consequence ("Bonjour names can't be read this scan"), and
  /// hedges what it inferred, so they are shown as written rather than summarised.
  struct NotesSectionView: View {
    let degradations: [Degradation]

    var body: some View {
      Section(.notesFromLastScan) {
        ForEach(degradations.enumerated(), id: \.offset) { _, degradation in
          Label {
            Text(degradation.reason)
              .font(.footnote)
              .foregroundStyle(.textSecondary)
          } icon: {
            StatusDot(degradation.recoverable ? .warning : .neutral)
          }
          .accessibilityElement(children: .combine)
        }
      }
    }
  }
}
