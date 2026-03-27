#!/usr/bin/env bash
set -e

echo "Désinstallation de DocReader..."

# 1. Supprimer le script principal
if [ -f /usr/local/bin/docreader ]; then
    sudo rm /usr/local/bin/docreader
    echo "  Supprimé : /usr/local/bin/docreader"
fi

# 2. Supprimer le fichier .desktop
DESKTOP_FILE="$HOME/.local/share/applications/docreader.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    rm "$DESKTOP_FILE"
    echo "  Supprimé : $DESKTOP_FILE"
fi

# 3. Mettre à jour le cache des applications desktop
update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true

# 4. Proposer la suppression du cache et de la configuration
echo ""
read -r -p "Supprimer le cache et la configuration (~/.cache/docreader, ~/.config/docreader) ? [o/N] " confirm
if [[ "$confirm" =~ ^[oOyY]$ ]]; then
    rm -rf "$HOME/.cache/docreader"
    rm -rf "$HOME/.config/docreader"
    echo "  Cache et configuration supprimés."
else
    echo "  Cache et configuration conservés."
fi

echo ""
echo "✅ DocReader désinstallé."
