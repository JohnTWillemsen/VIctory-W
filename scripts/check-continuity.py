#!/usr/bin/env python3
"""E129: source-only handoff consistency and disposable fresh-clone rehearsal.

This is a file/Git protocol test, not an AI-model behavior or game/GPU test.
Never reads title files, private logs, owner drives or external services.
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REQUIRED = (
    "AGENTS.md",
    "docs/agents/HANDOFF.md",
    "docs/agents/CURRENT_STATE.md",
    "docs/agents/LATEST_CHECKPOINT.md",
    "docs/agents/NEW_SESSION_PROMPT.md",
    "docs/agents/TASK_QUEUE.md",
    "docs/agents/EVIDENCE_LOG.md",
    "docs/agents/DECISIONS.md",
    "docs/migration/NVIDIA_SOURCE_PIN.md",
    "docs/research/E127-TESTING-AND-UPLOAD-PROTOCOL.md",
    "scripts/research/owner-nvidia-session.ps1",
    "crates/victory-gpu/src/host.rs",
    ".github/workflows/e127-nvidia-foundation-windows.yml",
)
SOURCE_SHA = "64d4931b3dd90305134512b805fc98f04119fb6e"
OLD_BASE_SHA = "63bcca43c6a00a758510398fa43096ce7e4f7df0"
LIMITS = {
    "AGENTS.md": 9500,
    "docs/agents/HANDOFF.md": 14000,
    "docs/agents/CURRENT_STATE.md": 10000,
    "docs/agents/LATEST_CHECKPOINT.md": 6000,
    "docs/agents/NEW_SESSION_PROMPT.md": 5000,
    "docs/agents/TASK_QUEUE.md": 8000,
}


def fail(message: str) -> None:
    raise AssertionError(message)


def git(root: Path, *args: str) -> str:
    cp = subprocess.run(["git", "-C", str(root), *args], text=True, capture_output=True, check=True)
    return cp.stdout.strip()


def verify(root: Path) -> str:
    """Check source-linked handoff, without accepting its dated SHA as a live one."""
    missing = [p for p in REQUIRED if not (root / p).is_file()]
    if missing:
        fail("Required NVIDIA handoff/source paths missing: " + ", ".join(missing))
    contents = {p: (root / p).read_text(encoding="utf-8") for p in REQUIRED if p.endswith(".md")}
    for path, limit in LIMITS.items():
        size = (root / path).stat().st_size
        if size > limit:
            fail(f"{path} is {size} bytes, exceeding short canonical limit {limit} (stale text pileup)")
    source = contents["docs/migration/NVIDIA_SOURCE_PIN.md"]
    handoff = contents["docs/agents/HANDOFF.md"]
    agents = contents["AGENTS.md"]
    prompt = contents["docs/agents/NEW_SESSION_PROMPT.md"]
    current = contents["docs/agents/CURRENT_STATE.md"]
    latest = contents["docs/agents/LATEST_CHECKPOINT.md"]
    queue = contents["docs/agents/TASK_QUEUE.md"]
    for path, value in [
        ("docs/migration/NVIDIA_SOURCE_PIN.md", source),
        ("docs/agents/HANDOFF.md", handoff),
        ("docs/agents/CURRENT_STATE.md", current),
        ("docs/agents/LATEST_CHECKPOINT.md", latest),
    ]:
        if SOURCE_SHA not in value:
            fail(f"{path} lacks canonical NVIDIA v8 upstream SHA")
    if OLD_BASE_SHA not in source or "archive/pre-nvidia-foundation-20261127" not in handoff:
        fail("Original source rollback missing")
    if "docs/agents/HANDOFF.md" not in agents or "docs/agents/HANDOFF.md" not in prompt:
        fail("Agent bootstrap/new-session prompt does not identify canonical handoff")
    if "live" not in prompt.lower() or "main" not in prompt:
        fail("Restart prompt must demand live GitHub default branch verification")
    if re.search(r"(?i)(migration (?:is )?in progress|main remains old source|main is still old)", "\n".join((agents, handoff, current, latest, queue))):
        fail("Current-state documents falsely describe finished NVIDIA migration as pending")
    if re.search(r"\b[0-9a-f]{40}\b", prompt):
        fail("New-session prompt is hard-pinned to a commit and will become stale")
    if "C:\\VIctory-NVIDIA" not in handoff or "C:\\VIctory-NVIDIA-Tests" not in handoff:
        fail("Owner's new local checkout/testing roots not recorded")
    if "World" not in handoff or "Controls" not in handoff or "E127-anonymous-summary.zip" not in handoff:
        fail("Positive playability criteria or single privacy-safe upload missing")
    if "NOT" not in handoff or "FAILED" not in handoff:
        fail("Source-build and gameplay limitations lost from handoff")
    evidence = contents["docs/agents/EVIDENCE_LOG.md"]
    ids = [int(x) for x in re.findall(r"(?m)^\| E-(\d{3}) ·", evidence)]
    if not ids or ids != list(range(1, len(ids) + 1)):
        fail("Evidence log E-series ID sequence missing/duplicated/not contiguous")
    if len(ids) < 128:
        fail("The migration evidence E128 or earlier was lost")
    if "D-047" not in contents["docs/agents/DECISIONS.md"]:
        fail("NVIDIA source-switch decision not present")
    if "strict" not in handoff.lower() or "synthetic" not in handoff.lower():
        fail("Build/lint/synthetic distinctions not recorded")
    if len([line for line in queue.splitlines() if line.startswith("| **VW-07")]) < 5:
        fail("Active NVIDIA task IDs missing from compact queue")
    # Evidence/decision records must be preserved, but never loaded wholesale as a startup plan.
    result = git(root, "rev-parse", "HEAD")
    if not re.fullmatch(r"[a-f0-9]{40}", result):
        fail("Cannot obtain exact checked-out Git source identity")
    print(f"PASS: NVIDIA handoff source pin, archive, startup references and statuses at {result}")
    print(f"PASS: {len(ids)} sequential evidence entries, append-only register present")
    print("PASS: short current-state files, live verification rules, E127 privacy/visual/control protocol")
    return result


def fresh_clone_rehearsal(root: Path) -> None:
    """Open source-controlled committed files in a new clone with no prior session HOME."""
    expected_head = git(root, "rev-parse", "HEAD")
    with tempfile.TemporaryDirectory(prefix="victory-handoff-") as folder:
        clone = Path(folder) / "fresh-checkout"
        subprocess.run(
            ["git", "clone", "--local", "--quiet", "--no-hardlinks", str(root), str(clone)],
            check=True,
            capture_output=True,
            text=True,
        )
        actual_head = git(clone, "rev-parse", "HEAD")
        if actual_head != expected_head:
            fail(f"Fresh clone SHA mismatch expected {expected_head} got {actual_head}")
        verify(clone)
        print("PASS: cold fresh clone can bootstrap from committed Git files at the same exact SHA")
        # A missing canonical file must fail closed. Never touch the real worktree.
        (clone / "docs/agents/HANDOFF.md").unlink()
        try:
            verify(clone)
        except AssertionError:
            print("PASS: missing canonical handoff rejects cold bootstrap")
        else:
            fail("Missing canonical handoff was silently accepted")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--smoke-clone", action="store_true", help="Also simulate restart in a fresh local clone")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    try:
        verify(root)
        if args.smoke_clone:
            fresh_clone_rehearsal(root)
    except (AssertionError, OSError, subprocess.CalledProcessError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1
    print("PASS: E129 source-only continuity verification complete (no AI/game/GPU test)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
