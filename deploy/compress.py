import gzip
import sys
from pathlib import Path

SUFFIXES = {".html", ".css", ".js", ".json", ".svg", ".txt", ".wasm", ".pck", ".webmanifest", ".xml"}
MIN_SIZE = 1024


def compress(root: Path) -> tuple[int, int]:
    before = after = 0
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix not in SUFFIXES or path.stat().st_size < MIN_SIZE:
            continue
        data = path.read_bytes()
        packed = gzip.compress(data, compresslevel=9, mtime=0)
        if len(packed) >= len(data):
            continue
        path.with_name(path.name + ".gz").write_bytes(packed)
        before += len(data)
        after += len(packed)
    return before, after


if __name__ == "__main__":
    original, packed = compress(Path(sys.argv[1]))
    print(f"Compressed {original / 1e6:.1f} MB into {packed / 1e6:.1f} MB")
