#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_binary=$(mktemp -d)
trap 'rm -rf "$test_binary"' EXIT
swiftc OpenParsec/KeypadModel.swift Tests/main.swift -o "$test_binary/keypad-tests"
"$test_binary/keypad-tests"
