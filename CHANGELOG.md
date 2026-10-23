# Changelog

Notable changes, newest first. The engine's own changes are in
[zhen-core's changelog](https://github.com/zhen-swift/zhen-core/blob/main/CHANGELOG.md).

## Unreleased

### Added
- **The first iPad app.** On zhen-core 0.9.0, the first engine release that builds for
  iPadOS.
  - **Layout:** a split view, with devices in the sidebar (online first, then seen
    before) and the selected device beside them. It collapses to a stack when the app is
    narrow.
  - **Device detail:** the name and how sure the app is of it, every name by source, the
    address, TTL and OS hint, round trip, how the device was found, and when it was first
    and last seen.
  - **Ports:**
    - A summary by state.
    - Open ports with what identified the service (banner, TLS certificate or handshake),
      and never a service guessed from a port number.
    - Closed and filtered ports behind a disclosure.
  - **Scan Ports, for the devices you pick:** one device from its page, its row's swipe
    action or its context menu, or several selected at once. The sheet offers:
    - common services
    - common services with UDP
    - a custom spec in the engine's own grammar, checked as it is typed
    - the probe count and a time ceiling, shown before the scan starts
    - a confirmation before a very large scan
  - **Scans:** a plain scan, or a scan that also checks the ports of new devices or of
    every device. Stop works for both. The screen stays on while a scan runs.
  - **Diagnostics:** what this iPad's sandbox allows, checked call by call and shareable as
    text.
  - **History:** kept in the app's container, so first-seen and last-seen survive a
    relaunch.
