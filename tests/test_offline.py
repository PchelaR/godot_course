import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "deploy"))

from compress import compress


def precached(site) -> list[str]:
    script = (site / "sw.js").read_text(encoding="utf-8")
    match = re.search(r"const PRECACHE = (\[.*?\]);", script, re.S)
    assert match, "precache list not found in sw.js"
    return json.loads(match.group(1))


def test_service_worker_precaches_pages_but_not_engine(site):
    files = precached(site)
    assert "./" in files
    assert "index.html" in files
    assert "404.html" in files
    assert "_static/godot.css" in files
    assert not any(name.startswith("_static/godot/") for name in files)
    assert not any(name.startswith(".") for name in files if name != "./")
    script = (site / "sw.js").read_text(encoding="utf-8")
    assert "__VERSION__" not in script and "__ENGINE__" not in script


def test_manifest_and_icons(site, page):
    manifest = json.loads((site / "manifest.webmanifest").read_text(encoding="utf-8"))
    assert manifest["start_url"] == "./"
    for icon in manifest["icons"]:
        assert (site / icon["src"]).is_file()
    link = page("basics/input.html").select_one('link[rel="manifest"]')
    assert link["href"] == "../manifest.webmanifest"


def test_not_found_page_resolves_from_site_root(page):
    assert page("404.html").select_one("head base")["href"] == "/"
    assert page("index.html").select_one("head base") is None


def test_compress_writes_smaller_gzip_copies(tmp_path):
    (tmp_path / "page.html").write_text("<p>hello</p>" * 500, encoding="utf-8")
    (tmp_path / "tiny.css").write_text("a{}", encoding="utf-8")
    (tmp_path / "image.png").write_bytes(b"\x89PNG" * 1000)
    compress(tmp_path)
    assert (tmp_path / "page.html.gz").stat().st_size < (tmp_path / "page.html").stat().st_size
    assert not (tmp_path / "tiny.css.gz").exists()
    assert not (tmp_path / "image.png.gz").exists()
