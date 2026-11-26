from __future__ import annotations

import zipfile
from pathlib import Path

from sphinx.application import Sphinx

from .images import image_cache, prune_image_cache

EXCLUDED_DIRS = {".godot", "__pycache__"}


EXCLUDED_FILES = {".DS_Store"}


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
