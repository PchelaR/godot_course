import os
import shutil
import subprocess
from collections import defaultdict
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
RUNNER = "tools/runner.gd"
MARKER = "@@@ "
FAILED = "@@@FAIL"


def godot_binary() -> str | None:
    for candidate in CANDIDATES:
        if candidate and Path(candidate).is_file():
            return candidate
    return None


def scripts() -> list[Path]:
    return sorted(p for p in PROJECTS.rglob("*.gd") if ".godot" not in p.parts)


def expected_outputs() -> list[Path]:
    return sorted(p for p in PROJECTS.rglob("*.out") if ".godot" not in p.parts)


def project_of(path: Path) -> Path:
    for parent in path.parents:
        if (parent / "project.godot").is_file():
            return parent
    raise AssertionError(f"file outside of a Godot project: {path}")


def res_path(path: Path) -> str:
    return "res://" + path.relative_to(project_of(path)).as_posix()


def target_of(expected: Path) -> Path:
    scene = expected.with_suffix(".tscn")
    return scene if scene.is_file() else expected.with_suffix(".gd")


GODOT = godot_binary()
pytestmark = pytest.mark.skipif(GODOT is None, reason="Godot not found: set GODOT_BIN")


def run(*args: str, cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [GODOT, "--headless", "--path", str(cwd), *args],
        capture_output=True,
        text=True,
        timeout=600,
    )


def split_by_marker(text: str) -> dict[str, str]:
    sections: dict[str, list[str]] = defaultdict(list)
    current = None
    for line in text.splitlines():
        if line.startswith(MARKER):
            current = line[len(MARKER) :]
            sections.setdefault(current, [])
        elif current is not None:
            sections[current].append(line)
    return {key: "\n".join(lines) for key, lines in sections.items()}


def clean_output(text: str) -> str:
    lines = [line for line in text.splitlines() if not line.startswith("Godot Engine v")]
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return "\n".join(lines)


def run_batch(mode: str, targets: list[Path]) -> dict[Path, tuple[str, str]]:
    by_project: dict[Path, list[Path]] = defaultdict(list)
    for target in targets:
        by_project[project_of(target)].append(target)
    results: dict[Path, tuple[str, str]] = {}
    for project, items in by_project.items():
        imported = run("--import", cwd=project)
        assert imported.returncode == 0, imported.stdout + imported.stderr
        if not (project / RUNNER).is_file():
            for item in items:
                single = run("--check-only", "--script", res_path(item), cwd=project)
                results[item] = (single.stdout, single.stderr)
            continue
        result = run("--script", f"res://{RUNNER}", "--", mode, *map(res_path, items), cwd=project)
        assert result.returncode == 0, result.stdout + result.stderr
        stdout = split_by_marker(result.stdout)
        stderr = split_by_marker(result.stderr)
        for item in items:
            key = res_path(item)
            assert key in stdout, f"no output for {key}:\n{result.stdout}\n{result.stderr}"
            results[item] = (stdout[key], stderr.get(key, ""))
    return results


@pytest.fixture(scope="session")
def checked() -> dict[Path, tuple[str, str]]:
    return run_batch("check", scripts())


@pytest.fixture(scope="session")
def executed() -> dict[Path, tuple[str, str]]:
    return run_batch("run", [target_of(expected) for expected in expected_outputs()])


def test_examples_have_scripts():
    assert scripts()


def test_every_output_has_script():
    for expected in expected_outputs():
        assert expected.with_suffix(".gd").is_file(), expected


@pytest.mark.parametrize("script", scripts(), ids=lambda p: p.relative_to(PROJECTS).as_posix())
def test_script_compiles(script, checked):
    stdout, stderr = checked[script]
    output = stdout + stderr
    assert FAILED not in stdout, output
    assert not any(marker in output for marker in ERRORS), output


@pytest.mark.parametrize(
    "expected", expected_outputs(), ids=lambda p: p.relative_to(PROJECTS).with_suffix("").as_posix()
)
def test_example_output(expected, executed):
    stdout, stderr = executed[target_of(expected)]
    assert FAILED not in stdout, stdout + stderr
    assert not any(marker in stderr for marker in ERRORS), stderr
    assert clean_output(stdout) == expected.read_text(encoding="utf-8").rstrip("\n")
