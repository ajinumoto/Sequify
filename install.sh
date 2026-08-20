#!/usr/bin/env bash
set -e

SKILL_NAME="sequify"
GLOBAL_TARGET_DIR="$HOME/.gemini/config/skills/$SKILL_NAME"
REPO_URL="https://github.com/ajinumoto/Sequify.git"

print_banner() {
    echo "=========================================================="
    echo "       📊 Sequify: Sequence Diagram Skill Installer       "
    echo "=========================================================="
}

install_global() {
    echo "📦 Installing Sequify Skill to: $GLOBAL_TARGET_DIR"
    mkdir -p "$GLOBAL_TARGET_DIR"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [ -d "$SCRIPT_DIR/sequify" ]; then
        # Installed from local cloned repository
        cp -R "$SCRIPT_DIR/sequify/"* "$GLOBAL_TARGET_DIR/"
    else
        # Installed via curl | bash
        TMP_DIR=$(mktemp -d)
        echo "⬇️ Downloading repository..."
        git clone --depth 1 "$REPO_URL" "$TMP_DIR"
        cp -R "$TMP_DIR/sequify/"* "$GLOBAL_TARGET_DIR/"
        rm -rf "$TMP_DIR"
    fi

    echo "🔨 Compiling native sequify-cli binary..."
    if command -v swiftc >/dev/null 2>&1; then
        swiftc -O "$GLOBAL_TARGET_DIR/scripts/render_diagram.swift" -o "$GLOBAL_TARGET_DIR/scripts/sequify-cli"
        chmod +x "$GLOBAL_TARGET_DIR/scripts/sequify-cli"
        echo "✅ Native binary compiled successfully!"
    else
        echo "⚠️ Warning: 'swiftc' compiler not found. Please install Xcode Command Line Tools via: xcode-select --install"
    fi

    echo ""
    echo "🎉 Success! Sequify is now active globally across all Antigravity workspaces."
    echo "👉 Open any project in Antigravity and type '/sequify', '/sequence', or '/diagram'!"
}

install_workspace() {
    TARGET_WORKSPACE="$1"
    if [ -z "$TARGET_WORKSPACE" ]; then
        TARGET_WORKSPACE="$(pwd)"
    fi
    WS_TARGET_DIR="$TARGET_WORKSPACE/.agents/skills/$SKILL_NAME"
    echo "📦 Installing Sequify into workspace: $WS_TARGET_DIR"
    mkdir -p "$WS_TARGET_DIR"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -d "$SCRIPT_DIR/sequify" ]; then
        cp -R "$SCRIPT_DIR/sequify/"* "$WS_TARGET_DIR/"
    else
        TMP_DIR=$(mktemp -d)
        git clone --depth 1 "$REPO_URL" "$TMP_DIR"
        cp -R "$TMP_DIR/sequify/"* "$WS_TARGET_DIR/"
        rm -rf "$TMP_DIR"
    fi

    if command -v swiftc >/dev/null 2>&1; then
        swiftc -O "$WS_TARGET_DIR/scripts/render_diagram.swift" -o "$WS_TARGET_DIR/scripts/sequify-cli"
        chmod +x "$WS_TARGET_DIR/scripts/sequify-cli"
    fi
    echo "✅ Installed to workspace! Commit the .agents/ folder to Git to share with your team."
}

print_banner

if [ "$1" == "--workspace" ] || [ "$1" == "-w" ]; then
    install_workspace "$2"
else
    install_global
fi
