#!/usr/bin/env bash
# E-056: fail-closed semantic port of Belobug/VIctory-Belobug-AMD PR #449.
# Applies only to the disposable PUBLIC-source six-PR reconstructed checkout.
# Does not touch the VIctory-W main branch, title data, or game executable.
set -euo pipefail
[[ "$#" == 1 ]] || { echo "usage: e056-legal-barrier-port.sh <disposable-public-source-root>" >&2; exit 60; }
python - "$1" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve(strict=True)
target = root / "crates/victory-gpu/src/list.rs"
old = target.read_text(encoding="utf-8")
anchor = """#[cfg(windows)]
fn host_barrier"""

helper = """/// Host-legal resource state pair, or none when sanitizing makes it a no-op.
/// The title's tracked states remain unchanged; only the host barrier is normalized.
#[cfg(windows)]
fn e056_legal_barrier_states(flags: u32, before: u32, wanted: u32) -> Option<(u32, u32)> {
    let before = crate::host::legal_for(flags, before);
    let after = crate::host::legal_for(flags, wanted);
    (before != after).then_some((before, after))
}

""" + anchor

old_transition = """            let wanted = crate::host::texture_state(b.last as u32);
            let (texture, before) = list.transition(b.first, wanted)?;
            Some(Barrier {
                kind: 0,
                flags: 0,
                first: texture.as_raw().cast_const().cast(),
                second: 0xffff_ffff | (u64::from(before) << 32),
                last: u64::from(crate::host::legal_state(&texture, wanted)),
            })"""

new_transition = """            let wanted = crate::host::texture_state(b.last as u32);
            let (texture, before) = list.transition(b.first, wanted)?;
            // SAFETY: this is the live host texture supplied by HostList::transition.
            let flags = unsafe { texture.GetDesc() }.Flags.0 as u32;
            let (before_legal, after_legal) = e056_legal_barrier_states(flags, before, wanted)?;
            Some(Barrier {
                kind: 0,
                flags: 0,
                first: texture.as_raw().cast_const().cast(),
                second: 0xffff_ffff | (u64::from(before_legal) << 32),
                last: u64::from(after_legal),
            })"""

tests = """
// Synthetic tests: no game files, no GPU or driver required.
// These confirm the pure host legality decision used by host_barrier.
#[cfg(all(test, windows))]
mod e056_barrier_legalization_tests {
    use super::e056_legal_barrier_states as choose;

    #[test]
    fn strips_illegal_uav_from_before_but_keeps_allowed_rtv_after() {
        // ALLOW_RENDER_TARGET without ALLOW_UNORDERED_ACCESS.
        assert_eq!(choose(0x1, 0x8, 0x4), Some((0, 0x4)));
        assert_eq!(choose(0x1, 0x8, 0x8), None);
    }

    #[test]
    fn avoids_host_transition_when_different_guest_states_become_equal() {
        assert_eq!(choose(0, 0x8, 0), None);
        assert_eq!(choose(0x8, 0x40, 0x80), None);
        assert_eq!(choose(0x1, 0x8 | 0x4, 0x4), None);
    }

    #[test]
    fn preserves_legal_distinct_states_and_depth_permissions() {
        assert_eq!(choose(0x5, 0x8, 0x4), Some((0x8, 0x4)));
        assert_eq!(choose(0x2, 0, 0x20), Some((0, 0x20)));
        assert_eq!(choose(0x0, 0x20, 0), None);
    }

    #[test]
    fn every_emitted_pair_is_distinct_and_host_legal() {
        for flags in 0..16u32 {
            for before in 0..128u32 {
                for wanted in [0, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80] {
                    if let Some((from, to)) = choose(flags, before, wanted) {
                        assert_ne!(from, to);
                        assert_eq!(from, crate::host::legal_for(flags, from));
                        assert_eq!(to, crate::host::legal_for(flags, to));
                    }
                }
            }
        }
    }
}
"""

for name, needle in [("host barrier insertion", anchor),
                     ("host barrier old implementation", old_transition)]:
    matches = old.count(needle)
    if matches != 1:
        raise ValueError(f"E-056 {name}: expected one exact preimage; got {matches}; no file changed")
if "e056_barrier_legalization_tests" in old:
    raise ValueError("E-056 test block already present; refusing duplicate import")
revised = old.replace(anchor, helper, 1).replace(old_transition, new_transition, 1)
revised = revised.rstrip("\n") + "\n" + tests
# Transactional: this is the only source write, after every pinned precondition passed.
target.write_text(revised, encoding="utf-8", newline="\n")
print("E-056 source applied: legalize BOTH barrier states; drop sanitized no-ops.", flush=True)
print("E-056 source-only: compilation, synthetic tests and owner RTX5090 remain separate.", flush=True)
PY
