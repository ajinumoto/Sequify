#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_FILE="$SCRIPT_DIR/render_diagram.swift"
BIN_FILE="$SCRIPT_DIR/sequify-cli"

echo "🔨 Compiling sequify-cli with swiftc..."
swiftc -O "$SWIFT_FILE" -o "$BIN_FILE"
chmod +x "$BIN_FILE"
echo "✅ Compilation successful: $BIN_FILE"
