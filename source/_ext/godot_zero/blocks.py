from __future__ import annotations

import difflib
import html
import posixpath
from pathlib import Path

from docutils import nodes
from docutils.parsers.rst import directives
from sphinx.util.docutils import SphinxDirective

from godot_pygments import GodotLexer

from .common import logger


def build_example(directive: SphinxDirective, name: str) -> list[nodes.Node]:
    root = Path(directive.config.godot_projects_dir)
    script = root / "examples" / f"{name}.gd"
    if not script.is_file() and (root / f"{name}.gd").is_file():
        script = root / f"{name}.gd"
    if not script.is_file():
        logger.warning("example not found: %s", script, location=directive.get_location())
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
        logger.warning("button target page not found: %s", node["docname"], location=node)
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
                logger.warning("example not found: %s", path, location=self.get_location())
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
