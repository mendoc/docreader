#!/usr/bin/env python3
"""DocReader — Ouvre les fichiers .doc/.docx via conversion PDF avec cache SHA-256."""

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

VERSION    = "1.4.0"
CONFIG_DIR = Path.home() / ".config" / "docreader"
CACHE_DIR  = Path.home() / ".cache"  / "docreader"
CHECKSUMS  = CONFIG_DIR / "checksums.json"

SUPPORTED_EXTENSIONS = {".doc", ".docx"}


def show_error(message: str) -> None:
    if shutil.which("zenity"):
        subprocess.run(
            ["zenity", "--error", "--title", "DocReader", "--text", message],
            check=False,
        )
    else:
        print(f"Erreur : {message}", file=sys.stderr)


def sha256_of_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def load_checksums() -> dict:
    if CHECKSUMS.exists():
        try:
            return json.loads(CHECKSUMS.read_text())
        except (json.JSONDecodeError, OSError):
            return {}
    return {}


def save_checksums(data: dict) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    CHECKSUMS.write_text(json.dumps(data, indent=2))


def convert_to_pdf(source: Path, file_hash: str) -> Path:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    if not shutil.which("libreoffice"):
        show_error(
            "LibreOffice est requis mais n'est pas installé.\n"
            "Installer avec : sudo apt install libreoffice"
        )
        sys.exit(1)

    tmp_dir = tempfile.mkdtemp()
    zenity_proc = None

    try:
        tmp_source = Path(tmp_dir) / source.name

        shutil.copy2(source, tmp_source)

        if shutil.which("zenity"):
            zenity_proc = subprocess.Popen(
                [
                    "zenity", "--progress", "--pulsate", "--auto-close",
                    "--title", "DocReader",
                    "--text", f"Conversion : {source.name}…",
                    "--no-cancel",
                ],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

        result = subprocess.run(
            [
                "libreoffice", "--headless", "--convert-to", "pdf",
                "--outdir", tmp_dir, str(tmp_source),
            ],
            capture_output=True,
            text=True,
        )

        if zenity_proc is not None:
            zenity_proc.terminate()
            zenity_proc.wait()

        if result.returncode != 0:
            show_error(
                f"Échec de la conversion.\n\n{result.stderr.strip()}"
            )
            sys.exit(1)

        tmp_pdf = Path(tmp_dir) / (tmp_source.stem + ".pdf")
        if not tmp_pdf.exists():
            show_error("LibreOffice n'a pas produit de fichier PDF.")
            sys.exit(1)

        dest_pdf = CACHE_DIR / f"{source.stem}_{file_hash[:8]}.pdf"
        shutil.move(str(tmp_pdf), dest_pdf)
        return dest_pdf

    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def show_about() -> None:
    markup = (
        f'<span size="x-large" weight="bold">DocReader</span>'
        f'  <span size="large" foreground="gray">v{VERSION}</span>\n'
        '<span foreground="gray">─────────────────────────────────────</span>\n\n'
        'Ouvre les fichiers <tt>.doc</tt> et <tt>.docx</tt> par double-clic\n'
        'en les convertissant en PDF via LibreOffice.\n\n'
        '<b>Utilisation normale</b>\n'
        '  Double-cliquez sur un fichier <tt>.doc</tt> ou <tt>.docx</tt>.\n\n'
        '<b>Ligne de commande</b>\n'
        '  <tt>docreader &lt;fichier.docx&gt;</tt>  — ouvrir un fichier\n'
        '  <tt>docreader clear</tt>           — vider le cache\n\n'
        '<b>Auteur</b>\n'
        '  Dimitri Ongoua\n'
        '  <a href="https://github.com/mendoc">github.com/mendoc</a>'
    )
    text_fallback = (
        f"DocReader v{VERSION}\n\n"
        "Ouvre les fichiers .doc et .docx par double-clic\n"
        "en les convertissant en PDF via LibreOffice.\n\n"
        "Usage : docreader <fichier.docx>\n"
        "        docreader clear\n\n"
        "Auteur : Dimitri Ongoua — https://github.com/mendoc"
    )
    try:
        import gi
        gi.require_version("Gtk", "3.0")
        from gi.repository import Gtk

        def on_activate(app):
            win = Gtk.ApplicationWindow(application=app)
            win.set_title("DocReader")
            win.set_resizable(False)
            win.set_default_size(420, -1)
            win.set_position(Gtk.WindowPosition.CENTER)

            label = Gtk.Label()
            label.set_markup(markup)
            label.set_margin_top(28)
            label.set_margin_bottom(28)
            label.set_margin_start(28)
            label.set_margin_end(28)
            label.set_halign(Gtk.Align.START)

            win.add(label)
            win.show_all()

        app = Gtk.Application(application_id="com.github.mendoc.docreader")
        app.connect("activate", on_activate)
        app.run(None)

    except Exception:
        print(text_fallback)


def clear_cache() -> None:
    removed = 0
    if CACHE_DIR.exists():
        shutil.rmtree(CACHE_DIR)
        removed += 1
    if CONFIG_DIR.exists():
        shutil.rmtree(CONFIG_DIR)
        removed += 1
    if removed:
        print("Cache vidé.")
    else:
        print("Le cache est déjà vide.")


def main() -> None:
    if len(sys.argv) < 2:
        show_about()
        sys.exit(0)

    if sys.argv[1] == "clear":
        clear_cache()
        sys.exit(0)

    source = Path(sys.argv[1])

    if not source.exists():
        show_error(f"Fichier introuvable :\n{source}")
        sys.exit(1)

    if source.suffix.lower() not in SUPPORTED_EXTENSIONS:
        show_error(
            f"Extension non supportée : {source.suffix}\n"
            "DocReader accepte uniquement les fichiers .doc et .docx."
        )
        sys.exit(1)

    file_hash = sha256_of_file(source)
    checksums = load_checksums()

    cached_pdf_name = checksums.get(file_hash)
    if cached_pdf_name:
        cached_pdf = CACHE_DIR / cached_pdf_name
        if cached_pdf.exists():
            subprocess.run(["xdg-open", str(cached_pdf)], check=False)
            sys.exit(0)

    pdf_path = convert_to_pdf(source, file_hash)

    checksums[file_hash] = f"{source.stem}_{file_hash[:8]}.pdf"
    save_checksums(checksums)

    subprocess.run(["xdg-open", str(pdf_path)], check=False)


if __name__ == "__main__":
    main()
