#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Construction du paquet..."
bash "$SCRIPT_DIR/packaging/build-deb.sh"

DEB="$SCRIPT_DIR/docreader_1.0.0.deb"
cp "$DEB" /tmp/docreader.deb

echo "Installation..."
sudo apt install -y /tmp/docreader.deb

rm /tmp/docreader.deb
