from __future__ import annotations

import re
from pathlib import Path

from docutils import nodes
from sphinx.util.docutils import SphinxRole
from sphinx.util.nodes import split_explicit_title

from .projects import archive_name

DOCS_URL = "https://docs.godotengine.org/en/{version}/classes/class_{page}.html"


CLASS_RE = re.compile(r"^@?[A-Z][A-Za-z0-9_]*$")


MEMBER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


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
            msg = self.inliner.reporter.error(f"invalid Godot reference: {target!r}", line=self.lineno)
            return [self.inliner.problematic(self.rawtext, self.rawtext, msg)], [msg]
        ref = nodes.reference("", "", internal=False, refuri=url, classes=["godot-ref"])
        ref += nodes.literal(title, title)
        return [ref], []


class GodotSignalRole(GodotRole):
    signal = True


class ProjectRole(SphinxRole):
    def run(self):
        _, title, target = split_explicit_title(self.text)
        target = target.strip("/")
        root = Path(self.config.godot_projects_dir)
        if not (root / target / "project.godot").is_file():
            msg = self.inliner.reporter.error(f"Godot project not found: {target!r}", line=self.lineno)
            return [self.inliner.problematic(self.rawtext, self.rawtext, msg)], [msg]
        depth = self.env.docname.count("/")
        uri = "../" * depth + f"downloads/{archive_name(target)}"
        ref = nodes.reference("", "", internal=True, refuri=uri, classes=["project-download"])
        ref += nodes.Text(title if title != target else f"{target}.zip")
        return [ref], []
