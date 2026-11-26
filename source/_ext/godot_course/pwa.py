import hashlib
import json
from pathlib import Path

from sphinx.application import Sphinx

TEMPLATE = Path(__file__).with_name("sw.js")
SKIPPED = {".buildinfo", "sw.js", "objects.inv"}


def digest(paths: list[Path]) -> str:
    hasher = hashlib.sha256()
    for path in paths:
        hasher.update(path.name.encode())
        hasher.update(path.read_bytes())
    return hasher.hexdigest()[:12]


def site_files(outdir: Path) -> tuple[list[Path], list[Path]]:
    pages: list[Path] = []
    demos: list[Path] = []
    for path in sorted(outdir.rglob("*")):
        relative = path.relative_to(outdir)
        if not path.is_file() or relative.parts[0].startswith(".") or path.name in SKIPPED:
            continue
        if path.suffix == ".gz":
            continue
        if relative.parts[:2] == ("_static", "godot"):
            demos.append(path)
        else:
            pages.append(path)
    return pages, demos


def manifest(app: Sphinx) -> dict:
    return {
        "name": app.config.html_title,
        "short_name": "Godot 0",
        "lang": app.config.language,
        "start_url": "./",
        "scope": "./",
        "display": "standalone",
        "background_color": "#1c1814",
        "theme_color": "#1c1814",
        "icons": [
            {"src": "_static/icon_192x192.png", "sizes": "192x192", "type": "image/png"},
            {"src": "_static/icon_512x512.png", "sizes": "512x512", "type": "image/png"},
        ],
    }


def write_offline_files(app: Sphinx, exception: Exception | None) -> None:
    if exception is not None or app.builder.format != "html":
        return
    outdir = Path(app.outdir)
    (outdir / "manifest.webmanifest").write_text(
        json.dumps(manifest(app), ensure_ascii=False, indent=2), encoding="utf-8"
    )
    pages, demos = site_files(outdir)
    files = ["./"] + [path.relative_to(outdir).as_posix() for path in pages]
    script = (
        TEMPLATE.read_text(encoding="utf-8")
        .replace("__VERSION__", digest(pages))
        .replace("__ENGINE__", digest(demos))
        .replace("__FILES__", json.dumps(files, ensure_ascii=False))
    )
    (outdir / "sw.js").write_text(script, encoding="utf-8")
