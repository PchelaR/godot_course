from __future__ import annotations

import hashlib
from pathlib import Path

from sphinx.application import Sphinx

from godot_pygments import GodotLexer

from .blocks import (
    ExampleDiffDirective,
    ExampleDirective,
    ExerciseDirective,
    FunFactDirective,
    InGameDirective,
    LinkButtonDirective,
    SolutionDirective,
    depart_solution_html,
    diff_lines,
    example_diff,
    link_button,
    resolve_docname,
    solution,
    visit_example_diff_html,
    visit_link_button_html,
    visit_solution_html,
)
from .common import pass_node, skip_node
from .images import ScreenshotDirective, optimize_image
from .media import (
    GameIntroDirective,
    GodotDemoDirective,
    SpriteAnimationDirective,
    game_intro,
    godot_demo,
    sprite_animation,
    visit_game_intro_html,
    visit_godot_demo_html,
    visit_sprite_animation_html,
)
from .projects import archive_name, pack_projects, resolve_projects_dir
from .pwa import write_offline_files
from .roles import GodotRole, GodotSignalRole, ProjectRole, godot_docs_url

__all__ = ["archive_name", "diff_lines", "godot_docs_url", "optimize_image", "resolve_docname", "setup"]


def refresh_all_pages(app: Sphinx, env, added: set, changed: set, removed: set) -> list[str]:
    if added or changed or removed:
        return sorted(env.found_docs)
    return []


def add_theme_script(app: Sphinx) -> None:
    if app.config.html_theme == "godot":
        app.add_js_file("godot.js", loading_method="defer")
        app.add_css_file("godot.css", priority=900)


EXTENSION_HASH = hashlib.sha256(
    b"".join(path.read_bytes() for path in sorted(Path(__file__).parent.glob("*.py")))
).hexdigest()


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
    app.connect("build-finished", write_offline_files)
    app.connect("env-get-outdated", refresh_all_pages)
    return {"version": "1.0", "parallel_read_safe": True, "parallel_write_safe": True}
