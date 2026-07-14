#!/usr/bin/env bash
# One-time per-clone setup. Git config like core.hooksPath is local and does
# not survive a clone, so run this once after cloning. Safe to re-run.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Activate the tracked git hooks (the pre-push README-badge guard).
if [ -d scripts/hooks ]; then
  git config core.hooksPath scripts/hooks
  echo "✓ git hooks activated: core.hooksPath = scripts/hooks"
fi
