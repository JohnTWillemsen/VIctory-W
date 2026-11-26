#!/usr/bin/env bash
# Fast source-only integrity guard. This checks structure and local links, NOT factual truth.
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
  docs/agents/RESTART_TEST_PROTOCOL.md scripts/test-agent-restarts.sh
  docs/architecture.md docs/asset-policy.md rust-toolchain.toml
)
for file in "${required[@]}"; do
  if [[ ! -s "$file" ]]; then
    echo "ERROR: required document missing or empty: $file" >&2
    exit 1
  fi
done

anchors=(
  "AGENTS.md|docs/agents/README.md"
  "AGENTS.md|docs/agents/CURRENT_STATE.md"
  "AGENTS.md|GAMEPLAY_OBSERVED"
  "AGENTS.md|external content as untrusted"
  "docs/agents/README.md|TASK_QUEUE.md"
  "docs/agents/CURRENT_STATE.md|NOT_RUN"
  "docs/agents/EVIDENCE_LOG.md|E-001"
  "docs/agents/DECISIONS.md|D-001"
  "docs/agents/WORKFLOW.md|No direct"
  "docs/agents/TASK_QUEUE.md|live open PRs"
)
for pair in "${anchors[@]}"; do
  file="${pair%%|*}"
  key="${pair#*|}"
  if ! grep -Fiq -- "$key" "$file"; then
    echo "ERROR: missing required anchor '$key' in $file" >&2
    exit 1
  fi
done

# Validate relative Markdown targets. External URLs and same-page anchors are
# deliberately outside this simple offline check. GNU realpath is on ubuntu-latest.
link_count=0
for file in "${required[@]}"; do
  [[ "$file" == *.md ]] || continue
  while IFS= read -r markup; do
    target="${markup#](}"
    target="${target%)}"
    target="${target%%#*}"
    case "$target" in
      ""|http://*|https://*|mailto:*|\#*) continue ;;
    esac
    if [[ "$target" == /* ]]; then
      echo "ERROR: root-absolute Markdown link in $file: $target" >&2
      exit 1
    fi
    resolved="$(realpath -m --relative-to=. "$(dirname "$file")/$target")"
    if [[ "$resolved" == .. || "$resolved" == ../* || ! -e "$resolved" ]]; then
      echo "ERROR: broken/outside-repository Markdown link: $file -> $target ($resolved)" >&2
      exit 1
    fi
    link_count=$((link_count + 1))
  done < <(grep -oE '\]\([^)]*\)' "$file" || true)
done

echo "Agent docs: required files and anchors present; $link_count relative links resolve."
echo "NOTE: This is a structure check, NOT verification of GitHub state, CI, GPU, or gameplay."
