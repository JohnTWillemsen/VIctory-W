#!/usr/bin/env bash
# E-074: diagnostic-only, anonymous BVH shader translation reason histogram.
# Disposable six-PR+E065+E066 public-source reconstruction only.
# No shader IDs/errors/path content is logged by this patch, no bypass of BVH gate.
set -euo pipefail
[[ "$#" == 1 ]] || { echo "usage: e074-bvh-shader-reasons.sh <public-source-root>" >&2; exit 74; }
python - "$1" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1]).resolve(strict=True)
pipeline = root / "crates/victory-gpu/src/pipeline.rs"
make = root / "crates/victory-gpu/src/pipeline/make.rs"
builder = root / "crates/victory-gpu/src/pipeline/builder.rs"
original = {p: p.read_text(encoding="utf-8") for p in (pipeline, make, builder)}
changed = dict(original)

def exact(p, old, new, description):
    count = changed[p].count(old)
    if count != 1:
        raise ValueError(f"E-074 {description} exact preimage expected 1, found {count}; no files written")
    changed[p] = changed[p].replace(old, new, 1)

exact(pipeline,
    """    #[cfg(windows)]
    translated: OnceLock<Option<Translated>>,
}""",
    """    #[cfg(windows)]
    translated: OnceLock<Option<Translated>>,
    /// E-074 optional diagnostic-only, anonymous error class (not raw text).
    #[cfg(windows)]
    e074_reason: OnceLock<E074Reason>,
}""",
    "Shader struct field")

reason = """/// E-074: broad translator failure class. No game-derived shader key or
/// source error string is stored; categories only, after original failure.
#[cfg(windows)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum E074Reason {
    LargeWaveGroup,
    ImplicitDerivative,
    CrossHalfLds,
    LaneMaskData,
    Other,
}

#[cfg(windows)]
fn e074_classify_error(error: &str) -> E074Reason {
    let lower = error.to_ascii_lowercase();
    if lower.contains("group of more than 64 threads") {
        E074Reason::LargeWaveGroup
    } else if lower.contains("implicit-derivative") {
        E074Reason::ImplicitDerivative
    } else if lower.contains("lane mask read as data") {
        E074Reason::LaneMaskData
    } else if lower.contains("lds")
        || lower.contains("whole-wave")
        || lower.contains("ds_permute")
        || lower.contains("cross") && lower.contains("half")
    {
        E074Reason::CrossHalfLds
    } else {
        E074Reason::Other
    }
}

"""
exact(pipeline,
      "impl std::fmt::Debug for Shader {",
      reason + "impl std::fmt::Debug for Shader {",
      "enum insertion")
exact(pipeline,
      """            translated: OnceLock::new(),
        }
    }""",
      """            translated: OnceLock::new(),
            #[cfg(windows)]
            e074_reason: OnceLock::new(),
        }
    }""",
      "Shader constructor")
exact(pipeline,
      """                let (done, cached) = translate(&self.container);
                let ms = started.elapsed().as_millis() as u64;""",
      """                let (done, cached) = translate(&self.container);
                // Only a broad in-memory enum; the existing warning may log
                // the original error, but E-074 itself never publishes it.
                if let Err(ref error) = done {
                    let _ = self.e074_reason.set(e074_classify_error(error));
                }
                let ms = started.elapsed().as_millis() as u64;""",
      "translated error reason classification")
# Account for a pre-existing, diagnostics-gated synthetic test with a struct literal.
exact(make,
      """            translated: OnceLock::new(),
        });
        let cold = Arc::new(Pending::new""",
      """            translated: OnceLock::new(),
            e074_reason: OnceLock::new(),
        });
        let cold = Arc::new(Pending::new""",
      "diagnostics-mode struct literal")

make_anchor = """pub(crate) fn e066_refusal_category(p: &Pending) -> Option<E066Refusal> {"""
if make_anchor not in changed[make]:
    raise ValueError("E-074 requires previous E066 classifier; no files written")
helper = """/// E-074: one anonymous class per already-refused builder pipeline.
pub(crate) fn e074_first_shader_failure(p: &Pending) -> Option<super::E074Reason> {
    if e066_refusal_category(p) != Some(E066Refusal::ShaderTranslation) {
        return None;
    }
    // Translation already completed; this does NOT translate a shader or
    // change the host's attempt to make a pipeline.
    Some(
        p.shaders
            .iter()
            .filter(|s| matches!(s.translated.get(), Some(None)))
            .find_map(|s| s.e074_reason.get().copied())
            .unwrap_or(super::E074Reason::Other),
    )
}

"""
exact(make,make_anchor,helper+make_anchor,"E066 classifier anchor")

builder_anchor = """                "BVH builder unavailable pipeline categories (anonymous)"
            );
        }
    }
    *decided = (frame, open);
    open
}"""
builder_new = """                "BVH builder unavailable pipeline categories (anonymous)"
            );
            if std::env::var("VICTORY_BVH_TRANSLATION_REASONS").as_deref() == Ok("1") {
                let (mut large_group, mut implicit_sample, mut cross_half_lds, mut mask_data, mut other) =
                    (0, 0, 0, 0, 0);
                for p in pipelines.iter().filter_map(|n| n.pipeline.upgrade()) {
                    match make::e074_first_shader_failure(&p) {
                        Some(super::E074Reason::LargeWaveGroup) => large_group += 1,
                        Some(super::E074Reason::ImplicitDerivative) => implicit_sample += 1,
                        Some(super::E074Reason::CrossHalfLds) => cross_half_lds += 1,
                        Some(super::E074Reason::LaneMaskData) => mask_data += 1,
                        Some(super::E074Reason::Other) => other += 1,
                        None => {}
                    }
                }
                tracing::info!(
                    frame,
                    large_group,
                    implicit_sample,
                    cross_half_lds,
                    mask_data,
                    other,
                    "BVH shader translator failure classes (anonymous)"
                );
            }
        }
    }
    *decided = (frame, open);
    open
}"""
exact(builder,builder_anchor,builder_new,"E066 builder log insertion")

test_pipeline = """
#[cfg(all(test, windows))]
mod e074_shader_reason_tests {
    use super::{e074_classify_error as classify, E074Reason as R};

    #[test]
    fn classifies_known_public_emitter_rejections_without_identifiers() {
        assert_eq!(classify("console wave64 lanes in a group of more than 64 threads on a host without 64-lane waves"), R::LargeWaveGroup);
        assert_eq!(classify("an implicit-derivative sample in the console flow"), R::ImplicitDerivative);
        assert_eq!(classify("a wave64 group sharing LDS without barriers"), R::CrossHalfLds);
        assert_eq!(classify("ds_permute across the halves"), R::CrossHalfLds);
        assert_eq!(classify("a lane mask read as data"), R::LaneMaskData);
    }

    #[test]
    fn unknown_errors_remain_unknown_instead_of_guessing_wave64() {
        assert_eq!(classify("synthetic unrelated source problem"), R::Other);
        assert_eq!(classify(""), R::Other);
    }
}
"""
test_make = """
#[cfg(all(test, windows))]
mod e074_builder_reason_tests {
    use super::*;
    use crate::pipeline::E074Reason;

    #[test]
    fn one_refused_pipeline_gets_only_one_anonymous_shader_class() {
        let shader = Arc::new(Shader::new("compute", b"synthetic public test only"));
        let _ = shader.translated.set(None);
        let _ = shader.e074_reason.set(E074Reason::LargeWaveGroup);
        let pending = Pending::new(
            vec![shader],
            None,
            #[cfg(feature = "diagnostics")]
            &[],
        );
        let _ = pending.made.set(None);
        assert_eq!(e074_first_shader_failure(&pending), Some(E074Reason::LargeWaveGroup));
    }

    #[test]
    fn no_failed_shader_or_missing_reason_is_not_a_false_specific_class() {
        let host_refusal = Pending::new(
            Vec::new(),
            None,
            #[cfg(feature = "diagnostics")]
            &[],
        );
        let _ = host_refusal.made.set(None);
        assert_eq!(e074_first_shader_failure(&host_refusal), None);
        let shader = Arc::new(Shader::new("compute", b"fictional unclassified error"));
        let _ = shader.translated.set(None);
        let failed = Pending::new(
            vec![shader],
            None,
            #[cfg(feature = "diagnostics")]
            &[],
        );
        let _ = failed.made.set(None);
        assert_eq!(e074_first_shader_failure(&failed), Some(E074Reason::Other));
    }
}
"""
for path,extra in ((pipeline,test_pipeline),(make,test_make)):
    if "mod e074_" in changed[path]:
        raise ValueError("E-074 test module already exists")
    changed[path] = changed[path].rstrip("\n") + "\n" + extra
if all(changed[p] != original[p] for p in original):
    for path in (pipeline, make, builder):
        path.write_text(changed[path], encoding="utf-8", newline="\n")
else:
    raise ValueError("E-074 missing one or more expected edits; aborting all")
print("E-074 applied in disposable source only: translation reason enum and BVH anonymous histogram.")
print("E-074 BVH safety gate, pipeline creation, shaders, executable source inputs unchanged.")
PY
