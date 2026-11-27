#!/usr/bin/env python3
"""E-045: exact-preimage six-PR reconciliation, run only in disposable source."""
from __future__ import annotations
import sys
from pathlib import Path

PATHS = [
 "apps/victory/src/translate.rs",
 "crates/victory-gpu/src/draw.rs",
 "crates/victory-gpu/src/shader_cache.rs",
 "crates/victory-shader/src/emit/lower.rs",
 "crates/victory-shader/src/emit/mod.rs",
]

def edit(src, old, new, name, n=1):
    found=src.count(old)
    if found!=n:
        raise ValueError(f"{name}: expected {n} occurrences, found {found}: {old[:100]!r}")
    return src.replace(old,new)

def main(root):
    root=root.resolve()
    expected={p+".rej" for p in PATHS}
    actual={p.relative_to(root).as_posix() for p in root.rglob("*.rej") if ".git" not in p.parts}
    if actual!=expected:
        raise ValueError(f"reject inventory mismatch: {sorted(actual)} vs {sorted(expected)}")
    before={p:(root/p).read_text(encoding="utf8") for p in PATHS}
    after=dict(before)

    # Offline command-line translation retains #439 host target, defaults
    # the new portable-heap option to false. No D3D12 host exists there.
    p=PATHS[0]
    after[p]=edit(after[p],
        "                        target: checks.target,\n                    };",
        "                        target: checks.target,\n                        ..Default::default()\n                    };",p)
    # #439's test already has the needed Options default expansion.
    p=PATHS[1]
    if "            Options {\n                view_marks: true,\n                ..Options::default()\n            }," not in after[p]:
        raise ValueError("draw.rs missing already-satisfied Options default")

    p=PATHS[2]; s=after[p]
    # #2628's partial patch added view_limit to the build key, but we must
    # preserve #439 wave target AND avoid freezing a device-less first probe.
    # Keep the static build key independent of the adapter; host_key includes
    # BOTH the wave range and actual heap size at each use.
    s=edit(s,
        "fn options() -> victory_shader::emit::Options {\n    victory_shader::emit::Options { view_marks: true, portable_views: crate::descriptor::host::portable_view_heap() }\n}",
        "fn options(target: Target) -> victory_shader::emit::Options {\n    victory_shader::emit::Options {\n        view_marks: true,\n        target,\n        portable_views: crate::descriptor::host::portable_view_heap(),\n    }\n}",p)
    s=edit(s,"key(victory_shader::SOURCE_HASH, ENCODING, limit, options().view_heap_limit())",
        "key(victory_shader::SOURCE_HASH, ENCODING, limit, victory_shader::emit::HEAP_VIEWS)",p)
    s=edit(s,"    let options = victory_shader::emit::Options {\n        view_marks: true,\n        target,\n    };",
        "    let options = options(target);",p)
    s=edit(s,"&host_key(build(), target), container, translate",
        "&host_key(build(), target, options.view_heap_limit()), container, translate",p)
    s=edit(s,"fn host_key(build: &[u8; 32], target: Target) -> [u8; 32] {",
        "fn host_key(build: &[u8; 32], target: Target, view_limit: u32) -> [u8; 32] {",p)
    s=edit(s,"    h.update(&target.key());\n    *h.finalize().as_bytes()",
        "    h.update(&target.key());\n    h.update(&view_limit.to_le_bytes());\n    *h.finalize().as_bytes()",p)
    s=edit(s,"                options().view_heap_limit()\n",
        "                victory_shader::emit::HEAP_VIEWS\n",p)
    s=edit(s,"        assert_eq!(host_key(&build, nvidia), host_key(&build, nvidia));",
        "        let full = victory_shader::emit::HEAP_VIEWS;\n        let portable = victory_shader::emit::PORTABLE_VIEWS;\n        assert_eq!(host_key(&build, nvidia, full), host_key(&build, nvidia, full));",p)
    s=edit(s,"        assert_ne!(host_key(&build, nvidia), host_key(&build, rdna));",
        "        assert_ne!(host_key(&build, nvidia, full), host_key(&build, rdna, full));",p)
    s=edit(s,"        assert_ne!(host_key(&build, nvidia), host_key(&[8; 32], nvidia));",
        "        assert_ne!(host_key(&build, nvidia, full), host_key(&[8; 32], nvidia, full));\n"
        "        assert_ne!(host_key(&build, nvidia, full), host_key(&build, nvidia, portable));",p)
    after[p]=s

    p=PATHS[3]; s=after[p]
    # Preserve the #439 numeric-select retry, console-flow handling and
    # conservative Wave64 failure gates, propagate the new heap limit.
    s=edit(s,"pub(crate) fn lower(parts: &Parts) -> Result<Lowered, ShaderError> {\n    match lower_program(parts, false) {",
        "#[cfg(test)]\npub(crate) fn lower(parts: &Parts) -> Result<Lowered, ShaderError> {\n"
        "    lower_with_limit(parts, super::HEAP_VIEWS)\n}\n\n"
        "pub(crate) fn lower_with_limit(parts: &Parts, view_limit: u32) -> Result<Lowered, ShaderError> {\n"
        "    match lower_program(parts, false, view_limit) {",p)
    s=edit(s,"        }) if parts.native.stage == HwStage::Cs => lower_program(parts, true),",
        "        }) if parts.native.stage == HwStage::Cs => lower_program(parts, true, view_limit),",p)
    s=edit(s,"fn lower_program(parts: &Parts, numeric_selects: bool) -> Result<Lowered, ShaderError> {",
        "fn lower_program(parts: &Parts, numeric_selects: bool, view_limit: u32) -> Result<Lowered, ShaderError> {",p)
    s=edit(s,"Lower::new(parts, &bad, numeric_selects).run()",
        "Lower::new(parts, &bad, numeric_selects, view_limit).run()",p)
    s=edit(s,"fn new(x: &'a Parts<'a>, bad: &'a HashMap<Value, Why>, numeric_selects: bool) -> Self {",
        "fn new(x: &'a Parts<'a>, bad: &'a HashMap<Value, Why>, numeric_selects: bool, view_limit: u32) -> Self {",p)
    if s.count("s.view_limit = view_limit;")!=1:
        raise ValueError("lower.rs #2628 partial hunk did not set Shader.view_limit exactly once")
    after[p]=s

    p=PATHS[4]; s=after[p]
    s=edit(s,"/// How a translation is made.\n#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]\npub struct Options {",
        "/// Portable shader-visible descriptor heap size on capped hosts.\npub const PORTABLE_VIEWS: u32 = 1_000_000;\n"
        "/// Title descriptors before the dynamic pool and three null views.\n"
        "pub const PORTABLE_TITLE_VIEWS: u32 = PORTABLE_VIEWS - 3 - (1 << 18);\n\n"
        "/// How a translation is made.\n#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]\npub struct Options {",p)
    s=edit(s,"    pub target: Target,\n}",
        "    pub target: Target,\n"
        "    /// Use a portable one-million-descriptor heap for shader view indices.\n"
        "    pub portable_views: bool,\n}\n\n"
        "impl Options {\n"
        "    pub fn view_heap_limit(self) -> u32 {\n"
        "        if self.portable_views { PORTABLE_VIEWS } else { HEAP_VIEWS }\n"
        "    }\n}",p)
    for old,new in [
        ("lower::lower(&parts(st, res, false, false))","lower::lower_with_limit(&parts(st, res, false, false), options.view_heap_limit())"),
        ("lower::lower(&parts(console, res, true, false))","lower::lower_with_limit(&parts(console, res, true, false), options.view_heap_limit())"),
        ("lower::lower(&parts(st, res, false, true))","lower::lower_with_limit(&parts(st, res, false, true), options.view_heap_limit())"),
        ("lower::lower(&parts(&st, &res, false, false))","lower::lower_with_limit(&parts(&st, &res, false, false), options.view_heap_limit())"),
    ]:
        s=edit(s,old,new,p)
    after[p]=s

    # Transactional: only write after ALL expected preimages and source
    # preconditions have been validated. Reject files are then removed.
    for p in PATHS:
        if before[p]!=after[p]:
            (root/p).write_text(after[p],encoding="utf8",newline="\n")
            print("E-045 reconciled "+p,flush=True)
    for p in sorted(expected):
        (root/p).unlink()
    print("E-045 nine rejected hunks resolved by explicit semantic edits or already satisfied",flush=True)
    print("E-045 SOURCE ONLY; compiler, synthetic tests and physical RTX5090 still REQUIRED",flush=True)

if __name__=="__main__":
    if len(sys.argv)!=2:
        raise SystemExit("usage: e045-reconcile-pr2628.py <source-worktree>")
    main(Path(sys.argv[1]))
