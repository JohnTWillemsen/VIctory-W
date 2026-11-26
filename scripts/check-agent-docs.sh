#!/usr/bin/env bash
# Fast, source-only integrity guard. It cannot establish truth or gameplay success.
set -euo pipefail
required=(
  AGENTS.md CLAUDE.md .github/copilot-instructions.md
  .github/pull_request_template.md
  docs/agents/README.md docs/agents/CURRENT_STATE.md
  docs/agents/ROADMAP.md docs/agents/WORKFLOW.md
  docs/agents/RESEARCH_PROTOCOL.md docs/agents/TESTING.md
  docs/agents/EVIDENCE_LOG.md docs/agents/DECISIONS.md
  docs/agents/UPSTREAM_TRACKER.md docs/agents/TASK_QUEUE.md
  docs/agents/ARCHITECTURE_INDEX.md docs/agents/LEGACY_CONTEXT.md
  docs/agents/EXPERIMENT_TEMPLATE.md docs/agents/NEW_SESSION_PROMPT.md
  docs/architecture.md docs/asset-policy.md rust-toolchain.toml
)
for file in "${required[@]}"; do
  if [[ ! -s "$file" ]]; then
    echo "ERROR: required document missing or empty: $file" >&2
    exit 1
  fi
done
for pair in   "AGENTS.md|docs/agents/README.md"   "AGENTS.md|docs/agents/CURRENT_STATE.md"   "docs/agents/README.md|TASK_QUEUE.md"   "docs/agents/CURRENT_STATE.md|NOT_RUN"   "docs/agents/EVIDENCE_LOG.md|E-001"   "docs/agents/DECISIONS.md|D-001"   "docs/agents/WORKFLOW.md|No direct"; do
  file="${pair%%|*}"
  key="${pair#*|}"
  if ! grep -Fiq -- "$key" "$file"; then
    echo "ERROR: missing required anchor '$key' in $file" >&2
    exit 1
  fi
done
# Only verify policy structure. No source-independent script can fact-check narrative claims.
echo "Agent documentation integrity checks passed (not a CI, GPU, or gameplay test)."
