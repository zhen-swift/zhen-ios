import SwiftUI

extension PortScanSheetView {
  /// Which devices the scan is for.
  struct TargetsSectionView: View {
    let items: [DeviceItem]

    var body: some View {
      Section {
        ForEach(items) { item in
          LabeledContent {
            Text(item.address)
              .font(.callout.monospaced())
          } label: {
            HStack(spacing: .spacing.small) {
              StatusDot(item.isOnline ? .online : .offline)
              Text(item.name ?? String(localized: .unidentifiedDevice))
            }
          }
          .accessibilityElement(children: .combine)
        }
      } header: {
        Text(.devicesHeader(items.count))
      } footer: {
        if items.contains(where: { !$0.isOnline }) {
          Text(.offlineTargetsFooter)
        }
      }
    }
  }
}
