from pathlib import Path

import pytest

PAGES = ["index.html", "intro/godot.html"]


@pytest.mark.parametrize("name", PAGES)
def test_no_sphinx_branding(site, name):
    text = (site / name).read_text(encoding="utf-8")
    assert "Powered by" not in text
    assert "sphinx-doc.org" not in text
    assert "alabaster" not in text.lower()
    assert "furo" not in text.lower()


@pytest.mark.parametrize("name", PAGES)
def test_no_source_links(page, name):
    html = page(name)
    assert not html.select('a[href*="_sources"]')
    assert html.select_one("div.related") is None
    assert html.select_one("div.sphinxsidebar") is None


def test_sources_not_copied(site):
    sources = site / "_sources"
    assert not sources.exists() or not any(sources.iterdir())


def test_theme_styles_are_published(site):
    css = site / "_static" / "godot.css"
    assert css.exists()
    assert (site / "_static" / "basic.css").exists()
    assert (site / "_static" / "godot.js").exists()
    assert '@import url("basic.css")' in css.read_text(encoding="utf-8")


def test_theme_classes_do_not_clash_with_basic_css(site):
    import re

    from conftest import THEME

    basic = (site / "_static" / "basic.css").read_text(encoding="utf-8")
    basic_classes = set(re.findall(r"\.([A-Za-z_][\w-]*)", basic))
    layout = (THEME / "layout.html").read_text(encoding="utf-8")
    theme_classes = {c for attr in re.findall(r'class="([^"]+)"', layout) for c in attr.split()}
    assert theme_classes - {"body"}
    assert (theme_classes - {"body"}) & basic_classes == set()
    assert all(c.startswith("site") for c in theme_classes - {"body"})


def test_screenshots_are_numbered_and_used():
    import re

    from conftest import SOURCE

    suffixes = {".png", ".jpg", ".jpeg", ".webp"}
    for rst in SOURCE.rglob("*.rst"):
        folder = rst.with_suffix("")
        if not folder.is_dir():
            continue
        images = sorted(p for p in folder.iterdir() if p.suffix.lower() in suffixes)
        if not images:
            continue
        numbers = sorted(int(p.stem) for p in images if p.stem.isdigit())
        assert len(numbers) == len(images), f"{folder}: screenshot names must be numbers"
        assert numbers == list(range(1, len(numbers) + 1)), f"{folder}: numbers must be consecutive starting from 1"
        used = set(re.findall(r"^\s*\.\. screenshot:: (\d+)", rst.read_text(encoding="utf-8"), re.M))
        unused = {str(n) for n in numbers} - used
        assert not unused, f"{folder}: unused screenshots {sorted(unused)}"


def test_theme_script_has_cache_buster(page):
    scripts = [tag["src"] for tag in page("index.html").select("script[src]")]
    theme = [src for src in scripts if "godot.js" in src]
    assert len(theme) == 1
    assert "?v=" in theme[0]


def code_files():
    import subprocess

    from conftest import ROOT

    listed = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split()
    suffixes = {".py", ".gd", ".js", ".css", ".html", ".toml"}
    return [
        ROOT / name
        for name in listed
        if (Path(name).suffix in suffixes or Path(name).name == "Makefile")
        and not name.startswith((".idea/", "source/_static/godot/"))
        and (ROOT / name).is_file()
    ]


def strip_strings(text: str) -> str:
    import re

    return re.sub(r'"(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\'|`(?:\\.|[^`\\])*`', '""', text)


@pytest.mark.parametrize("path", code_files(), ids=lambda p: p.name)
def test_code_has_no_comments(path):
    import io
    import re
    import tokenize

    text = path.read_text(encoding="utf-8")
    if path.suffix == ".py":
        tokens = tokenize.generate_tokens(io.StringIO(text).readline)
        assert not [t.string for t in tokens if t.type == tokenize.COMMENT]
    elif path.suffix in {".gd", ".toml"} or path.name == "Makefile":
        assert not re.search(r"(?m)#", strip_strings(text))
    elif path.suffix == ".js":
        assert not re.search(r"//|/\*", strip_strings(text))
    elif path.suffix == ".css":
        assert "/*" not in text
    elif path.suffix == ".html":
        assert "<!--" not in text and "{#" not in text
