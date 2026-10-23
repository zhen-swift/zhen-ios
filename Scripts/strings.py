#!/usr/bin/env python3
"""strings.py — write Zhen/Localizable.xcstrings from the table below.

The catalog generates Swift symbols (STRING_CATALOG_GENERATE_SYMBOLS): every key here is a
`LocalizedStringResource` the code names, `.scanThisNetwork`, and a key whose value has
format specifiers becomes a function, `.checkingPortsOn(36, "192.168.50.32")`. A key the
code uses and this table lacks is a compile error, which is the point of keeping the table
in one place.

Usage: Scripts/strings.py            write the catalog
       Scripts/strings.py --check    exit 1 if the committed catalog is stale
"""
import json
import sys
from pathlib import Path

STRINGS = {
    # ── Scanning ─────────────────────────────────────────────────────────────
    "noInterfaceForScanning": "No network interface could be used for scanning (%@). Connect to Wi-Fi and scan again.",
    "offlineSoPortsNotItsOwn": "This device is offline, so whatever answers at %@ may be another device. Its ports are not shown or saved here.",
    "stoppedBeforeAnyPortAnswered": "Stopped before any port answered.",
    "didNotAnswerThisTimeSo": "%@ did not answer this time, so no port was checked.",
    "thisIPad": "This iPad",
    "respondsToPing": "Responds to ping",
    "osHintUnixLike": "Unix-like",
    "osHintWindows": "Windows",
    "osHintNetworkDevice": "network equipment",
    # ── Diagnostics ──────────────────────────────────────────────────────────
    "diagnostics": "Diagnostics",
    "interface": "Interface",
    "engine": "Engine",
    "sandboxChecks": "What this iPad allows",
    "sandboxChecksFooter": "Each check makes the call the scanner, or a feature cut from it, would make. None sends anything on the network.",
    "checkIcmpSocket": "ICMP datagram socket",
    "checkOpened": "opened",
    "checkIcmpSocketAssumption": "Opens without privilege. The sweep depends on it.",
    "checkDescriptorLimit": "Open-file limit",
    "checkDescriptorLimitAssumption": "At least 256, or port scans run narrow.",
    "checkRouteTable": "Routing table",
    "checkBytes": "%lld bytes",
    "checkRouteTableAssumption": "Not used on iPadOS. If it is readable, the scan's interface could come from the route, as it does on a Mac.",
    "checkNeighborTable": "Neighbour table (ARP)",
    "checkNeighborTableAssumption": "Empty or unreadable. If not, hardware addresses could come back on iPadOS.",
    "checkHardwareAddress": "This iPad's hardware address",
    "checkNone": "none",
    "checkHardwareAddressAssumption": "The 02:00:00:00:00:00 placeholder, which the scanner ignores.",
    "checkBonjourDeclared": "Bonjour types declared",
    "checkAllDeclared": "All %lld declared",
    "checkBonjourDeclaredAssumption": "Every type the browser asks for. A missing one browses to silence.",
    "done": "Done",
    # ── Components ───────────────────────────────────────────────────────────
    "of": "%1$lld of %2$lld",
    "identified": "Identified",
    "partial": "Partial",
    "minimal": "Minimal",
    "identity": "Identity",
    "signal": "Signal",
    "online": "Online",
    "offline": "Offline",
    "warning": "Warning",
    "changed": "Changed",
    "merged": "Merged",
    "gone": "Gone",
    # ── Devices ──────────────────────────────────────────────────────────────
    "devices": "Devices",
    "selectADevice": "Select a device",
    "selectADeviceDescription": "Pick a device to see its names, its ports, and how it was found.",
    "onlineSection": "Online",
    "seenBeforeSection": "Seen before",
    "searchDevices": "Names and addresses",
    "scanPortsEllipsis": "Scan Ports…",
    "unidentifiedDevice": "Unidentified device",
    "scanningThisNetwork": "Scanning this network",
    "devicesAnsweredSoFar": "%lld answered so far",
    "notesFromLastScan": "From the last scan",
    "noScanYet": "No scan yet",
    "noScanYetDescription": "Scan to see every device on this network.",
    "scanThisNetwork": "Scan This Network",
    "nothingAnswered": "Nothing answered",
    "nothingAnsweredDescription": "No device answered the last scan. On an iPad that is usually the Local Network permission, which can't be checked directly. It is on Zhen's page in Settings.",
    "scanAgain": "Scan Again",
    "openSettings": "Open Settings",
    "stop": "Stop",
    "scan": "Scan",
    "scanAndCheckPortsOfNewDevices": "Scan, and Check Ports of New Devices",
    "scanAndCheckPortsOfEveryDevice": "Scan, and Check Ports of Every Device",
    "nDevicesSelected": "%lld devices selected",
    "scanPortsOfSelected": "Scan Ports of Selected…",
    # ── Device detail ────────────────────────────────────────────────────────
    "deviceNotFound": "Device not found",
    "deviceNotFoundDescription": "It is no longer in this iPad's history.",
    "onlineNow": "Online now",
    "lastSeen": "Last seen %@",
    "knownBy": "Known by",
    "knownByCaption": "best first",
    "noNameGiven": "This device gave no name.",
    "sourceAdministrative": "assigned",
    "sourceBonjour": "Bonjour",
    "sourceUPnP": "UPnP",
    "sourceNetBIOS": "NetBIOS",
    "sourceReverseDNS": "reverse DNS",
    "network": "Network",
    "addresses": "Addresses",
    "ttl": "TTL",
    "roundTrip": "Round trip",
    "foundBy": "Found by",
    "firstSeen": "First seen",
    "lastSeenTitle": "Last seen",
    "suggests": "suggests %@",
    "millisecondsValue": "%@ ms",
    "viaProbeReply": "answered a ping",
    "viaARPReply": "answered ARP",
    "viaNeighborResolved": "resolved during the scan",
    "viaNeighborTable": "neighbour table",
    "viaLocalInterface": "this iPad",
    # ── Ports ────────────────────────────────────────────────────────────────
    "ports": "Ports",
    "openPorts": "Open ports",
    "checkedPorts": "%1$lld ports checked %2$@",
    "fromAnEarlierScan": "From an earlier scan",
    "checkingPortsOn": "Checking %1$lld ports on %2$@",
    "noPortScanYet": "No port scan yet.",
    "noneOfNPortsWasOpen": "None of the %lld ports checked was open.",
    "notOpenCount": "%lld not open",
    "openCount": "%lld open",
    "closedCount": "%lld closed",
    "filteredCount": "%lld filtered",
    "openFilteredCount": "%lld open or filtered",
    "evidenceBanner": "banner",
    "evidenceTLS": "TLS certificate",
    "evidenceHandshake": "handshake",
    "portOpen": "open",
    "portClosed": "closed",
    "portFiltered": "filtered",
    "portOpenFiltered": "open or filtered",
    # ── Scan Ports sheet ─────────────────────────────────────────────────────
    "scanPorts": "Scan Ports",
    "cancel": "Cancel",
    "devicesHeader": "Devices · %lld",
    "offlineTargetsFooter": "An offline device's address may belong to another device now. What answers there is not saved as this device's.",
    "presetCommon": "Common services",
    "presetCommonWithUDP": "Common services and UDP",
    "presetCustom": "Custom",
    "customPorts": "Ports",
    "customPortsHelp": "Lists and ranges, like 22,80,8000-8100. U:53 for UDP, a service name like ssh, and ! to leave a port out.",
    "specSummary": "%1$lld TCP and %2$lld UDP ports",
    "probes": "Probes",
    "atMost": "At most",
    "estimateFooter": "A ceiling, not a forecast: most ports answer or are refused in milliseconds.",
    "largeScanTitle": "This is a large scan",
    "largeScanMessage": "%lld probes. It may take minutes, and every device scanned will see each one.",
    "scanAnyway": "Scan Anyway",
}


def catalog() -> str:
    strings = {
        key: {
            "extractionState": "manual",
            "localizations": {"en": {"stringUnit": {"state": "translated", "value": value}}},
        }
        for key, value in sorted(STRINGS.items())
    }
    document = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
    return json.dumps(document, indent=2, ensure_ascii=False, sort_keys=True) + "\n"


def main() -> int:
    path = Path(__file__).resolve().parent.parent / "Zhen" / "Localizable.xcstrings"
    text = catalog()
    if "--check" in sys.argv:
        if path.exists() and path.read_text() == text:
            print(f"strings: {path.name} is current ({len(STRINGS)} keys) — PASS")
            return 0
        print(f"strings: {path.name} is stale — FAIL; run Scripts/strings.py")
        return 1
    path.write_text(text)
    print(f"strings: wrote {len(STRINGS)} keys to {path.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
