from __future__ import annotations

import hashlib
import shutil
from pathlib import Path

from docutils import nodes
from docutils.parsers.rst import directives
from PIL import Image
from sphinx.util.docutils import SphinxDirective
from sphinx.util.osutil import relative_uri

from .common import logger


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
            logger.warning("sprite not found: %s", path, location=self.get_location())
            return []
        self.env.note_dependency(str(path))
        with Image.open(path) as image:
            width, height = image.size
        if width % height:
            logger.warning("sprite frames must be square: %s", path, location=self.get_location())
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
        f"background-image: url(&quot;{self.encode(src)}&quot;); "
        f'background-size: {width * scale}px {height * scale}px"></div>'
    )


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
                logger.warning("game-intro: missing option %s", key, location=self.get_location())
                return []
            path = Path(self.config.godot_projects_dir) / self.options[key].strip("/")
            if not path.is_file():
                logger.warning("sprite not found: %s", path, location=self.get_location())
                return []
            self.env.note_dependency(str(path))
            with Image.open(path) as image:
                node[f"{key}_size"] = image.size
            node[key] = str(path)
        node["eyes"] = ""
        if "eyes" in self.options:
            path = Path(self.config.godot_projects_dir) / self.options["eyes"].strip("/")
            if not path.is_file():
                logger.warning("sprite not found: %s", path, location=self.get_location())
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


def pack_name(project: str) -> str:
    return project.strip("/").replace("/", "-") + ".pck"


class GodotDemoDirective(SphinxDirective):
    required_arguments = 1
    option_spec = {
        "ratio": directives.unchanged,
        "title": directives.unchanged,
        "debug": directives.flag,
    }

    def run(self):
        name = self.arguments[0].strip("/")
        root = Path(self.config.godot_projects_dir)
        project = root / name / "project.godot"
        scene = root / "examples" / f"{name}.tscn"
        node = godot_demo()
        if project.is_file():
            node["query"] = f"pack={pack_name(name)}"
            self.env.note_dependency(str(project))
        elif scene.is_file():
            node["query"] = f"scene={name}"
            self.env.note_dependency(str(scene))
        else:
            logger.warning("demo scene or project not found: %s", name, location=self.get_location())
            return []
        build = Path(self.env.srcdir) / DEMO_BUILD
        if not build.is_file():
            logger.warning("web build of the examples not found, run make demos", location=self.get_location())
        node["ratio"] = self.options.get("ratio", "16 / 9")
        node["title"] = self.options.get("title", "Пример в Godot")
        node["debug"] = "debug" in self.options
        return [node]


def visit_godot_demo_html(self, node: godot_demo) -> None:
    src = relative_uri(self.builder.get_target_uri(self.builder.current_docname), DEMO_BUILD)
    src = f"{src}?{node['query']}"
    title = self.encode(node["title"])
    camera = (
        ' <span class="godot-demo-mouse">Колесо мыши — масштаб, перетаскивание</span>'
        '<span class="godot-demo-touch">Перетаскивание пальцем</span> — перемещение камеры.'
        if node["query"].startswith("scene=")
        else ""
    )
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
        f'<p class="godot-demo-hint">Godot загрузится прямо в браузере.{camera}</p>'
        "</div></div>"
    )
    raise nodes.SkipNode
