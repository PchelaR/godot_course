from pygments.lexer import inherit
from pygments.lexers.gdscript import GDScriptLexer
from pygments.style import Style
from pygments.token import Name


class GodotLexer(GDScriptLexer):
    name = "GDScript"
    aliases = ["gdscript", "gd"]
    tokens = {
        "root": [
            (r"@[A-Za-z_]\w*", Name.Decorator),
            (r'\$(?:"[^"\n]*"|[A-Za-z_][\w/]*)', Name.Variable),
            inherit,
        ],
    }


class GodotStyle(Style):
    name = "godot"
    background_color = "transparent"
    highlight_color = "transparent"
    line_number_color = "inherit"
    line_number_background_color = "transparent"
    line_number_special_color = "inherit"
    line_number_special_background_color = "transparent"
    styles = {}
