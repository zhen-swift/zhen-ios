# Zhen for iPad

Who is on your network, from an iPad: every device that answers, what it calls itself,
and — when you ask about a specific one — which ports it has open and what is listening
on them.

It is the iPad sibling of [Zhen for Mac](https://github.com/zhen-swift/zhen-app), on the
same engine, [zhen-core](https://github.com/zhen-swift/zhen-core). It is a separate app
rather than an iPad build of the Mac one because the Mac app is built around privileges
an iPad does not have: a packet-capture helper, the layer-2 sweep, the neighbour table.
What the iPad gets is the engine's unprivileged half.

## What it does on an iPad

| | |
|---|---|
| Finds devices | ICMP echo sweep of the network the iPad is on |
| Names them | Bonjour and NetBIOS |
| Scans ports | TCP connect, with banners and TLS certificates; UDP for the services the engine has probes for. For the hosts **you** pick, with the ports you pick |
| Remembers | History in the app's own container: first seen, last seen, what changed |

What it does not do, and why, is in zhen-core's
[`Docs/IPADOS.md`](https://github.com/zhen-swift/zhen-core/blob/main/Docs/IPADOS.md): no
hardware addresses or vendors (iPadOS withholds the neighbour table), no SYN scan or OS
fingerprint (no packet capture), no UPnP naming yet (that needs Apple's multicast
entitlement), and no scanning in the background.

## Building

Xcode 26 or later, iPadOS 26. `Zhen.xcodeproj` is committed; open it and run the `Zhen`
scheme on an iPad or an iPad simulator. Choose your own team under Signing & Capabilities
to run on a device, and do not commit that change.

```bash
bundle config set --local path vendor/bundle && bundle install
bundle exec fastlane unit    # unit tests on an iPad simulator
bundle exec fastlane ui      # UI tests; they drive the simulator
```

`project.yml` is the source of the project; `Scripts/generate-project.sh` regenerates
`Zhen.xcodeproj` from it with XcodeGen.

**Read `SECURITY.md` before pointing this at a network you do not run.**

## Licence

Apache License 2.0. See `LICENSE` and `NOTICE`.
