from __future__ import annotations

from docutils import nodes
from sphinx.util import logging

logger = logging.getLogger(__name__)


def skip_node(self, node: nodes.Node) -> None:
    raise nodes.SkipNode


def pass_node(self, node: nodes.Element) -> None:
    pass
