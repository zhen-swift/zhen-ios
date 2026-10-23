import SwiftUI
import ZhenCore

extension DeviceDetailView {
  /// Which ports answered, what is listening on the open ones, and what was checked.
  ///
  /// Open ports lead, with what identified the service — a banner, a TLS certificate, a
  /// handshake — because a name with no evidence behind it is a guess, and this app does
  /// not guess a service from a port number. A port that answered without saying what it
  /// was shows a dash. Closed and filtered ports are counted, and listed on request.
  struct PortsCardView: View {
    let item: DeviceItem
    let scan: PortScan?
    let ports: [PortObservation]
    let canScan: Bool
    let onScanPorts: () -> Void

    var body: some View {
      Card(.ports, caption: caption) {
        VStack(alignment: .leading, spacing: .zero) {
          if case .running(let probes) = scan?.state {
            RunningView(probes: probes, since: scan?.at ?? .now, host: item.address)
            Divider()
          } else if case .failed(let reason) = scan?.state {
            Text(reason)
              .font(.subheadline)
              .foregroundStyle(.textSecondary)
              .padding(.spacing.large)
              .accessibilityIdentifier("portScanFailure")
            Divider()
          }
          PortListView(ports: ports, canScan: canScan, onScanPorts: onScanPorts)
        }
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("portsCard")
    }

    /// When the ports shown were checked, and where they came from.
    private var caption: String? {
      if let scan, scan.state == .finished {
        return String(localized: .checkedPorts(scan.ports.count, scan.at.formatted(.relative(presentation: .named))))
      }
      if scan == nil, !ports.isEmpty { return String(localized: .fromAnEarlierScan) }
      return nil
    }
  }
}
