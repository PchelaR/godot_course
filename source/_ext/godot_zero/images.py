from __future__ import annotations

import hashlib
import os
import re
from pathlib import Path

from docutils import nodes
from docutils.parsers.rst import directives
from PIL import Image
from sphinx.application import Sphinx
from sphinx.util.docutils import SphinxDirective

from .common import logger


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
            logger.warning("invalid image name: %r", name, location=self.get_location())
            return []
        source = find_image(Path(self.env.srcdir) / self.env.docname, name)
        if source is None:
            logger.warning("image not found: %s/%s.png", self.env.docname, name, location=self.get_location())
            return []
        self.env.note_dependency(str(source))
        target, width = optimize_image(source, Path(self.config.godot_image_cache))
        uri = "/" + os.path.relpath(target, self.env.srcdir).replace(os.sep, "/")
        caption = " ".join(self.content).strip()
        text_nodes, messages = self.state.inline_text(caption, self.lineno) if caption else ([], [])
        plain = "".join(node.astext() for node in text_nodes)
        figure = nodes.figure(classes=["screenshot"])
        figure += nodes.image(uri=uri, alt=self.options.get("alt", plain or name), width=f"{width}px", loading="lazy")
        if caption:
            figure += nodes.caption(caption, "", *text_nodes)
        return [figure, *messages]
