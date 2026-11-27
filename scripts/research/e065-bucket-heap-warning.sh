#!/usr/bin/env bash
# E-065: opt-in diagnostic-only throttle of heap out-of-range warning.
# Does NOT remap a descriptor, increase host heap capacity or alter return None.
# Applies to disposable pinned public-source six-PR reconstruction only.
set -euo pipefail
[[ "$#" == 1 ]] || { echo "usage: e065-bucket-heap-warning.sh <public-source-worktree>" >&2; exit 65; }
python - "$1" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve(strict=True)
target = root / "crates/victory-gpu/src/descriptor/host.rs"
old = target.read_text(encoding="utf-8")

anchor = "pub(crate) struct HostHeap {"
helper = """// E-065 diagnostic-only rate reduction. Preserve the maximum index and the
// original out-of-range return path; log the first exceedance and crossings
// of 64-Ki-slot boundaries, rather than each new maximum in a linear scan.
fn e065_log_oob_max(previous_max: u32, index: u32) -> bool {
    const WIDTH: u32 = 65_536;
    previous_max < index
        && (previous_max == 0 || previous_max / WIDTH != index / WIDTH)
}

""" + anchor

previous = """            // Diagnostic (NVIDIA heap cap): the highest title slot past the
            // host heap seen so far.
            static HIGHEST: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(0);
            if HIGHEST.fetch_max(index, std::sync::atomic::Ordering::Relaxed) < index {
                tracing::warn!(
                    index,
                    count = self.count,
                    for_draw,
                    "title slot past the host heap"
                );
            }
            return None;"""

replacement = """            // Keep tracking the exact maximum, but only report the first
            // exceedance and each newly crossed 64-Ki-slot boundary. This
            // changes logging only: the out-of-range view remains refused.
            static HIGHEST: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(0);
            let previous = HIGHEST.fetch_max(index, std::sync::atomic::Ordering::Relaxed);
            if e065_log_oob_max(previous, index) {
                tracing::warn!(
                    index,
                    count = self.count,
                    for_draw,
                    "title slot past the host heap"
                );
            }
            return None;"""

tests = """
#[cfg(test)]
mod e065_heap_warning_tests {
    use super::e065_log_oob_max as should_log;

    #[test]
    fn first_exceedance_is_logged_and_repeated_indices_are_not() {
        assert!(should_log(0, 100));
        assert!(!should_log(100, 100));
        assert!(!should_log(101, 100));
        assert!(!should_log(100, 101));
    }

    #[test]
    fn every_crossed_slot_boundary_is_logged_once() {
        assert!(!should_log(65_533, 65_535));
        assert!(should_log(65_535, 65_536));
        assert!(!should_log(65_536, 65_537));
        assert!(should_log(131_071, 131_072));
        assert!(!should_log(u32::MAX, u32::MAX));
    }

    #[test]
    fn synthetic_linear_scan_reports_buckets_not_each_new_slot() {
        let mut max = 0;
        let mut warnings = 0;
        for index in 700_000..1_200_000 {
            let prev = max;
            max = max.max(index);
            if should_log(prev, index) {
                warnings += 1;
            }
        }
        assert!(warnings <= 10, "only the first and 64-Ki boundaries");
        assert!(warnings >= 2, "still report continuing overflow");
        assert_eq!(max, 1_199_999, "the exact tracked maximum is preserved");
    }
}
"""
for label, needle in (
    ("unique HostHeap module insertion point", anchor),
    ("exact original out-of-range warning logic", previous)
):
    n = old.count(needle)
    if n != 1:
        raise ValueError(f"E-065 {label}: expected exactly one preimage, found {n}; no edits")
if "e065_heap_warning_tests" in old:
    raise ValueError("E-065 already applied; refusing duplicate")
updated = old.replace(anchor, helper, 1).replace(previous, replacement, 1).rstrip("\n") + "\n" + tests
target.write_text(updated, encoding="utf-8", newline="\n")
print("E-065 applied to disposable source: bucketed diagnostic-only warnings.")
print("E-065 out-of-range return None and actual descriptor capacity unchanged.")
PY
