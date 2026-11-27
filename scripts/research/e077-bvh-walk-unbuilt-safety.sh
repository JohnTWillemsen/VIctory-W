#!/usr/bin/env bash
# E-077: reconciled, opt-in and fail-closed safety port of the public final
# change in upstream #2311 (481a9ae). The literal upstream patch conflicts
# with the independently reconciled E045 six-PR source; DO NOT use ours/theirs.
# This narrower port preserves the original held_back bool API and its tests.
# It blocks BVH ray walkers until builder structures have actually been built.
set -euo pipefail
[[ "$#" == 1 ]] || { echo "usage: e077-bvh-walk-unbuilt-safety.sh <disposable-source-worktree>" >&2; exit 77; }
cd "$1"
[[ -f Cargo.lock && -f crates/victory-gpu/src/pipeline/builder.rs ]] ||
    { echo "E-077 wrong source worktree" >&2; exit 77; }
upstream="481a9aec8eaf9938fe8ce8ae9451b78cfd6b0920"
parent="60632d3f0fcb9e916a2ad22be300e5f71c4a2b49"
if ! git cat-file -e "$upstream^{commit}" 2>/dev/null; then
    git fetch --quiet origin "$upstream"
fi
[[ "$(git rev-parse "$upstream")" == "$upstream" && "$(git rev-parse "$upstream^")" == "$parent" ]] ||
    { echo "E-077 reviewed upstream commit/parent mismatch" >&2; exit 77; }
expect="$(printf '%s\n' 'crates/victory-gpu/src/draw.rs' 'crates/victory-gpu/src/pipeline.rs' 'crates/victory-gpu/src/pipeline/builder.rs')"
actual="$(git diff --name-only "$parent" "$upstream")"
[[ "$actual" == "$expect" ]] ||
    { echo "E-077 upstream changed-file scope mismatch" >&2; exit 77; }

python - "$PWD" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve(strict=True)
pipeline = root / "crates/victory-gpu/src/pipeline.rs"
builder = root / "crates/victory-gpu/src/pipeline/builder.rs"
old = {p: p.read_text(encoding="utf-8") for p in (pipeline, builder)}
new = dict(old)

def replace(path, anchor, replacement, label):
    count = new[path].count(anchor)
    if count != 1:
        raise RuntimeError(f"E-077 {label}: expected unique source preimage, found {count}; no writes")
    new[path] = new[path].replace(anchor, replacement, 1)

replace(pipeline,
    """    #[cfg(windows)]
    builder: bool,
}
const _: () = assert!(offset_of!(Pipeline, packet) == 0x10);""",
    """    #[cfg(windows)]
    builder: bool,
    /// Whether one of its shaders walks an acceleration structure.
    #[cfg(windows)]
    walks_bvh: bool,
}
const _: () = assert!(offset_of!(Pipeline, packet) == 0x10);""",
    "Pipeline layout invariant")

replace(pipeline,
    """pub(crate) fn held_back(this: This) -> bool {
    !this.is_null() && pipeline(this).builder && !builder::runs()
}""",
    """pub(crate) fn held_back(this: This) -> bool {
    if this.is_null() {
        return false;
    }
    let p = pipeline(this);
    // Preserve the old all-made builder decision and the bool return type.
    (p.builder && !builder::runs()) || (p.walks_bvh && !builder::built())
}

/// True only for decoded, published GFX10 BVH ray-intersection instructions.
/// Does not inspect shader IDs or write any private title content.
#[cfg(windows)]
fn e077_code_walks_bvh(code: &[u8]) -> bool {
    victory_shader::gfx10::decode(code).is_ok_and(|insts| {
        insts.iter().any(|i| {
            i.name().is_some_and(|name| name.starts_with("image_bvh"))
        })
    })
}

#[cfg(windows)]
fn e077_walks_bvh(container: &[u8]) -> bool {
    use victory_shader::{Container, FourCC};
    let Ok(c) = Container::parse(container) else {
        return false;
    };
    c.part(FourCC::DXIL)
        .and_then(|part| victory_shader::native_programs(part.data).ok())
        .is_some_and(|programs| {
            programs.iter().any(|p| e077_code_walks_bvh(&p.code))
        })
}""",
    "upstream held_back bool extension and synthetic decoder")

replace(pipeline,
    """    #[cfg(windows)]
    let builder = !code.is_empty() && builder::created_by_builder(code);
    #[cfg(not(windows))]
    let _ = code;""",
    """    #[cfg(windows)]
    let builder = !code.is_empty() && builder::created_by_builder(code);
    // Compute once when the title creates the pipeline. Never decode private
    // shader content for logging or upload.
    #[cfg(windows)]
    let walks_bvh = !builder && shaders.iter().any(|s| e077_walks_bvh(&s.container));
    #[cfg(not(windows))]
    let _ = code;""",
    "pipeline creation classifier")

replace(pipeline,
    """        #[cfg(windows)]
        builder,
        shaders,
        bound: std::sync::atomic::AtomicBool::new(false),""",
    """        #[cfg(windows)]
        builder,
        #[cfg(windows)]
        walks_bvh,
        shaders,
        bound: std::sync::atomic::AtomicBool::new(false),""",
    "Pipeline initializer")

replace(builder,
    """fn image() -> Option<(usize, usize)> {
    *IMAGE.lock().unwrap_or_else(|e| e.into_inner())
}""",
    """fn image() -> Option<(usize, usize)> {
    *IMAGE.lock().unwrap_or_else(|e| e.into_inner())
}

/// E-077: an acceleration structure cannot be walked until the builder has
/// actually completed a whole frame; without this title DLL, do not gate.
static BUILT: AtomicBool = AtomicBool::new(false);
pub(crate) fn built() -> bool {
    BUILT.load(Ordering::Relaxed) || image().is_none()
}""",
    "builder initialized check")

replace(builder,
    """    *decided = (frame, open);
    open
}""",
    """    *decided = (frame, open);
    if open && !states.is_empty() && !BUILT.swap(true, Ordering::Relaxed) {
        tracing::info!(frame, "BVH builder ran whole; BVH walkers may now run");
    }
    open
}""",
    "set built only when builder has pipelines and all can run")

replace(builder,
    """    let guard = LOCK.lock().unwrap_or_else(|e| e.into_inner());
    forget_decision();
    guard
}""",
    """    let guard = LOCK.lock().unwrap_or_else(|e| e.into_inner());
    forget_decision();
    BUILT.store(false, Ordering::Relaxed);
    guard
}

/// Reset only this test module's builder mapping (never in production).
#[cfg(test)]
pub(crate) fn e077_clear_image_for_tests() {
    *IMAGE.lock().unwrap_or_else(|e| e.into_inner()) = None;
}""",
    "isolated synthetic tests reset")

if "e077_bvh_walk_safety_tests" in new[pipeline]:
    raise RuntimeError("E-077 synthetic module already present")

new[pipeline] = new[pipeline].rstrip("\n") + """
#[cfg(all(test, windows))]
mod e077_bvh_walk_safety_tests {
    use super::*;

    #[test]
    fn only_gfx10_bvh_intersect_instructions_are_walks() {
        let code = |words: &[u32]| words.iter().flat_map(|w| w.to_le_bytes()).collect::<Vec<u8>>();
        const END: u32 = 0xBF81_0000;
        let rest = 20 << 8 | 3 << 16;
        let narrow = code(&[0xF198_9F01, rest | 2, END]);
        let wide = code(&[0xF19C_9F07, rest | 2, 0x0504_030D, 0x0908_0706, 0x000C_0B0A, END]);
        assert!(e077_code_walks_bvh(&narrow));
        assert!(e077_code_walks_bvh(&wide));
        assert!(!e077_code_walks_bvh(&code(&[END])));
    }

    #[test]
    fn unbuilt_builder_blocks_walks_but_a_title_without_builder_does_not() {
        let _one = builder::test_lock();
        builder::note_title_dll("XboxBvhBuilder.dll", 0x1000, 0x1000);
        assert!(!builder::built(), "mapped builder has not run whole");
        builder::e077_clear_image_for_tests();
        assert!(builder::built(), "titles with no builder must not be blocked");
    }
}
"""
if old[pipeline] == new[pipeline] or old[builder] == new[builder]:
    raise RuntimeError("E-077 no actual source change; refusing")
# After ALL independent preimages and test checks succeed, write both.
for path in (pipeline, builder):
    path.write_text(new[path], encoding="utf-8", newline="\n")
print("E-077 reconciled: BVH walks held until whole builder run; original bool API unchanged")
print("E-077 patches only public GPU pipeline + builder, no shader or rendering changes")
PY

git diff --check
grep -Fq 'e077_bvh_walk_safety_tests' crates/victory-gpu/src/pipeline.rs ||
    { echo "E-077 synthetic tests missing" >&2; exit 77; }
grep -Fq 'BUILT.swap(true' crates/victory-gpu/src/pipeline/builder.rs ||
    { echo "E-077 BVH built interlock missing" >&2; exit 77; }
echo "E-077 source-only gate complete; tests/hosted Windows still required."
