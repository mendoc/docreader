#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION="$(grep '^Version:' "$SCRIPT_DIR/DEBIAN/control" | awk '{print $2}')"
PKG="docreader_${VERSION}"

cd "$ROOT_DIR"

echo "Création de l'archive source ${PKG}.orig.tar.gz..."
tar --exclude='.git'      \
    --exclude='*.deb'     \
    --exclude='__pycache__' \
    -czf "../${PKG}.orig.tar.gz" .

echo "Construction du paquet source..."
debuild -S -sa -k C28C5740C72F90B8

echo "Upload vers ppa:dimitriongoua/docreader..."
dput ppa:dimitriongoua/docreader "../${PKG}-1_source.changes"

echo ""
echo "✅ Upload terminé. Launchpad va compiler et publier le paquet."
echo "   Suivi : https://launchpad.net/~dimitriongoua/+archive/ubuntu/docreader"
