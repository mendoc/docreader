# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

**DocReader** est une application desktop légère pour Ubuntu 24.04 GNOME qui permet d'ouvrir les fichiers `.doc` et `.docx` par double-clic. Elle convertit le fichier en PDF via LibreOffice, met le résultat en cache (hash SHA-256 du contenu), puis délègue l'affichage au lecteur PDF par défaut.

La spécification complète est dans `docreader-spec.md`.

## Fichiers à créer

```
docreader.py        # Script Python principal → installé dans /usr/local/bin/docreader
docreader.desktop   # Entrée GNOME → installée dans ~/.local/share/applications/
install.sh          # Installation + enregistrement MIME
uninstall.sh        # Désinstallation (avec confirmation pour le cache)
README.md           # Documentation utilisateur
```

## Installation et test manuel

```bash
# Installer
bash install.sh

# Vérifier l'association MIME
xdg-mime query default application/vnd.openxmlformats-officedocument.wordprocessingml.document
# → doit retourner : docreader.desktop

# Tester directement
/usr/local/bin/docreader /chemin/vers/test.docx

# Inspecter le cache
ls ~/.cache/docreader/
cat ~/.config/docreader/checksums.json

# Désinstaller
bash uninstall.sh
```

Pas de framework de test automatisé — les tests sont manuels selon la procédure ci-dessus.

## Architecture

### Flux d'exécution

```
Double-clic .docx → docreader.py invoqué avec chemin en argv[1]
  → Calcul SHA-256 du contenu binaire
  → Lookup dans ~/.config/docreader/checksums.json
      ├─ Hash trouvé + PDF présent → xdg-open(PDF en cache) [chemin rapide]
      └─ Sinon → copie dans tempfile.mkdtemp()
                → zenity --progress (en parallèle via Popen)
                → libreoffice --headless --convert-to pdf --outdir tmp_dir
                → kill zenity + shutil.rmtree(tmp_dir) [dans finally]
                → mv PDF → ~/.cache/docreader/<hash>.pdf
                → mise à jour checksums.json
                → xdg-open(PDF)
```

### Répertoires runtime

| Chemin | Contenu |
|---|---|
| `~/.config/docreader/checksums.json` | `{ "<sha256>": "<sha256>.pdf" }` |
| `~/.cache/docreader/<sha256>.pdf` | PDFs convertis |

### Constantes Python

```python
CONFIG_DIR = Path.home() / ".config" / "docreader"
CACHE_DIR  = Path.home() / ".cache"  / "docreader"
CHECKSUMS  = CONFIG_DIR / "checksums.json"
```

## Contraintes impératives

- **Jamais modifier le fichier source** : toujours travailler sur une copie dans `tempfile.mkdtemp()`
- **Nettoyage du répertoire temporaire dans un `try/finally`**, même en cas d'erreur LibreOffice
- **Hash calculé sur le contenu binaire**, pas sur le nom ou le chemin
- **Stdlib Python uniquement** (`hashlib`, `json`, `os`, `sys`, `subprocess`, `pathlib`, `shutil`, `tempfile`)
- **`install.sh` doit être idempotent** (relancer sans erreur)
- **`%f` dans le `.desktop`**, pas `%F` (un seul fichier à la fois)

## Dépendances système

| Outil | Obligatoire | Note |
|---|---|---|
| `libreoffice` | Oui | Vérifier avec `shutil.which()`, erreur zenity si absent |
| `xdg-open` / `xdg-mime` | Oui | Présents par défaut via `xdg-utils` |
| `zenity` | Non | Dégradation silencieuse si absent |
| `python3` | Oui | Présent par défaut sur Ubuntu 24.04 |

## Gestion d'erreurs

| Situation | Comportement |
|---|---|
| `sys.argv` vide | Usage dans stderr + exit(1) |
| Fichier introuvable | `zenity --error` + exit(1) |
| Extension non supportée (.doc/.docx insensible à la casse) | `zenity --error` + exit(1) |
| LibreOffice absent | `zenity --error` avec commande `apt install` + exit(1) |
| Échec conversion | `zenity --error` avec stderr LibreOffice + exit(1) |
| zenity absent | Continuer sans loader |
