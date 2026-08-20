#!/usr/bin/env bash
set -e

SKILL_NAME="sequify"
GLOBAL_TARGET_DIR="$HOME/.gemini/config/skills/$SKILL_NAME"

if [ -d "$GLOBAL_TARGET_DIR" ]; then
    rm -rf "$GLOBAL_TARGET_DIR"
    echo "🗑️ Sequify skill successfully uninstalled from: $GLOBAL_TARGET_DIR"
else
    echo "ℹ️ Skill was not found at $GLOBAL_TARGET_DIR"
fi
