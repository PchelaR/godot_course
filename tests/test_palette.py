import re

import pytest

from conftest import PALETTE, SOURCE, THEME, THEMES

HEX = re.compile(r"#[0-9a-fA-F]{3,8}\b")
FUNCTIONS = re.compile(r"\b(rgba?|hsla?|hwb|lab|lch|oklab|oklch|color)\(")
ROOT = re.compile(r'(?m)^:root(\[data-theme="(\w+)"\])?\s*\{([^}]*)\}')


def theme_css() -> str:
    return (THEME / "static" / "godot.css").read_text(encoding="utf-8")


def root_blocks() -> dict[str, set[str]]:
    blocks: dict[str, set[str]] = {}
    for match in ROOT.finditer(theme_css()):
        colors = {c.lower() for c in HEX.findall(match.group(3))}
        if colors:
            blocks[match.group(2) or "dark"] = colors
    return blocks


@pytest.mark.parametrize("name", sorted(THEMES))
def test_theme_has_at_most_six_colors(name):
    assert 4 <= len(THEMES[name]) <= 6


@pytest.mark.parametrize("name", sorted(THEMES))
def test_theme_css_uses_only_its_palette(name):
    assert root_blocks()[name] == THEMES[name]


def test_dark_theme_is_default():
    match = re.search(r"(?m)^:root\s*\{([^}]*)\}", theme_css())
    assert "color-scheme: dark" in match.group(1)


def test_theme_css_defines_colors_only_in_root():
    rest = ROOT.sub("", theme_css())
    assert HEX.findall(rest) == []
    assert FUNCTIONS.findall(rest) == []


def test_pygments_style_has_no_colors():
    import sys

    sys.path.insert(0, str(SOURCE / "_ext"))
    from godot_pygments import GodotStyle

    values = [
        GodotStyle.background_color,
        GodotStyle.highlight_color,
        GodotStyle.line_number_color,
        GodotStyle.line_number_background_color,
        GodotStyle.line_number_special_color,
        GodotStyle.line_number_special_background_color,
        *GodotStyle.styles.values(),
    ]
    assert not any(HEX.search(value) for value in values)


def test_generated_pygments_css_uses_only_palette(site):
    text = (site / "_static" / "pygments.css").read_text(encoding="utf-8")
    found = {c.lower() for c in HEX.findall(text)}
    assert found <= PALETTE
