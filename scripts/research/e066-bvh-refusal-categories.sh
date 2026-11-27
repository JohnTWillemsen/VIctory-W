#!/usr/bin/env bash
# E-066: opt-in, category-only BVH builder refusal diagnostics.
# Public-source disposable six-PR reconstruction; no title data or shader IDs.
# Never changes pipeline make, all_made or dispatch holdback decisions.
set -euo pipefail
[[ "$#" == 1 ]] || { echo "usage: e066-bvh-refusal-categories.sh <public-source-root>" >&2; exit 66; }
python - "$1" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve(strict=True)
make = root / "crates/victory-gpu/src/pipeline/make.rs"
builder = root / "crates/victory-gpu/src/pipeline/builder.rs"
old_make = make.read_text(encoding="utf-8")
old_builder = builder.read_text(encoding="utf-8")

make_anchor = """pub(crate) fn state(p: &Pending) -> Option<bool> {
    p.made.get().map(Option::is_some)
}"""

make_new = make_anchor + """

/// E-066: categorize only a completed refusal, without printing its shader
/// hash, title address, pipeline key or any other game-derived identifier.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum E066Refusal {
    ShaderTranslation,
    HostPipeline,
}

pub(crate) fn e066_refusal_category(p: &Pending) -> Option<E066Refusal> {
    // None is pending; Some(Some(_)) is made. Neither is a refusal.
    if !matches!(p.made.get(), Some(None)) {
        return None;
    }
    if p.shaders
        .iter()
        .any(|s| matches!(s.translated.get(), Some(None)))
    {
        Some(E066Refusal::ShaderTranslation)
    } else {
        Some(E066Refusal::HostPipeline)
    }
}"""

builder_anchor = """        );
    }
    *decided = (frame, open);
    open
}"""

builder_new = """        );
        // E-066 is strictly opt-in and only runs when the existing safety
        // decision changes or is first reported. No pipeline IDs or hashes
        // from the title are emitted, only broad count categories.
        if !open && std::env::var("VICTORY_BVH_REFUSAL_COUNTS").as_deref() == Ok("1") {
            let pipelines = PIPELINES.lock().unwrap_or_else(|e| e.into_inner());
            let (mut shader_translation, mut host_pipeline, mut pending) = (0, 0, 0);
            for p in pipelines.iter().filter_map(|n| n.pipeline.upgrade()) {
                match make::e066_refusal_category(&p) {
                    Some(make::E066Refusal::ShaderTranslation) => shader_translation += 1,
                    Some(make::E066Refusal::HostPipeline) => host_pipeline += 1,
                    None if make::state(&p).is_none() => pending += 1,
                    None => {}
                }
            }
            tracing::info!(
                frame,
                shader_translation,
                host_pipeline,
                pending,
                "BVH builder unavailable pipeline categories (anonymous)"
            );
        }
    }
    *decided = (frame, open);
    open
}"""

tests = """
#[cfg(test)]
mod e066_refusal_category_tests {
    use super::{e066_refusal_category as category, E066Refusal, Pending};
    use std::sync::Arc;

    #[test]
    fn distinguishes_pending_and_host_pipeline_refusal() {
        let pending = Pending::new(
            Vec::new(),
            None,
            #[cfg(feature = "diagnostics")]
            &[],
        );
        assert_eq!(category(&pending), None, "not built is not refused");
        assert!(pending.made.set(None).is_ok());
        assert_eq!(category(&pending), Some(E066Refusal::HostPipeline));
    }

    #[test]
    fn identifies_failed_translation_without_a_shader_identifier() {
        let shader = Arc::new(super::Shader::new("compute", b"synthetic E066 only"));
        assert!(shader.translated.set(None).is_ok());
        let pending = Pending::new(
            vec![shader],
            None,
            #[cfg(feature = "diagnostics")]
            &[],
        );
        assert!(pending.made.set(None).is_ok());
        assert_eq!(category(&pending), Some(E066Refusal::ShaderTranslation));
    }
}
"""
for label, value, needle in (
    ("single make::state definition", old_make, make_anchor),
    ("single builder::runs log tail", old_builder, builder_anchor)
):
    n = value.count(needle)
    if n != 1:
        raise ValueError(f"E-066 {label} expected once; got {n}; no edits")
if "e066_refusal_category" in old_make or "VICTORY_BVH_REFUSAL_COUNTS" in old_builder:
    raise ValueError("E-066 already present; refusing duplicate")
new_make = old_make.replace(make_anchor, make_new, 1).rstrip("\n") + "\n" + tests
new_builder = old_builder.replace(builder_anchor, builder_new, 1)
# The only writes occur once BOTH independent preimages have been validated.
make.write_text(new_make, encoding="utf-8", newline="\n")
builder.write_text(new_builder, encoding="utf-8", newline="\n")
print("E-066 applied: anonymous builder pipeline categories; holdback untouched.")
print("E-066 output opt-in: VICTORY_BVH_REFUSAL_COUNTS=1; NO title data logged by this patch.")
PY
