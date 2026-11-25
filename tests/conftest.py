from pathlib import Path

import pytest
from bs4 import BeautifulSoup
from sphinx.cmd.build import build_main

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "source"
THEME = SOURCE / "_themes" / "godot"

THEMES = {
    "dark": {"#1c1814", "#27211b", "#efe2cc", "#a08f7c", "#ee6a42", "#b39bd1"},
    "light": {"#f4e4c9", "#fdf4e3", "#2b211c", "#7d6a5a", "#e8552f", "#c8a6dc"},
}
PALETTE = THEMES["dark"] | THEMES["light"]


@pytest.fixture(scope="session")
def site(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("html")
    code = build_main(["-b", "html", "-E", "-W", "--keep-going", "-n", "-q", str(SOURCE), str(out)])
    assert code == 0, "the build finished with errors or warnings"
    return out


@pytest.fixture(scope="session")
def page(site):
    def load(name: str) -> BeautifulSoup:
        return BeautifulSoup((site / name).read_text(encoding="utf-8"), "html.parser")

    return load
