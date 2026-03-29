#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION="$(grep '^Version:' "$SCRIPT_DIR/DEBIAN/control" | awk '{print $2}')"
PKG_NAME="docreader_${VERSION}"
BUILD_DIR="$(mktemp -d)/${PKG_NAME}"

echo "Construction du paquet docreader v${VERSION}..."

# Arborescence du paquet
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/icons/hicolor/scalable/apps"

# Fichiers DEBIAN
cp "$SCRIPT_DIR/DEBIAN/control"  "$BUILD_DIR/DEBIAN/control"
cp "$SCRIPT_DIR/DEBIAN/postinst" "$BUILD_DIR/DEBIAN/postinst"
cp "$SCRIPT_DIR/DEBIAN/prerm"    "$BUILD_DIR/DEBIAN/prerm"
cp "$SCRIPT_DIR/DEBIAN/postrm"   "$BUILD_DIR/DEBIAN/postrm"
chmod 755 "$BUILD_DIR/DEBIAN/postinst" \
          "$BUILD_DIR/DEBIAN/prerm"    \
          "$BUILD_DIR/DEBIAN/postrm"

# Script principal
cp "$ROOT_DIR/docreader.py" "$BUILD_DIR/usr/bin/docreader"
chmod 755 "$BUILD_DIR/usr/bin/docreader"

# Fichier .desktop
cp "$ROOT_DIR/docreader.desktop" "$BUILD_DIR/usr/share/applications/docreader.desktop"

# Icône
cp "$ROOT_DIR/docreader.svg" "$BUILD_DIR/usr/share/icons/hicolor/scalable/apps/docreader.svg"

# Construction
OUTPUT="${ROOT_DIR}/${PKG_NAME}.deb"
dpkg-deb --build --root-owner-group "$BUILD_DIR" "$OUTPUT"
rm -rf "$(dirname "$BUILD_DIR")"

echo ""
echo "✅ Paquet créé : ${PKG_NAME}.deb"
echo ""
echo "Installation :"
echo "  sudo apt install ./${PKG_NAME}.deb"
