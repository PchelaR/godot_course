import os
import shutil
import subprocess
from pathlib import Path

import pytest

from conftest import ROOT

PROJECTS = ROOT / "projects"
CANDIDATES = [
    os.environ.get("GODOT_BIN", ""),
    shutil.which("godot") or "",
    shutil.which("godot4") or "",
    "/Applications/Godot.app/Contents/MacOS/Godot",
]
ERRORS = ("SCRIPT ERROR", "Parse Error", "Compile Error")


def godot_binary() -> str | None:
    for candidate in CANDIDATES:
        if candidate and Path(candidate).is_file():
            return candidate
    return None


def scripts() -> list[Path]:
    return sorted(p for p in PROJECTS.rglob("*.gd") if ".godot" not in p.parts)


def project_of(script: Path) -> Path:
    for parent in script.parents:
        if (parent / "project.godot").is_file():
            return parent
    raise AssertionError(f"скрипт вне проекта Godot: {script}")


GODOT = godot_binary()
pytestmark = pytest.mark.skipif(GODOT is None, reason="Godot не найден: задайте GODOT_BIN")


def run(*args: str, cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [GODOT, "--headless", "--path", str(cwd), *args],
        capture_output=True,
        text=True,
        timeout=180,
    )


@pytest.fixture(scope="session")
def imported():
    done = set()

    def ensure(project: Path) -> None:
        if project not in done:
            result = run("--import", cwd=project)
            assert result.returncode == 0, result.stdout + result.stderr
            done.add(project)

    return ensure


def test_examples_have_scripts():
    assert scripts()


@pytest.mark.parametrize("script", scripts(), ids=lambda p: p.relative_to(PROJECTS).as_posix())
def test_script_compiles(script, imported):
    project = project_of(script)
    imported(project)
    res_path = "res://" + script.relative_to(project).as_posix()
    result = run("--check-only", "--script", res_path, cwd=project)
    output = result.stdout + result.stderr
    assert result.returncode == 0, output
    assert not any(marker in output for marker in ERRORS), output


RUNNER = "res://tools/runner.gd"


def expected_outputs() -> list[Path]:
    return sorted(p for p in PROJECTS.rglob("*.out") if ".godot" not in p.parts)


def clean_output(text: str) -> str:
    lines = [line for line in text.splitlines() if not line.startswith("Godot Engine v")]
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return "\n".join(lines)


def test_every_output_has_script():
    for expected in expected_outputs():
        assert expected.with_suffix(".gd").is_file(), expected


@pytest.mark.parametrize("expected", expected_outputs(), ids=lambda p: p.relative_to(PROJECTS).with_suffix("").as_posix())
def test_example_output(expected, imported):
    script = expected.with_suffix(".gd")
    scene = expected.with_suffix(".tscn")
    target = scene if scene.is_file() else script
    project = project_of(target)
    imported(project)
    res_path = "res://" + target.relative_to(project).as_posix()
    result = run("--script", RUNNER, "--", res_path, cwd=project)
    assert result.returncode == 0, result.stdout + result.stderr
    assert not any(marker in result.stderr for marker in ERRORS), result.stderr
    assert clean_output(result.stdout) == expected.read_text(encoding="utf-8").rstrip("\n")
