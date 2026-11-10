#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${NIRI_MINIMAP_REPO:-https://github.com/caulifluoride/minimap.git}"
PLUGIN_ID="niriMinimap"
PLUGIN_NAME="Niri Minimap"

die() {
    echo "error: $*" >&2
    exit 1
}

command -v git >/dev/null 2>&1 || die "git is required"
command -v dms >/dev/null 2>&1 || die "dms is required (https://github.com/AvengeMedia/DankMaterialShell)"

# DMS v2+ uses ~/.config/dms; releases before the rename used ~/.config/DankMaterialShell.
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
if [[ -d "$config_home/dms" || ! -d "$config_home/DankMaterialShell" ]]; then
    plugins_dir="$config_home/dms/plugins"
else
    plugins_dir="$config_home/DankMaterialShell/plugins"
fi

target="$plugins_dir/$PLUGIN_ID"

mkdir -p "$plugins_dir"

if [[ -L "$target" ]]; then
    echo "$PLUGIN_NAME is already linked: $target -> $(readlink -f "$target")"
elif [[ -d "$target/.git" ]]; then
    echo "Updating $PLUGIN_NAME in $target"
    git -C "$target" pull --ff-only
elif [[ -e "$target" ]]; then
    die "$target already exists and is not a git checkout; remove it and re-run"
else
    echo "Installing $PLUGIN_NAME to $target"
    git clone --depth 1 "$REPO_URL" "$target"
fi

dms ipc call plugin-scan scan >/dev/null 2>&1 || true
dms ipc call plugins enable "$PLUGIN_ID" >/dev/null 2>&1 || true

echo
echo "$PLUGIN_NAME installed."
echo "Next: add it to your bar in Settings -> DankBar (or restart with 'dms restart')."
