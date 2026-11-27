import sys
import zipfile
from pathlib import Path

import pytest
from bs4 import BeautifulSoup
from sphinx.cmd.build import build_main

from conftest import SOURCE

sys.path.insert(0, str(SOURCE / "_ext"))

from godot_zero import archive_name, godot_docs_url, resolve_docname

BASE = "https://docs.godotengine.org/en/4.7/classes/"


@pytest.mark.parametrize(
    ("target", "signal", "expected"),
    [
        ("Node", False, BASE + "class_node.html"),
        ("CharacterBody2D", False, BASE + "class_characterbody2d.html"),
        ("@GlobalScope", False, BASE + "class_@globalscope.html"),
        (
            "@GlobalScope.is_equal_approx()",
            False,
            BASE + "class_@globalscope.html#class-globalscope-method-is-equal-approx",
        ),
        ("Node2D.position", False, BASE + "class_node2d.html#class-node2d-property-position"),
        ("Node2D.look_at()", False, BASE + "class_node2d.html#class-node2d-method-look-at"),
        ("Timer.timeout", True, BASE + "class_timer.html#class-timer-signal-timeout"),
    ],
)
def test_docs_url(target, signal, expected):
    assert godot_docs_url(target, "4.7", signal) == expected


@pytest.mark.parametrize(
    ("target", "signal"),
    [
        ("node", False),
        ("Node2D.", False),
        ("Node2D.look at()", False),
        ("Timer", True),
        ("Timer.start()", True),
    ],
)
def test_docs_url_rejects_invalid(target, signal):
    assert godot_docs_url(target, "4.7", signal) is None


def test_archive_name():
    assert archive_name("checkpoints/2.01") == "checkpoints-2.01.zip"
    assert archive_name("examples/") == "examples.zip"


CONF = """
import sys
sys.path.insert(0, {ext!r})
extensions = ["godot_zero"]
godot_docs_version = "4.7"
godot_projects_dir = "projects"
"""

INDEX = """
Тест
====

:godot:`Node2D.look_at()` :godot-signal:`Timer.timeout` :godot:`узел <Node>`

:project:`demo`

.. godot-demo:: sample
   :title: Пример

.. toctree::

   sub/page
"""

SUBPAGE = """
Вложенная
=========

:project:`Архив <demo>`

.. godot-demo:: sample
   :ratio: 4 / 3
"""


def make_project(root: Path, index: str = INDEX, demo: bool = True, project: bool = True) -> Path:
    src = root / "src"
    (src / "sub").mkdir(parents=True)
    (src / "conf.py").write_text(CONF.format(ext=str(SOURCE / "_ext")), encoding="utf-8")
    (src / "index.rst").write_text(index, encoding="utf-8")
    (src / "sub" / "page.rst").write_text(SUBPAGE, encoding="utf-8")
    scenes = src / "projects" / "examples"
    scenes.mkdir(parents=True)
    (scenes / "sample.tscn").write_text("[gd_scene format=3]\n", encoding="utf-8")
    if demo:
        (src / "_static" / "godot").mkdir(parents=True)
        (src / "_static" / "godot" / "index.html").write_text("<html></html>", encoding="utf-8")
    if project:
        proj = src / "projects" / "demo"
        (proj / ".godot").mkdir(parents=True)
        (proj / "project.godot").write_text("config_version=5\n", encoding="utf-8")
        (proj / "main.gd").write_text("extends Node\n", encoding="utf-8")
        (proj / ".godot" / "cache.bin").write_text("x", encoding="utf-8")
    return src


def build(src: Path, out: Path) -> int:
    return build_main(["-b", "html", "-E", "-W", "-q", str(src), str(out)])


@pytest.fixture(scope="module")
def mini_site(tmp_path_factory):
    root = tmp_path_factory.mktemp("mini")
    src = make_project(root)
    out = root / "out"
    assert build(src, out) == 0
    return out


def soup(path: Path) -> BeautifulSoup:
    return BeautifulSoup(path.read_text(encoding="utf-8"), "html.parser")


def test_godot_role_renders_links(mini_site):
    links = soup(mini_site / "index.html").select("a.godot-ref")
    hrefs = [a["href"] for a in links]
    assert BASE + "class_node2d.html#class-node2d-method-look-at" in hrefs
    assert BASE + "class_timer.html#class-timer-signal-timeout" in hrefs
    assert BASE + "class_node.html" in hrefs
    texts = [a.get_text() for a in links]
    assert "узел" in texts
    assert all(a.select_one("code") is not None for a in links)


def test_project_role_links_relative(mini_site):
    root_link = soup(mini_site / "index.html").select_one("a.project-download")
    sub_link = soup(mini_site / "sub" / "page.html").select_one("a.project-download")
    assert root_link["href"] == "downloads/demo.zip"
    assert root_link.get_text() == "demo.zip"
    assert sub_link["href"] == "../downloads/demo.zip"
    assert sub_link.get_text() == "Архив"


def test_project_archive_contents(mini_site):
    archive = mini_site / "downloads" / "demo.zip"
    assert archive.is_file()
    names = zipfile.ZipFile(archive).namelist()
    assert "demo/project.godot" in names
    assert "demo/main.gd" in names
    assert not any(".godot/" in name for name in names)


def test_demo_placeholder(mini_site):
    root_demo = soup(mini_site / "index.html").select_one("div.godot-demo")
    sub_demo = soup(mini_site / "sub" / "page.html").select_one("div.godot-demo")
    assert root_demo["data-src"] == "_static/godot/index.html?scene=sample"
    assert root_demo["data-title"] == "Пример"
    assert root_demo.select_one("button.godot-demo-start") is not None
    assert root_demo.select_one("iframe") is None
    assert sub_demo["data-src"] == "../_static/godot/index.html?scene=sample"
    assert "4 / 3" in sub_demo.select_one(".godot-demo-screen")["style"]
    assert root_demo.select_one("p.godot-demo-bar").get_text() == "Пример"


def test_missing_demo_fails_strict_build(tmp_path):
    src = make_project(tmp_path, demo=False)
    assert build(src, tmp_path / "out") != 0


def test_missing_demo_scene_fails_strict_build(tmp_path):
    src = make_project(tmp_path, index=INDEX.replace(".. godot-demo:: sample", ".. godot-demo:: missing"))
    assert build(src, tmp_path / "out") != 0


def test_missing_project_fails_strict_build(tmp_path):
    src = make_project(tmp_path, project=False)
    assert build(src, tmp_path / "out") != 0


def test_invalid_godot_role_fails_strict_build(tmp_path):
    src = make_project(tmp_path, index=INDEX.replace(":godot:`Node2D.look_at()`", ":godot:`node2d`"))
    assert build(src, tmp_path / "out") != 0


def test_incremental_build_refreshes_sidebar(tmp_path):
    src = tmp_path / "src"
    src.mkdir()
    (src / "conf.py").write_text(
        CONF.format(ext=str(SOURCE / "_ext"))
        + f'html_theme = "godot"\nhtml_theme_path = [{str(SOURCE / "_themes")!r}]\n',
        encoding="utf-8",
    )
    (src / "index.rst").write_text("Главная\n=======\n\n.. toctree::\n\n   first\n", encoding="utf-8")
    (src / "first.rst").write_text("Первая\n======\n", encoding="utf-8")
    out = tmp_path / "out"
    assert build_main(["-b", "html", "-q", str(src), str(out)]) == 0

    (src / "second.rst").write_text("Вторая\n======\n", encoding="utf-8")
    (src / "index.rst").write_text("Главная\n=======\n\n.. toctree::\n\n   first\n   second\n", encoding="utf-8")
    assert build_main(["-b", "html", "-q", str(src), str(out)]) == 0

    links = [a.get_text(strip=True) for a in soup(out / "first.html").select("nav.site-nav a")]
    assert "Вторая" in links


def make_image(path: Path, size: tuple[int, int] = (120, 80), dpi: int = 72, alpha: bool = False) -> None:
    from PIL import Image, ImageDraw

    image = Image.new("RGBA" if alpha else "RGB", size, (0, 0, 0, 0) if alpha else (20, 23, 28))
    draw = ImageDraw.Draw(image)
    draw.rectangle([10, 10, size[0] - 10, size[1] // 2], fill=(91, 163, 220, 255))
    draw.text((12, size[1] // 2 + 4), "Node", fill=(213, 217, 223, 255))
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, dpi=(dpi, dpi))


@pytest.mark.parametrize("alpha", [False, True])
def test_optimized_image_is_lossless(tmp_path, alpha):
    from PIL import Image

    from godot_zero import optimize_image

    source = tmp_path / "editor-panel.png"
    make_image(source, alpha=alpha)
    target, _ = optimize_image(source, tmp_path / "cache")
    with Image.open(target) as optimized, Image.open(source) as original:
        assert optimized.format == "WEBP"
        assert optimized.size == original.size
        assert optimized.tobytes() == original.convert(optimized.mode).tobytes()


def test_optimized_image_name_is_content_hash(tmp_path):
    from godot_zero import optimize_image

    source = tmp_path / "editor-panel.png"
    make_image(source)
    first, _ = optimize_image(source, tmp_path / "cache")
    assert first.name.startswith("editor-panel.") and first.suffix == ".webp"
    make_image(source, size=(140, 80))
    second, _ = optimize_image(source, tmp_path / "cache")
    assert first.name != second.name


def test_hidpi_image_is_displayed_at_half_width(tmp_path):
    from godot_zero import optimize_image

    regular = tmp_path / "regular.png"
    retina = tmp_path / "retina.png"
    make_image(regular, size=(400, 200), dpi=72)
    make_image(retina, size=(400, 200), dpi=144)
    assert optimize_image(regular, tmp_path / "cache")[1] == 400
    assert optimize_image(retina, tmp_path / "cache")[1] == 200


IMAGES_CONF = """
import sys
sys.path.insert(0, {ext!r})
extensions = ["godot_zero"]
"""


def build_screenshot_page(tmp_path: Path, body: str) -> tuple[int, Path]:
    src = tmp_path / "src"
    (src / "guide").mkdir(parents=True)
    (src / "conf.py").write_text(IMAGES_CONF.format(ext=str(SOURCE / "_ext")), encoding="utf-8")
    (src / "index.rst").write_text("Тест\n====\n\n.. toctree::\n\n   guide/page\n", encoding="utf-8")
    (src / "guide" / "page.rst").write_text("Статья\n======\n\n" + body, encoding="utf-8")
    make_image(src / "guide" / "page" / "1.png", size=(400, 200), dpi=144)
    out = tmp_path / "build" / "html"
    return build_main(["-b", "html", "-E", "-W", "-q", str(src), str(out)]), out


def test_screenshot_directive(tmp_path):
    code, out = build_screenshot_page(tmp_path, ".. screenshot:: 1\n\n   Окно **Attach Node Script**.\n")
    assert code == 0
    html = soup(out / "guide" / "page.html")
    img = html.select_one("figure.screenshot img")
    assert img["src"].startswith("../_images/1.")
    assert img["src"].endswith(".webp")
    assert (out / "guide" / img["src"]).resolve().is_file()
    assert "200px" in img.get("style", "") + img.get("width", "")
    assert img["alt"] == "Окно Attach Node Script."
    assert html.select_one("figure.screenshot figcaption strong").get_text() == "Attach Node Script"
    assert [p.suffix for p in (out / "_images").iterdir()] == [".webp"]


@pytest.mark.parametrize("name", ["2", "0", "01", "step-1", "attach-script"])
def test_screenshot_invalid_or_missing_fails_strict_build(tmp_path, name):
    code, _ = build_screenshot_page(tmp_path, f".. screenshot:: {name}\n")
    assert code != 0


def test_example_directive(tmp_path):
    src = tmp_path / "src"
    example = src / "projects" / "examples" / "demo"
    example.mkdir(parents=True)
    (example / "hello.gd").write_text('extends Node\n\n\nfunc _ready() -> void:\n\tprint("Привет")\n', encoding="utf-8")
    (example / "hello.out").write_text("Привет\n", encoding="utf-8")
    (example / "data.gd").write_text("class_name Data\nextends RefCounted\n", encoding="utf-8")
    (src / "conf.py").write_text(CONF.format(ext=str(SOURCE / "_ext")), encoding="utf-8")
    (src / "index.rst").write_text(
        "Тест\n====\n\n.. example:: demo/hello\n\n.. example:: demo/data\n", encoding="utf-8"
    )
    out = tmp_path / "out"
    assert build(src, out) == 0
    examples = soup(out / "index.html").select("div.example")
    assert len(examples) == 2
    first, second = examples
    assert first.select_one(".example-file").get_text() == "hello.gd"
    assert first.select_one(".example-lang").get_text() == "GDScript"
    code = first.select_one("div.highlight-gdscript pre").get_text()
    assert "\t" not in code and "    print" in code
    assert first.select_one("div.example-output .example-output-label").get_text() == "Вывод"
    assert first.select_one("div.example-output pre").get_text().strip() == "Привет"
    assert second.select_one("div.example-output") is None


def test_example_in_game_project_shows_path_inside_project(tmp_path):
    src = tmp_path / "src"
    game = src / "projects" / "game"
    (game / "hero").mkdir(parents=True)
    (game / "project.godot").write_text("config_version=5\n", encoding="utf-8")
    (game / "hero" / "hero.gd").write_text("extends Node\n", encoding="utf-8")
    (src / "conf.py").write_text(CONF.format(ext=str(SOURCE / "_ext")), encoding="utf-8")
    (src / "index.rst").write_text("Тест\n====\n\n.. example:: game/hero/hero\n", encoding="utf-8")
    out = tmp_path / "out"
    assert build(src, out) == 0
    assert soup(out / "index.html").select_one(".example-file").get_text() == "hero/hero.gd"


def test_missing_example_fails_strict_build(tmp_path):
    src = tmp_path / "src"
    src.mkdir()
    (src / "conf.py").write_text(CONF.format(ext=str(SOURCE / "_ext")), encoding="utf-8")
    (src / "index.rst").write_text("Тест\n====\n\n.. example:: demo/missing\n", encoding="utf-8")
    assert build(src, tmp_path / "out") != 0


def test_in_game_directive(tmp_path):
    src = tmp_path / "src"
    src.mkdir()
    (src / "conf.py").write_text(CONF.format(ext=str(SOURCE / "_ext")), encoding="utf-8")
    (src / "index.rst").write_text("Тест\n====\n\n.. in-game::\n\n   Представьте **персонажа**.\n", encoding="utf-8")
    out = tmp_path / "out"
    assert build(src, out) == 0
    block = soup(out / "index.html").select_one("div.in-game")
    assert block.select_one("p.in-game-label").get_text() == "В игре"
    assert block.select_one("strong").get_text() == "персонажа"


def test_link_button_directive(tmp_path):
    src = tmp_path / "src"
    (src / "guide").mkdir(parents=True)
    (src / "conf.py").write_text(CONF.format(ext=str(SOURCE / "_ext")), encoding="utf-8")
    (src / "index.rst").write_text(
        "Тест\n====\n\n.. link-button:: guide/page\n\n   Открыть\n\n"
        ".. link-button:: guide/page\n   :secondary:\n\n   Ещё раз\n\n"
        ".. toctree::\n\n   guide/page\n",
        encoding="utf-8",
    )
    (src / "guide" / "page.rst").write_text("Статья\n======\n", encoding="utf-8")
    out = tmp_path / "out"
    assert build(src, out) == 0
    buttons = soup(out / "index.html").select("p.button-row a span.button")
    assert [b.get_text() for b in buttons] == ["Открыть", "Ещё раз"]
    assert "button-primary" in buttons[0]["class"]
    assert "button-secondary" in buttons[1]["class"]
    assert buttons[0].parent["href"] == "guide/page.html"


def test_link_button_to_missing_page_fails_strict_build(tmp_path):
    src = tmp_path / "src"
    src.mkdir()
    (src / "conf.py").write_text(CONF.format(ext=str(SOURCE / "_ext")), encoding="utf-8")
    (src / "index.rst").write_text("Тест\n====\n\n.. link-button:: missing\n\n   Нет\n", encoding="utf-8")
    assert build(src, tmp_path / "out") != 0


@pytest.mark.parametrize(
    ("current", "target", "expected"),
    [
        ("index", "intro/install", "intro/install"),
        ("intro/index", "install", "intro/install"),
        ("intro/index", "../gdscript/first_script", "gdscript/first_script"),
        ("intro/index", "/gdscript/first_script", "gdscript/first_script"),
    ],
)
def test_resolve_docname(current, target, expected):
    assert resolve_docname(current, target) == expected


@pytest.mark.parametrize(
    "code",
    [
        "@onready var lamps: Node2D = $Lamps\n",
        "var light: Polygon2D = $Lamps/Lamp1/Light\n",
        'var lamp: Node = $"Lamps/Lamp 2"\n',
        "@export var speed: float = 1.0\n",
    ],
)
def test_gdscript_lexer_has_no_errors(code):
    import sys

    from pygments.token import Error

    sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "source" / "_ext"))
    from godot_pygments import GodotLexer

    assert all(token is not Error for token, _ in GodotLexer().get_tokens(code))


def test_diff_lines_marks_changes_and_skips_context():
    sys.path.insert(0, str(SOURCE / "_ext"))
    from godot_zero import diff_lines

    old = [f"line {i}" for i in range(20)]
    new = old[:10] + ["added"] + old[11:]
    result = diff_lines(old, new, context=2)
    kinds = [kind for kind, _ in result]
    assert ("del", "line 10") in result
    assert ("add", "added") in result
    assert kinds[0] == "skip" and kinds[-1] == "skip"
    assert result[0] == ("skip", "8")


def test_example_diff_and_debug_toggle(tmp_path):
    index = INDEX.replace(
        "   :title: Пример\n",
        "   :title: Пример\n   :debug:\n\n.. example-diff:: demo/old.gd demo/main.gd\n",
    )
    src = make_project(tmp_path, index=index)
    (src / "projects" / "demo" / "old.gd").write_text("extends Node2D\n", encoding="utf-8")
    out = tmp_path / "out"
    assert build(src, out) == 0
    html = soup(out / "index.html")
    assert html.select_one("button.godot-demo-debug").get_text() == "МЫСЛИ: ВЫКЛ"
    diff = html.select_one("div.example-diff")
    assert diff.select_one(".diff-del") is not None
    assert diff.select_one(".diff-add") is not None
    assert diff.select_one("div.highlight")["data-code"] == "extends Node"


def test_demo_touch_pad_follows_scene_actions(tmp_path):
    src = make_project(tmp_path)
    scenes = src / "projects" / "examples"
    (scenes / "hero.gd").write_text(
        'extends Node2D\nfunc _process(_delta: float) -> void:\n\tInput.get_axis("move_left", "move_right")\n'
        '\tInput.is_action_just_pressed("jump")\n',
        encoding="utf-8",
    )
    (scenes / "hero.tscn").write_text(
        '[gd_scene format=3]\n[ext_resource type="Script" path="res://hero.gd" id="1"]\n[node name="Hero" type="Node2D"]\n'
        'script = ExtResource("1")\n',
        encoding="utf-8",
    )
    (scenes / "sample.tscn").write_text(
        '[gd_scene format=3]\n[ext_resource type="PackedScene" path="res://hero.tscn" id="1"]\n'
        '[node name="Sample" type="Node2D"]\n[node name="Hero" parent="." instance=ExtResource("1")]\n',
        encoding="utf-8",
    )
    out = tmp_path / "out"
    assert build(src, out) == 0
    pad = soup(out / "index.html").select_one("div.godot-demo div.godot-demo-pad")
    assert pad.has_attr("hidden")
    assert pad.select_one(".godot-demo-stick")["data-directions"] == "left right"
    assert [key["data-action"] for key in pad.select(".godot-demo-key")] == ["jump"]


def test_demo_without_keys_has_no_touch_pad(mini_site):
    assert soup(mini_site / "index.html").select_one(".godot-demo-pad") is None


def test_demo_hint_option_replaces_default_hint(tmp_path):
    index = INDEX.replace("   :title: Пример\n", "   :title: Пример\n   :hint: Найдите все дискеты!\n")
    src = make_project(tmp_path, index=index)
    out = tmp_path / "out"
    assert build(src, out) == 0
    assert soup(out / "index.html").select_one("p.godot-demo-hint").get_text() == "Найдите все дискеты!"


def test_demo_touch_hint_adds_touch_variant(tmp_path):
    hints = "   :hint: Мышью.\n   :touch-hint: Пальцем.\n"
    src = make_project(tmp_path, index=INDEX.replace("   :title: Пример\n", "   :title: Пример\n" + hints))
    out = tmp_path / "out"
    assert build(src, out) == 0
    hint = soup(out / "index.html").select_one("p.godot-demo-hint")
    assert hint.select_one(".godot-demo-mouse").get_text() == "Мышью."
    assert hint.select_one(".godot-demo-touch").get_text() == "Пальцем."
