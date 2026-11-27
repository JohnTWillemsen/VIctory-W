#!/usr/bin/env python3
"""E083 public-source-only multi-wave barrier rendezvous eligibility MODEL.

NOT integrated in VIctory shader lowering. Returns "synthetic ... only"; real
compiler would need group-uniform predicate proof and static site attribution.
Never executes shaders, GPU code, title content or title files.
"""
from __future__ import annotations
from dataclasses import dataclass
from enum import Enum
from typing import Mapping


class PredicateScope(Enum):
    CONSTANT = "constant"
    GROUP = "proven_group_uniform"
    WAVE = "wave_uniform_only"
    LANE = "lane_divergent"
    UNKNOWN = "unknown"


class EdgeKind(Enum):
    JUMP = "jump"
    BRANCH = "branch"
    RETURN = "return"
    INDIRECT = "indirect"


@dataclass(frozen=True)
class Block:
    name: str
    barrier_sites: tuple[str, ...]
    edge: EdgeKind
    successors: tuple[str, ...] = ()
    predicate: PredicateScope = PredicateScope.UNKNOWN
    guarded_barriers: bool = False
    has_lane_early_exit: bool = False


@dataclass(frozen=True)
class Plan:
    eligible: bool
    reason: str
    barrier_sites: tuple[str, ...] = ()


def analyse_group_safety(
    blocks: Mapping[str, Block],
    *,
    entry: str,
    threads: int,
    host_wave: int,
    guest_wave: int,
) -> Plan:
    """Pure synthetic proof obligations; NOT runtime shader eligibility.

    Workgroup-uniform != AMD wave-uniform when group spans several Wave64s.
    Cycles, lane early exits and guarded barrier call sites fail closed.
    Group provenance tags in model inputs are NOT derived from a real ISA.
    """
    def no(reason: str) -> Plan:
        return Plan(False, reason)

    if guest_wave != 64 or host_wave != 32:
        return no("unsupported_wave_width")
    if threads < 128 or threads > 1024 or threads % 64 != 0:
        return no("unsupported_group_size")
    if entry not in blocks or not blocks:
        return no("missing_entry")
    if any(k != v.name or not k for k, v in blocks.items()):
        return no("inconsistent_block_identity")
    if any(not site or not isinstance(site, str) for b in blocks.values() for site in b.barrier_sites):
        return no("missing_static_barrier_site")

    owner: dict[str, str] = {}
    for block in blocks.values():
        if len(set(block.barrier_sites)) != len(block.barrier_sites):
            return no("duplicate_barrier_site")
        for site in block.barrier_sites:
            if site in owner:
                return no("duplicate_barrier_site")
            owner[site] = block.name

    visiting: set[str] = set()
    visited: set[str] = set()
    ordered: list[str] = []
    terminals = 0

    def visit(name: str) -> str | None:
        nonlocal terminals
        if name in visiting:
            return "cycle_or_unproved_loop"
        if name in visited:
            return None
        b = blocks.get(name)
        if b is None:
            return "missing_target"
        if b.guarded_barriers or b.has_lane_early_exit:
            return "guarded_barrier_or_lane_exit"
        if b.edge == EdgeKind.INDIRECT:
            return "indirect_jump"
        if b.edge == EdgeKind.RETURN:
            if b.successors:
                return "return_has_successors"
            terminals += 1
        elif b.edge == EdgeKind.JUMP:
            if len(b.successors) != 1:
                return "invalid_jump"
        elif b.edge == EdgeKind.BRANCH:
            if len(b.successors) != 2:
                return "invalid_branch"
            if b.predicate not in (PredicateScope.CONSTANT, PredicateScope.GROUP):
                return "branch_not_proven_workgroup_uniform"
        else:
            return "unknown_edge"
        visiting.add(name)
        ordered.extend(b.barrier_sites)
        for target in b.successors:
            fail = visit(target)
            if fail:
                return fail
        visiting.remove(name)
        visited.add(name)
        return None

    fail = visit(entry)
    if fail:
        return no(fail)
    if visited != set(blocks):
        return no("unreachable_or_unsupported_blocks")
    if terminals != 1:
        return no("ambiguous_group_exit")
    if not ordered:
        return no("no_barrier_site_to_verify")
    return Plan(True, "synthetic_static_obligations_satisfied_only", tuple(ordered))


def verify_observed_rendezvous(
    *, threads: int, host_wave: int, traces: Mapping[int, tuple[str, ...]]
) -> Plan:
    """Adversarial synthetic trace oracle; does NOT inspect actual DXIL."""
    if threads < 128 or threads > 1024 or threads % 64 or host_wave != 32:
        return Plan(False, "unsupported_group_shape")
    expected = threads // host_wave
    if set(traces) != set(range(expected)):
        return Plan(False, "missing_or_partial_host_wave")
    if any(not isinstance(v, tuple) for v in traces.values()):
        return Plan(False, "invalid_trace")
    first = traces[0]
    if not first:
        return Plan(False, "empty_barrier_trace")
    if any(not isinstance(s, str) or not s for s in first):
        return Plan(False, "missing_static_site")
    for wave in range(1, expected):
        sequence = traces[wave]
        if len(sequence) != len(first):
            return Plan(False, "different_barrier_epoch_count")
        if sequence != first:
            return Plan(False, "same_epoch_different_static_call_site")
    return Plan(True, "synthetic_site_and_epoch_sequences_match", first)
