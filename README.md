# DocReader

Application légère pour Ubuntu 24.04 GNOME qui permet d'ouvrir les fichiers `.doc` et `.docx` par double-clic. Le fichier est converti en PDF via LibreOffice, mis en cache, puis affiché dans le lecteur PDF par défaut du système.

## Fonctionnement

```
Double-clic sur .docx
  → Calcul du hash SHA-256 du contenu
  → Cache trouvé ?  Oui → Ouverture directe du PDF (instantané)
                    Non → Conversion LibreOffice + mise en cache → Ouverture
```

Le cache est basé sur le **contenu** du fichier : renommer ou déplacer un fichier ne déclenche pas de nouvelle conversion. Modifier son contenu, si.

## Prérequis

```bash
sudo apt install libreoffice zenity
```

| Outil | Rôle | Obligatoire |
|---|---|---|
| `libreoffice` | Conversion DOCX → PDF | Oui |
| `zenity` | Fenêtre de progression | Non (dégradation silencieuse) |

## Installation

```bash
git clone https://github.com/mendoc/docreader.git
cd docreader
bash install.sh
```

## Désinstallation

```bash
bash uninstall.sh
```

## Cache

Les PDFs convertis sont stockés dans `~/.cache/docreader/` sous la forme `<nom>_<hash>.pdf`.

Pour vider le cache :

```bash
docreader clear
```

## Compatibilité

Ubuntu 24.04 LTS — GNOME
