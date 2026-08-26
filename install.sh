#!/usr/bin/env bash
# mycelium-tools installer — installs the 5 universal packages (U1-U5) into
# a virtualenv, and offers to copy the systemd --user unit templates.
#
# Designed to run on any device: a VPS, a desktop, or Termux on a phone.
# Never asks for root. Never installs into the system Python.
#
# Usage:
#   ./install.sh                 # install into ~/.venvs/mycelium-tools
#   ./install.sh /path/to/venv   # install into a specific venv path
set -euo pipefail

VENV_DIR="${1:-$HOME/.venvs/mycelium-tools}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "mycelium-tools installer"
echo "  repo: $REPO_DIR"
echo "  venv: $VENV_DIR"
echo

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found on PATH — install it first (pkg install python on Termux, apt/brew elsewhere)." >&2
  exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
  echo "-> creating venv at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

PIP="$VENV_DIR/bin/pip"
"$PIP" install -q --upgrade pip

echo "-> installing packages"
for pkg in mycelium-substrate mycelium-collector mycelium-cycle substrate-tunnel picks-client; do
  echo "   $pkg"
  "$PIP" install -q -e "$REPO_DIR/packages/$pkg"
done

echo
echo "Done. Console scripts are in: $VENV_DIR/bin"
echo "Add that to PATH, or run tools directly, e.g.:"
echo "  $VENV_DIR/bin/mycelium init"
echo "  $VENV_DIR/bin/mycelium-http"
echo

read -r -p "Install systemd --user unit templates to ~/.config/systemd/user/? [y/N] " reply
if [[ "$reply" =~ ^[Yy]$ ]]; then
  if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl not found on this device (expected on Termux/macOS) — skipping." >&2
  else
    UNIT_DIR="$HOME/.config/systemd/user"
    mkdir -p "$UNIT_DIR"
    cp "$REPO_DIR"/systemd/*.service "$REPO_DIR"/systemd/*.timer "$UNIT_DIR/"
    echo "-> copied unit templates to $UNIT_DIR"
    echo "   Each ExecStart uses 'env <tool>' — either put $VENV_DIR/bin on PATH"
    echo "   system-wide for your user, or edit each unit's ExecStart= to the full"
    echo "   $VENV_DIR/bin/<tool> path."
    echo "   Edit each unit's commented Environment= lines for your config, then:"
    echo "     systemctl --user daemon-reload"
    echo "     systemctl --user enable --now <unit>"
    echo "     loginctl enable-linger \$USER   # keep running after logout / on boot"
  fi
fi

echo
echo "See README.md for the full 'add your own device' walkthrough."
