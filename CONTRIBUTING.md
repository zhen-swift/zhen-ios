# Contributing

## Setting up

- macOS 26 and Xcode 26 or later, with an iPadOS simulator runtime.
- Ruby with Bundler, for fastlane: `bundle config set --local path vendor/bundle &&
  bundle install`.
- **No Apple Developer account is needed to build and test.** The fastlane lanes run on a
  simulator with ad-hoc signing. Running on an iPad uses automatic signing: select your
  own team on the Zhen target, and do not commit that change.
- The engine is [zhen-core](https://github.com/zhen-swift/zhen-core), resolved by version
  from GitHub. Nothing needs to be checked out beside this repository.
- `Zhen.xcodeproj` is generated. Change `project.yml`, then run
  `Scripts/generate-project.sh` (it needs XcodeGen) and commit both.

## Changes

1. Read `AGENTS.md`, the house rules. They win over every other document here.
2. One change per pull request. A change that needs a new zhen-core is two pull
   requests: zhen-core first, then this repository adopting the release.
3. `bundle exec fastlane unit` passes locally before you push; CI runs the same tests.
   UI tests (`bundle exec fastlane ui`) drive the simulator; run them before a change to
   the screens.
4. A behaviour change adds a line under **Unreleased** in `CHANGELOG.md`.
5. Nothing from a real network is committed. The fixture network is invented.

Conduct: `CODE_OF_CONDUCT.md`. Security reports: `SECURITY.md`.

## Licence

By contributing you agree your contribution is licensed under the Apache License 2.0,
the same as the rest of the work, including the patent grant in section 3.
