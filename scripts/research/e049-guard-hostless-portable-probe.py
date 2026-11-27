#!/usr/bin/env python3
"""E-049: guard the upstream #2628 portable-heap probe against hostless cache poisoning.

Only edits disposable, pinned public-source checkouts built by the E-045 runner.
The host-free phase must not initialize a process-wide OnceLock<bool> to false.
"""
from __future__ import annotations

from pathlib import Path
import sys

HOST_PATH = "crates/victory-gpu/src/descriptor/host.rs"

OLD_PROBE = """/// Probes the host once, before choosing a shader cache key or allocating a view heap.
pub(crate) fn portable_view_heap() -> bool {
    static PORTABLE: std::sync::OnceLock<bool> = std::sync::OnceLock::new();
    *PORTABLE.get_or_init(|| {
        host().is_some_and(|host| {
            needs_portable_heap(|count| {
                visible_heap(&host.device, D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, count).is_ok()
            })
        })
    })
}
"""

NEW_PROBE = """/// Probes the host once, before choosing a shader cache key or allocating a view heap.
/// An early hostless call may return false but must never cache that guess.
pub(crate) fn portable_view_heap() -> bool {
    static PORTABLE: std::sync::OnceLock<bool> = std::sync::OnceLock::new();
    portable_view_heap_cached(
        &PORTABLE,
        host().map(|host| {
            move |count| {
                visible_heap(&host.device, D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, count).is_ok()
            }
        }),
    )
}

/// Cache only a real device probe. Cached results remain stable after host teardown.
/// The separate shader host cache key includes this selected view-heap limit.
fn portable_view_heap_cached(
    cache: &std::sync::OnceLock<bool>,
    can_create: Option<impl FnOnce(u32) -> bool>,
) -> bool {
    if let Some(&portable) = cache.get() {
        return portable;
    }
    let Some(can_create) = can_create else {
        return false;
    };
    *cache.get_or_init(|| needs_portable_heap(can_create))
}
"""

TEST_ANCHOR = """    #[test]
    fn the_probe_selects_the_heap_layout_before_translation() {"""

NEW_TEST = """    #[test]
    fn hostless_probe_does_not_poison_portable_heap_cache() {
        // Simulate shader warm-up before a host exists, then a capped NVIDIA host.
        let portable = std::sync::OnceLock::new();
        assert!(!portable_view_heap_cached(&portable, None::<fn(u32) -> bool>));
        assert!(portable.get().is_none(), "no host must not commit a heap decision");
        assert!(portable_view_heap_cached(&portable, Some(|count| {
            assert_eq!(count, HEAP_VIEWS);
            false // full 2M heap rejected; use the portable 1M layout
        })));
        assert_eq!(portable.get(), Some(&true));
        assert!(portable_view_heap_cached(&portable, None::<fn(u32) -> bool>));
        assert!(portable_view_heap_cached(&portable, Some(|_| panic!("probed twice"))));

        // A host accepting the full heap must be cached as nonportable.
        let full = std::sync::OnceLock::new();
        assert!(!portable_view_heap_cached(&full, Some(|count| count == HEAP_VIEWS)));
        assert_eq!(full.get(), Some(&false));
        assert!(!portable_view_heap_cached(&full, None::<fn(u32) -> bool>));
    }

""" + TEST_ANCHOR

def replace_once(source: str, old: str, new: str, desc: str) -> str:
    occurrences = source.count(old)
    if occurrences != 1:
        raise ValueError(f"E-049 {desc}: expected one exact pinned preimage; found {occurrences}")
    return source.replace(old, new, 1)

def main(root: Path) -> None:
    path = root.resolve() / HOST_PATH
    original = path.read_text(encoding="utf-8")
    revised = replace_once(original, OLD_PROBE, NEW_PROBE, "portable probe")
    revised = replace_once(revised, TEST_ANCHOR, NEW_TEST, "regression test")
    # No partial write if either preimage was not exact.
    path.write_text(revised, encoding="utf-8", newline="\n")
    print("E-049 guard applied to portable heap host probe; pure hostless-to-host test added", flush=True)
    print("E-049 SOURCE_ONLY; Windows compile and unit gates still required", flush=True)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: e049-guard-hostless-portable-probe.py <disposable-source-root>")
    main(Path(sys.argv[1]))
