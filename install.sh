#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Construction du paquet..."
bash "$SCRIPT_DIR/packaging/build-deb.sh"

VERSION="$(grep '^Version:' "$SCRIPT_DIR/packaging/DEBIAN/control" | awk '{print $2}')"
DEB="$SCRIPT_DIR/docreader_${VERSION}.deb"
cp "$DEB" /tmp/docreader.deb

echo "Installation..."
sudo apt install -y /tmp/docreader.deb

rm /tmp/docreader.deb
