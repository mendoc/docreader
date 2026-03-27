#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installation de DocReader..."

# 1. Vérifier Python 3
if ! command -v python3 &>/dev/null; then
    echo "Erreur : python3 est requis mais introuvable." >&2
    exit 1
fi

# 2. Vérifier LibreOffice (avertissement seulement)
if ! command -v libreoffice &>/dev/null; then
    echo "Avertissement : LibreOffice n'est pas installé."
    echo "  → sudo apt install libreoffice"
fi

# 3. Vérifier zenity (avertissement seulement)
if ! command -v zenity &>/dev/null; then
    echo "Avertissement : zenity n'est pas installé (loader désactivé)."
    echo "  → sudo apt install zenity"
fi

# 4. Copier le script principal
sudo cp "$SCRIPT_DIR/docreader.py" /usr/local/bin/docreader

# 5. Rendre exécutable
sudo chmod +x /usr/local/bin/docreader

# 6. Copier le fichier .desktop
mkdir -p "$HOME/.local/share/applications"
cp "$SCRIPT_DIR/docreader.desktop" "$HOME/.local/share/applications/docreader.desktop"

# 7. Enregistrer l'application auprès de xdg-mime
xdg-mime install --novendor "$HOME/.local/share/applications/docreader.desktop"

# 8. Définir DocReader comme handler par défaut
xdg-mime default docreader.desktop \
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
xdg-mime default docreader.desktop \
    application/msword

# 9. Mettre à jour le cache des applications desktop
update-desktop-database "$HOME/.local/share/applications/"

echo ""
echo "✅ DocReader installé avec succès."
echo ""
echo "Vérification :"
echo "  xdg-mime query default application/vnd.openxmlformats-officedocument.wordprocessingml.document"
echo ""
echo "Dépendances requises :"
echo "  sudo apt install libreoffice zenity"
