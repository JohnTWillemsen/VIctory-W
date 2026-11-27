"""E083 purely fictional group/warp traces; no console or title data."""
import unittest
from e083_multiwave_barrier_model import (
    Block, EdgeKind as E, PredicateScope as P,
    analyse_group_safety as analyse,
    verify_observed_rendezvous as verify,
)


class StaticEligibility(unittest.TestCase):
    def linear(self, threads=128):
        return analyse({"entry": Block("entry", ("before_write", "after_read"), E.RETURN)},
                       entry="entry", threads=threads, host_wave=32, guest_wave=64)

    def test_group_128_256_1024_straight_line_only(self):
        for n in (128, 256, 1024):
            with self.subTest(n=n):
                self.assertTrue(self.linear(n).eligible)

    def test_unsupported_64_96_129_1025(self):
        for n in (64, 96, 129, 1025):
            with self.subTest(n=n):
                self.assertFalse(self.linear(n).eligible)

    def test_incompatible_host_and_guest_waves(self):
        b = {"entry": Block("entry", ("B",), E.RETURN)}
        for host, guest in ((64, 64), (16, 64), (32, 32)):
            self.assertFalse(analyse(b, entry="entry", threads=128,
                                     host_wave=host, guest_wave=guest).eligible)

    def test_wave_uniform_is_not_workgroup_uniform(self):
        for scope in (P.WAVE, P.LANE, P.UNKNOWN):
            b = {"root": Block("root", ("B",), E.BRANCH, ("yes", "no"), scope),
                 "yes": Block("yes", (), E.JUMP, ("end",)),
                 "no": Block("no", (), E.JUMP, ("end",)),
                 "end": Block("end", ("C",), E.RETURN)}
            self.assertEqual(analyse(b, entry="root", threads=128,
                                     host_wave=32, guest_wave=64).reason,
                             "branch_not_proven_workgroup_uniform")

    def test_group_uniform_branch_is_synthetic_only(self):
        b = {"root": Block("root", ("A",), E.BRANCH, ("yes", "no"), P.GROUP),
             "yes": Block("yes", (), E.JUMP, ("end",)),
             "no": Block("no", (), E.JUMP, ("end",)),
             "end": Block("end", ("B",), E.RETURN)}
        p = analyse(b, entry="root", threads=128, host_wave=32, guest_wave=64)
        self.assertTrue(p.eligible)
        self.assertIn("only", p.reason)

    def test_group_uniform_loop_still_rejected(self):
        b = {"root": Block("root", ("B",), E.BRANCH, ("root", "end"), P.GROUP),
             "end": Block("end", (), E.RETURN)}
        self.assertEqual(analyse(b, entry="root", threads=128,
                                 host_wave=32, guest_wave=64).reason,
                         "cycle_or_unproved_loop")

    def test_indirect_guarded_and_lane_exit_rejected(self):
        for b in (Block("entry", ("B",), E.INDIRECT),
                  Block("entry", ("B",), E.RETURN, has_lane_early_exit=True),
                  Block("entry", ("B",), E.RETURN, guarded_barriers=True)):
            self.assertFalse(analyse({"entry": b}, entry="entry", threads=128,
                                     host_wave=32, guest_wave=64).eligible)

    def test_missing_unreachable_and_ambiguous_exits_rejected(self):
        cases = [
            {"root": Block("root", ("B",), E.JUMP, ("missing",))},
            {"root": Block("root", ("B",), E.RETURN),
             "orphan": Block("orphan", (), E.RETURN)},
            {"root": Block("root", (), E.BRANCH, ("yes", "no"), P.GROUP),
             "yes": Block("yes", ("B",), E.RETURN),
             "no": Block("no", ("C",), E.RETURN)},
        ]
        for b in cases:
            self.assertFalse(analyse(b, entry="root", threads=128,
                                     host_wave=32, guest_wave=64).eligible)

    def test_duplicate_static_site_identity_rejected(self):
        b = {"root": Block("root", ("B",), E.JUMP, ("end",)),
             "end": Block("end", ("B",), E.RETURN)}
        self.assertEqual(analyse(b, entry="root", threads=128,
                                 host_wave=32, guest_wave=64).reason,
                         "duplicate_barrier_site")

    def test_empty_barrier_model_not_a_proof(self):
        self.assertFalse(analyse({"root": Block("root", (), E.RETURN)},
                                 entry="root", threads=128, host_wave=32,
                                 guest_wave=64).eligible)


class DynamicTraceOracle(unittest.TestCase):
    def test_all_four_host_waves_same_site_and_epoch(self):
        p = verify(threads=128, host_wave=32,
                   traces={i: ("write", "read", "leave") for i in range(4)})
        self.assertTrue(p.eligible)

    def test_same_barrier_count_different_call_sites_is_invalid(self):
        p = verify(threads=128, host_wave=32,
                   traces={0: ("exchange", "drain"), 1: ("exchange", "drain"),
                           2: ("drain", "exchange"), 3: ("drain", "exchange")})
        self.assertEqual(p.reason, "same_epoch_different_static_call_site")

    def test_extra_barrier_in_one_host_wave_is_invalid(self):
        p = verify(threads=128, host_wave=32,
                   traces={0: ("B",), 1: ("B",), 2: ("B", "B"), 3: ("B",)})
        self.assertEqual(p.reason, "different_barrier_epoch_count")

    def test_missing_host_wave_is_invalid(self):
        p = verify(threads=128, host_wave=32,
                   traces={0: ("B",), 1: ("B",), 2: ("B",)})
        self.assertEqual(p.reason, "missing_or_partial_host_wave")

    def test_up_to_1024_threads_32_host_waves_same_sites(self):
        self.assertTrue(verify(threads=1024, host_wave=32,
                               traces={i: ("B0", "B1") for i in range(32)}).eligible)

    def test_empty_barrier_sequence_and_bad_shape_are_invalid(self):
        self.assertFalse(verify(threads=128, host_wave=32,
                                traces={i: () for i in range(4)}).eligible)
        self.assertFalse(verify(threads=96, host_wave=32,
                                traces={i: ("B",) for i in range(3)}).eligible)


if __name__ == "__main__":
    unittest.main()
