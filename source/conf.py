import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / "_ext"))

project = "Godot: нулевой уровень"
author = "Pchela R."
copyright = "2026, Pchela R."
language = "ru"

extensions = [
    "sphinx_design",
    "godot_zero",
]

godot_docs_version = "4.7"
godot_projects_dir = "../projects"

html_theme = "godot"
html_theme_path = ["_themes"]
html_title = "Godot: нулевой уровень"
html_static_path = ["_static"]
html_favicon = "_static/favicon_32x32.png"
html_permalinks_icon = "#"

html_show_sphinx = False
html_show_sourcelink = False
html_copy_source = False

pygments_style = "godot_pygments.GodotStyle"
html_context = {"site_root": os.environ.get("SITE_ROOT", "/")}
