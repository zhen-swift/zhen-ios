#!/usr/bin/env bash
#
# generate-project.sh — regenerate Zhen.xcodeproj from project.yml with XcodeGen.
#
# The project is committed so a clone builds without XcodeGen; this is for the person
# changing project.yml. Install XcodeGen with `brew install xcodegen`, or point XCODEGEN at
# a binary.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
xcodegen="${XCODEGEN:-$(command -v xcodegen || true)}"
[ -n "$xcodegen" ] || { echo "generate-project: XcodeGen not found. brew install xcodegen"; exit 2; }
"$xcodegen" generate --spec project.yml
echo "generate-project: wrote Zhen.xcodeproj"
