from __future__ import annotations

import difflib
import hashlib
import html
import os
import posixpath
import re
import shutil
import zipfile
from pathlib import Path

from PIL import Image

from docutils import nodes
from docutils.parsers.rst import directives
from sphinx.application import Sphinx
from sphinx.util import logging
from sphinx.util.docutils import SphinxDirective, SphinxRole
from sphinx.util.nodes import split_explicit_title
from sphinx.util.osutil import relative_uri
from godot_pygments import GodotLexer

logger = logging.getLogger(__name__)

DOCS_URL = "https://docs.godotengine.org/en/{version}/classes/class_{page}.html"
CLASS_RE = re.compile(r"^@?[A-Z][A-Za-z0-9_]*$")
MEMBER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
EXCLUDED_DIRS = {".godot", "__pycache__"}
EXCLUDED_FILES = {".DS_Store"}


def godot_docs_url(target: str, version: str, signal: bool = False) -> str | None:
    cls, separator, member = target.partition(".")
    if not CLASS_RE.match(cls) or (separator and not member):
        return None
    page = cls.lower()
    url = DOCS_URL.format(version=version, page=page)
    if not member:
        return None if signal else url
    if member.endswith("()"):
        if signal:
            return None
        kind, name = "method", member[:-2]
    else:
        kind, name = ("signal" if signal else "property"), member
    if not MEMBER_RE.match(name):
        return None
    anchor = f"class-{page.lstrip('@')}-{kind}-{name.replace('_', '-').lower()}"
    return f"{url}#{anchor}"


class GodotRole(SphinxRole):
    signal = False

    def run(self):
        _, title, target = split_explicit_title(self.text)
        url = godot_docs_url(target, self.config.godot_docs_version, self.signal)
        if url is None:
            msg = self.inliner.reporter.error(
                f"некорректная ссылка на справку Godot: {target!r}", line=self.lineno
            )
            return [self.inliner.problematic(self.rawtext, self.rawtext, msg)], [msg]
        ref = nodes.reference("", "", internal=False, refuri=url, classes=["godot-ref"])
        ref += nodes.literal(title, title)
        return [ref], []


class GodotSignalRole(GodotRole):
    signal = True


def projects_root(app: Sphinx) -> Path:
    return (Path(app.confdir) / app.config.godot_projects_dir).resolve()


def resolve_projects_dir(app: Sphinx, config) -> None:
    config.godot_projects_dir = str(projects_root(app))
    config.godot_image_cache = str(image_cache(app))


def archive_name(relative: str) -> str:
    return relative.strip("/").replace("/", "-") + ".zip"


def find_projects(root: Path) -> list[Path]:
    if not root.is_dir():
        return []
    found = []
    for marker in sorted(root.rglob("project.godot")):
        if not EXCLUDED_DIRS.intersection(marker.relative_to(root).parts):
            found.append(marker.parent)
    return found


class ProjectRole(SphinxRole):
    def run(self):
        _, title, target = split_explicit_title(self.text)
        target = target.strip("/")
        root = Path(self.config.godot_projects_dir)
        if not (root / target / "project.godot").is_file():
            msg = self.inliner.reporter.error(
                f"проект Godot не найден: {target!r}", line=self.lineno
            )
            return [self.inliner.problematic(self.rawtext, self.rawtext, msg)], [msg]
        depth = self.env.docname.count("/")
        uri = "../" * depth + f"downloads/{archive_name(target)}"
        ref = nodes.reference("", "", internal=True, refuri=uri, classes=["project-download"])
        ref += nodes.Text(title if title != target else f"{target}.zip")
        return [ref], []


def pack_project(project: Path, root: Path, outdir: Path) -> Path:
    relative = project.relative_to(root).as_posix()
    target = outdir / archive_name(relative)
    target.parent.mkdir(parents=True, exist_ok=True)
    prefix = Path(relative.replace("/", "-"))
    files = [
        path
        for path in sorted(project.rglob("*"))
        if path.is_file()
        and not EXCLUDED_DIRS.intersection(path.relative_to(project).parts)
        and path.name not in EXCLUDED_FILES
    ]
    if target.is_file() and all(path.stat().st_mtime <= target.stat().st_mtime for path in files):
        with zipfile.ZipFile(target) as archive:
            if len(archive.namelist()) == len(files):
                return target
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, (prefix / path.relative_to(project)).as_posix())
    return target


def pack_projects(app: Sphinx, exception: Exception | None) -> None:
    if exception is not None or app.builder.format != "html":
        return
    root = projects_root(app)
    outdir = Path(app.outdir) / "downloads"
    for project in find_projects(root):
        pack_project(project, root, outdir)
    prune_image_cache(Path(app.srcdir), Path(app.config.godot_image_cache))


def prune_image_cache(srcdir: Path, cache: Path) -> None:
    if not cache.is_dir():
        return
    keep = set()
    for suffix in IMAGE_SUFFIXES:
        for image in srcdir.rglob(f"*{suffix}"):
            if IMAGE_NAME_RE.match(image.stem) and "_static" not in image.parts:
                digest = hashlib.sha256(image.read_bytes()).hexdigest()[:10]
                keep.add(f"{image.stem}.{digest}.webp")
    for cached in cache.glob("*.webp"):
        if cached.name not in keep:
            cached.unlink()


IMAGE_NAME_RE = re.compile(r"^[1-9][0-9]*$")
IMAGE_SUFFIXES = (".png", ".jpg", ".jpeg", ".webp")
BASE_DPI = 72


def find_image(root: Path, name: str) -> Path | None:
    for suffix in IMAGE_SUFFIXES:
        candidate = root / f"{name}{suffix}"
        if candidate.is_file():
            return candidate
    return None


def display_scale(image: Image.Image) -> int:
    dpi = image.info.get("dpi", (BASE_DPI, BASE_DPI))[0]
    return max(1, round(float(dpi) / BASE_DPI))


def optimize_image(source: Path, cache: Path) -> tuple[Path, int]:
    digest = hashlib.sha256(source.read_bytes()).hexdigest()[:10]
    target = cache / f"{source.stem}.{digest}.webp"
    with Image.open(source) as image:
        width = image.width // display_scale(image)
        if not target.is_file():
            cache.mkdir(parents=True, exist_ok=True)
            mode = "RGBA" if "A" in image.getbands() or "transparency" in image.info else "RGB"
            image.convert(mode).save(target, "WEBP", lossless=True, quality=100, method=6, exact=True)
    return target, width


def image_cache(app: Sphinx) -> Path:
    return Path(app.outdir).parent / ".image-cache"


class ScreenshotDirective(SphinxDirective):
    required_arguments = 1
    has_content = True
    option_spec = {"alt": directives.unchanged}

    def run(self):
        name = self.arguments[0]
        if not IMAGE_NAME_RE.match(name):
            logger.warning("некорректное имя изображения: %r", name, location=self.get_location())
            return []
        source = find_image(Path(self.env.srcdir) / self.env.docname, name)
        if source is None:
            logger.warning(
                "изображение не найдено: %s/%s.png", self.env.docname, name, location=self.get_location()
            )
            return []
        self.env.note_dependency(str(source))
        target, width = optimize_image(source, Path(self.config.godot_image_cache))
        uri = "/" + os.path.relpath(target, self.env.srcdir).replace(os.sep, "/")
        caption = " ".join(self.content).strip()
        text_nodes, messages = self.state.inline_text(caption, self.lineno) if caption else ([], [])
        plain = "".join(node.astext() for node in text_nodes)
        figure = nodes.figure(classes=["screenshot"])
        figure += nodes.image(uri=uri, alt=self.options.get("alt", plain or name), width=f"{width}px")
        if caption:
            figure += nodes.caption(caption, "", *text_nodes)
        return [figure, *messages]


def build_example(directive: SphinxDirective, name: str) -> list[nodes.Node]:
    script = Path(directive.config.godot_projects_dir) / "examples" / f"{name}.gd"
    if not script.is_file():
        logger.warning("пример не найден: %s", script, location=directive.get_location())
        return []
    directive.env.note_dependency(str(script))
    source = script.read_text(encoding="utf-8").expandtabs(4).rstrip("\n")

    header = nodes.paragraph(classes=["example-header"])
    header += nodes.inline(script.name, script.name, classes=["example-file"])
    header += nodes.inline("GDScript", "GDScript", classes=["example-lang"])

    code = nodes.literal_block(source, source, language="gdscript")
    example = nodes.container(classes=["example"])
    example += header
    example += code

    expected = script.with_suffix(".out")
    if expected.is_file():
        directive.env.note_dependency(str(expected))
        text = expected.read_text(encoding="utf-8").rstrip("\n")
        output = nodes.container(classes=["example-output"])
        output += nodes.paragraph("Вывод", "Вывод", classes=["example-output-label"])
        output += nodes.literal_block(text, text, language="text")
        example += output
    return [example]


class ExampleDirective(SphinxDirective):
    required_arguments = 1

    def run(self):
        return build_example(self, self.arguments[0].strip("/"))


class ExerciseDirective(SphinxDirective):
    has_content = True

    def run(self):
        block = nodes.container(classes=["exercise"])
        block += nodes.paragraph("Задание", "Задание", classes=["exercise-label"])
        self.state.nested_parse(self.content, self.content_offset, block)
        return [block]


class solution(nodes.General, nodes.Element):
    pass


class SolutionDirective(SphinxDirective):
    optional_arguments = 1
    has_content = True

    def run(self):
        node = solution()
        if self.arguments:
            node += build_example(self, self.arguments[0].strip("/"))
        self.state.nested_parse(self.content, self.content_offset, node)
        return [node]


def visit_solution_html(self, node: solution) -> None:
    self.body.append('<details class="exercise-solution"><summary>Решение</summary>')


def depart_solution_html(self, node: solution) -> None:
    self.body.append("</details>")


def pass_node(self, node: nodes.Element) -> None:
    pass


class link_button(nodes.General, nodes.Element):
    pass


def resolve_docname(current: str, target: str) -> str:
    if target.startswith("/"):
        return posixpath.normpath(target.lstrip("/"))
    return posixpath.normpath(posixpath.join(posixpath.dirname(current), target))


class LinkButtonDirective(SphinxDirective):
    required_arguments = 1
    has_content = True
    option_spec = {"secondary": directives.flag}

    def run(self):
        node = link_button()
        node["docname"] = resolve_docname(self.env.docname, self.arguments[0])
        node["text"] = " ".join(self.content).strip() or self.arguments[0]
        node["variant"] = "button-secondary" if "secondary" in self.options else "button-primary"
        node.source, node.line = self.get_source_info()
        return [node]


def visit_link_button_html(self, node: link_button) -> None:
    if node["docname"] not in self.builder.env.all_docs:
        logger.warning("страница для кнопки не найдена: %s", node["docname"], location=node)
        raise nodes.SkipNode
    href = self.builder.get_relative_uri(self.builder.current_docname, node["docname"])
    self.body.append(
        f'<p class="button-row"><a class="reference internal" href="{self.encode(href)}">'
        f'<span class="button {node["variant"]}">{self.encode(node["text"])}</span></a></p>'
    )
    raise nodes.SkipNode


class FunFactDirective(SphinxDirective):
    has_content = True

    def run(self):
        block = nodes.container(classes=["fun-fact"])
        block += nodes.paragraph("Интересное", "Интересное", classes=["fun-fact-label"])
        self.state.nested_parse(self.content, self.content_offset, block)
        return [block]


class InGameDirective(SphinxDirective):
    has_content = True

    def run(self):
        block = nodes.container(classes=["in-game"])
        block += nodes.paragraph("В игре", "В игре", classes=["in-game-label"])
        self.state.nested_parse(self.content, self.content_offset, block)
        return [block]


class sprite_animation(nodes.General, nodes.Element):
    pass


class SpriteAnimationDirective(SphinxDirective):
    required_arguments = 1
    option_spec = {
        "scale": directives.positive_int,
        "fps": directives.positive_int,
        "alt": directives.unchanged,
    }

    def run(self):
        relative = self.arguments[0].strip("/")
        path = Path(self.config.godot_projects_dir) / relative
        if not path.is_file():
            logger.warning("спрайт не найден: %s", path, location=self.get_location())
            return []
        self.env.note_dependency(str(path))
        with Image.open(path) as image:
            width, height = image.size
        if width % height:
            logger.warning("кадры спрайта должны быть квадратными: %s", path, location=self.get_location())
            return []
        node = sprite_animation()
        node["path"] = str(path)
        node["width"] = width
        node["height"] = height
        node["frames"] = width // height
        node["scale"] = self.options.get("scale", 6)
        node["fps"] = self.options.get("fps", 6)
        node["alt"] = self.options.get("alt", "")
        return [node]


def publish_sprite(builder, path: str) -> str:
    digest = hashlib.sha256(Path(path).read_bytes()).hexdigest()[:16]
    target = f"_images/sprites/{digest}.png"
    output = Path(builder.outdir) / target
    if not output.is_file():
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, output)
    return relative_uri(builder.get_target_uri(builder.current_docname), target)


def sprite_html(self, src: str, width: int, height: int, scale: int, fps: int) -> str:
    frames = width // height
    window = f"width: {height * scale}px; height: {height * scale}px"
    motion = f"animation-duration: {frames / fps:.3f}s; animation-timing-function: steps({frames})"
    return (
        f'<div class="sprite-animation-window" style="{window}">'
        f'<img src="{self.encode(src)}" alt="" width="{width * scale}" height="{height * scale}" style="{motion}">'
        "</div>"
    )


def visit_sprite_animation_html(self, node: sprite_animation) -> None:
    src = publish_sprite(self.builder, node["path"])
    self.body.append(
        f'<div class="sprite-animation" role="img" aria-label="{self.encode(node["alt"])}">'
        + sprite_html(self, src, node["width"], node["height"], node["scale"], node["fps"])
        + "</div>"
    )
    raise nodes.SkipNode


def eyes_html(self, node, scale: int) -> str:
    if not node["eyes"]:
        return ""
    src = publish_sprite(self.builder, node["eyes"])
    width, height = node["eyes_size"]
    return (
        f'<div class="game-intro-eyes" style="width: {height * scale}px; height: {height * scale}px; '
        f'background-image: url(&quot;{self.encode(src)}&quot;); '
        f'background-size: {width * scale}px {height * scale}px"></div>'
    )


def diff_lines(old: list[str], new: list[str], context: int = 3) -> list[tuple[str, str]]:
    marked: list[tuple[str, str]] = []
    for line in difflib.ndiff(old, new):
        tag, text = line[:2], line[2:]
        if tag == "  ":
            marked.append(("same", text))
        elif tag == "- ":
            marked.append(("del", text))
        elif tag == "+ ":
            marked.append(("add", text))
    changed = [i for i, (kind, _) in enumerate(marked) if kind != "same"]
    keep = {j for i in changed for j in range(i - context, i + context + 1)}
    result: list[tuple[str, str]] = []
    skipped = 0
    for i, item in enumerate(marked):
        if item[0] != "same" or i in keep:
            if skipped:
                result.append(("skip", str(skipped)))
                skipped = 0
            result.append(item)
        else:
            skipped += 1
    if skipped:
        result.append(("skip", str(skipped)))
    return result


class example_diff(nodes.General, nodes.Element):
    pass


class ExampleDiffDirective(SphinxDirective):
    required_arguments = 2
    option_spec = {"name": directives.unchanged}

    def run(self):
        root = Path(self.config.godot_projects_dir)
        paths = [root / argument.strip("/") for argument in self.arguments]
        for path in paths:
            if not path.is_file():
                logger.warning("пример не найден: %s", path, location=self.get_location())
                return []
            self.env.note_dependency(str(path))
        old, new = (path.read_text(encoding="utf-8").expandtabs(4).rstrip("\n") for path in paths)
        node = example_diff()
        node["new"] = new
        node["lines"] = diff_lines(old.split("\n"), new.split("\n"))
        node["name"] = self.options.get("name", paths[1].name)
        return [node]


def visit_example_diff_html(self, node: example_diff) -> None:
    from pygments import highlight
    from pygments.formatters import HtmlFormatter

    formatter = HtmlFormatter(nowrap=True)
    lexer = GodotLexer()
    rows = []
    for kind, text in node["lines"]:
        if kind == "skip":
            count = int(text)
            rows.append(f'<span class="diff-line diff-skip">⋯ без изменений: {count} стр.\n</span>')
            continue
        code = highlight(text or " ", lexer, formatter).rstrip("\n")
        rows.append(f'<span class="diff-line diff-{kind}">{code}\n</span>')
    self.body.append(
        '<div class="example example-diff">'
        f'<p class="example-header"><span class="example-file">{self.encode(node["name"])}</span>'
        '<span class="example-lang">Изменения</span></p>'
        '<div class="highlight-gdscript notranslate">'
        f'<div class="highlight" data-code="{html.escape(node["new"], quote=True)}"><pre>'
        + "".join(rows)
        + "</pre></div></div></div>"
    )
    raise nodes.SkipNode


class game_intro(nodes.General, nodes.Element):
    pass


class GameIntroDirective(SphinxDirective):
    option_spec = {
        "hero": directives.unchanged_required,
        "enemy": directives.unchanged_required,
        "coin": directives.unchanged_required,
        "eyes": directives.unchanged,
        "title": directives.unchanged,
        "alt": directives.unchanged,
    }

    def run(self):
        node = game_intro()
        for key in ("hero", "enemy", "coin"):
            if key not in self.options:
                logger.warning("game-intro: не задан параметр %s", key, location=self.get_location())
                return []
            path = Path(self.config.godot_projects_dir) / self.options[key].strip("/")
            if not path.is_file():
                logger.warning("спрайт не найден: %s", path, location=self.get_location())
                return []
            self.env.note_dependency(str(path))
            with Image.open(path) as image:
                node[f"{key}_size"] = image.size
            node[key] = str(path)
        node["eyes"] = ""
        if "eyes" in self.options:
            path = Path(self.config.godot_projects_dir) / self.options["eyes"].strip("/")
            if not path.is_file():
                logger.warning("спрайт не найден: %s", path, location=self.get_location())
                return []
            self.env.note_dependency(str(path))
            with Image.open(path) as image:
                node["eyes_size"] = image.size
            node["eyes"] = str(path)
        node["title"] = self.options.get("title", "PRESS START")
        node["alt"] = self.options.get("alt", "")
        return [node]


def visit_game_intro_html(self, node: game_intro) -> None:
    scale = 3
    hero = publish_sprite(self.builder, node["hero"])
    enemy = publish_sprite(self.builder, node["enemy"])
    coin = publish_sprite(self.builder, node["coin"])
    coin_size = node["coin_size"][1] * scale
    self.body.append(
        f'<div class="game-intro" role="img" aria-label="{self.encode(node["alt"])}">'
        f'<p class="game-intro-bar">{self.encode(node["title"])}</p>'
        '<div class="game-intro-track">'
        f'<div class="game-intro-coins" style="background-image: url(&quot;{self.encode(coin)}&quot;); '
        f'background-size: {coin_size}px {coin_size}px"></div>'
        '<div class="game-intro-actor game-intro-hero">'
        + sprite_html(self, hero, *node["hero_size"], scale, 8)
        + '</div><div class="game-intro-actor game-intro-enemy">'
        + sprite_html(self, enemy, *node["enemy_size"], scale, 4)
        + eyes_html(self, node, scale)
        + "</div></div></div>"
    )
    raise nodes.SkipNode


DEMO_BUILD = "_static/godot/index.html"


class godot_demo(nodes.General, nodes.Element):
    pass


class GodotDemoDirective(SphinxDirective):
    required_arguments = 1
    option_spec = {
        "ratio": directives.unchanged,
        "title": directives.unchanged,
        "debug": directives.flag,
    }

    def run(self):
        name = self.arguments[0].strip("/")
        scene = Path(self.config.godot_projects_dir) / "examples" / f"{name}.tscn"
        if not scene.is_file():
            logger.warning("сцена демо не найдена: %s", scene, location=self.get_location())
            return []
        build = Path(self.env.srcdir) / DEMO_BUILD
        if not build.is_file():
            logger.warning("веб-сборка примеров не найдена, выполните make demos", location=self.get_location())
        self.env.note_dependency(str(scene))
        node = godot_demo()
        node["scene"] = name
        node["ratio"] = self.options.get("ratio", "16 / 9")
        node["title"] = self.options.get("title", "Пример в Godot")
        node["debug"] = "debug" in self.options
        return [node]


def visit_godot_demo_html(self, node: godot_demo) -> None:
    src = relative_uri(self.builder.get_target_uri(self.builder.current_docname), DEMO_BUILD)
    src = f"{src}?scene={node['scene']}"
    title = self.encode(node["title"])
    debug = (
        '<button class="godot-demo-debug" type="button" aria-pressed="false">МЫСЛИ: ВЫКЛ</button>'
        if node.get("debug")
        else ""
    )
    self.body.append(
        f'<div class="godot-demo" data-src="{self.encode(src)}" data-title="{title}">'
        f'<p class="godot-demo-bar"><span class="godot-demo-title">{title}</span>{debug}</p>'
        f'<div class="godot-demo-screen" style="aspect-ratio: {self.encode(node["ratio"])}">'
        '<button class="button button-primary godot-demo-start" type="button">Запустить пример</button>'
        '<p class="godot-demo-hint">Godot загрузится прямо в браузере. '
        "Колесо мыши — масштаб, перетаскивание — перемещение камеры.</p>"
        "</div></div>"
    )
    raise nodes.SkipNode


def skip_node(self, node: nodes.Node) -> None:
    raise nodes.SkipNode


def refresh_all_pages(app: Sphinx, env, added: set, changed: set, removed: set) -> list[str]:
    if added or changed or removed:
        return sorted(env.found_docs)
    return []


def add_theme_script(app: Sphinx) -> None:
    if app.config.html_theme == "godot":
        app.add_js_file("godot.js", loading_method="defer")


EXTENSION_HASH = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()


def setup(app: Sphinx) -> dict:
    app.add_config_value("godot_extension_hash", EXTENSION_HASH, "env")
    app.add_config_value("godot_docs_version", "stable", "env")
    app.add_config_value("godot_projects_dir", "../projects", "env")
    app.add_config_value("godot_image_cache", "", "")
    app.add_lexer("gdscript", GodotLexer)
    app.add_role("godot", GodotRole())
    app.add_role("godot-signal", GodotSignalRole())
    app.add_role("project", ProjectRole())
    app.add_node(
        godot_demo,
        html=(visit_godot_demo_html, None),
        text=(skip_node, None),
        latex=(skip_node, None),
        man=(skip_node, None),
        texinfo=(skip_node, None),
    )
    app.add_directive("godot-demo", GodotDemoDirective)
    app.add_directive("screenshot", ScreenshotDirective)
    app.add_directive("example", ExampleDirective)
    app.add_node(
        example_diff,
        html=(visit_example_diff_html, None),
        text=(skip_node, None),
        latex=(skip_node, None),
        man=(skip_node, None),
        texinfo=(skip_node, None),
    )
    app.add_directive("example-diff", ExampleDiffDirective)
    app.add_directive("in-game", InGameDirective)
    app.add_directive("fun-fact", FunFactDirective)
    app.add_directive("exercise", ExerciseDirective)
    app.add_node(
        sprite_animation,
        html=(visit_sprite_animation_html, None),
        text=(skip_node, None),
        latex=(skip_node, None),
        man=(skip_node, None),
        texinfo=(skip_node, None),
    )
    app.add_directive("sprite-animation", SpriteAnimationDirective)
    app.add_node(
        game_intro,
        html=(visit_game_intro_html, None),
        text=(skip_node, None),
        latex=(skip_node, None),
        man=(skip_node, None),
        texinfo=(skip_node, None),
    )
    app.add_directive("game-intro", GameIntroDirective)
    app.add_node(
        solution,
        html=(visit_solution_html, depart_solution_html),
        text=(pass_node, pass_node),
        latex=(pass_node, pass_node),
        man=(pass_node, pass_node),
        texinfo=(pass_node, pass_node),
    )
    app.add_directive("solution", SolutionDirective)
    app.add_node(
        link_button,
        html=(visit_link_button_html, None),
        text=(skip_node, None),
        latex=(skip_node, None),
        man=(skip_node, None),
        texinfo=(skip_node, None),
    )
    app.add_directive("link-button", LinkButtonDirective)
    app.connect("builder-inited", add_theme_script)
    app.connect("config-inited", resolve_projects_dir)
    app.connect("build-finished", pack_projects)
    app.connect("env-get-outdated", refresh_all_pages)
    return {"version": "1.0", "parallel_read_safe": True, "parallel_write_safe": True}
