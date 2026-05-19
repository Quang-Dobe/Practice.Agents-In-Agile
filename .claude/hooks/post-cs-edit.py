#!/usr/bin/env python3
"""
PostToolUse hook for *.cs file edits.

- Edits under src/ -> `dotnet build` on the discovered solution
- Edits under tests/ -> `dotnet test` scoped to the matching test project (best-effort match)

Silently skips for non-.cs files. Surfaces failures to Claude via exit-code 2 + stderr.

The hook auto-discovers:
  - Solution: first *.slnx then *.sln in repo root.
  - Test project: nearest ancestor of the edited file that contains a *.csproj.
"""
import glob
import json
import os
import subprocess
import sys


def find_solution() -> str | None:
    for pattern in ("*.slnx", "*.sln"):
        matches = sorted(glob.glob(pattern))
        if matches:
            return matches[0]
    return None


def find_owning_csproj(file_path: str) -> str | None:
    d = os.path.dirname(os.path.abspath(file_path))
    while True:
        csprojs = glob.glob(os.path.join(d, "*.csproj"))
        if csprojs:
            return csprojs[0]
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    tool_input = data.get("tool_input", {}) or {}
    file_path = tool_input.get("file_path", "") or ""
    fp = file_path.replace("\\", "/")

    if not fp.endswith(".cs"):
        return 0

    solution = find_solution()
    if solution is None:
        return 0  # no .NET solution at root - nothing to do

    if "/src/" in fp:
        cmd = ["dotnet", "build", solution, "--nologo", "--verbosity", "quiet"]
        label = "BUILD"
    elif "/tests/" in fp:
        proj = find_owning_csproj(fp) or solution
        cmd = ["dotnet", "test", proj, "--nologo", "--verbosity", "quiet"]
        label = f"TESTS ({os.path.basename(proj)})"
    else:
        return 0

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write(f"{label} FAILED for {file_path}\n")
        if result.stdout.strip():
            sys.stderr.write(result.stdout)
        if result.stderr.strip():
            sys.stderr.write(result.stderr)
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
