#!/usr/bin/env bash
# Regenerate the README CI badges between the placeholder markers:
#   <!-- BADGES:START --> ... <!-- BADGES:END -->
#
# Emits all badges on ONE line. The CI badges are STATIC shields.io labels
# (always publicly renderable, so they never show as a broken image icon on the
# "wrong" platform) that LINK to their respective CI page:
#   * GitHub  — always, derived from the `origin` GitHub remote.
#   * Azure   — only when the org/project are configured, in `.env`:
#                 AZURE_DEVOPS_ORG=<your-org>
#                 AZURE_DEVOPS_PROJECT=<your-project>
#   * Python  — version from `.env` PYTHON_VERSION, else the requires-python
#               floor in pyproject.toml.
#
# Want a LIVE pass/fail Azure badge instead of the static label? Set
#   AZURE_DEVOPS_BADGE_LIVE=true
# and enable "anonymous badge access" on the Azure pipeline (otherwise it
# renders as a broken icon). GitHub live badges don't render for private repos,
# so GitHub stays a static label.
#
# Usage: scripts/gen-badges.sh [README.md]
set -euo pipefail

readme="${1:-README.md}"
[ -f "$readme" ] || { echo "no $readme" >&2; exit 1; }

# Read KEY from .env (last assignment wins, surrounding quotes stripped). These
# are docs-tooling values, not app runtime settings — the app ignores them.
_from_env() { # $1 = key
  [ -f .env ] || return 0
  sed -n -E "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" .env | tail -n1 \
    | sed -E "s/^[\"']//; s/[\"']$//"
}

gh_slug="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github\.com[:/]##; s#\.git$##' || true)"
az_org="$(_from_env AZURE_DEVOPS_ORG)"
az_proj="$(_from_env AZURE_DEVOPS_PROJECT)"

badges=""
if [ -n "$gh_slug" ]; then
  badges+="[![CI (GitHub)](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)](https://github.com/${gh_slug}/actions/workflows/ci.yml) "
fi
if [ -n "$az_org" ] && [ -n "$az_proj" ]; then
  if [ "$(_from_env AZURE_DEVOPS_BADGE_LIVE)" = "true" ]; then
    # Live status — renders only if the pipeline has anonymous badge access.
    az_img="https://dev.azure.com/${az_org}/${az_proj}/_apis/build/status%2Fazure-pipeline-ci?branchName=master"
  else
    # Static label — always renders, links to the pipeline page.
    az_img="https://img.shields.io/badge/CI-Azure%20Pipelines-0078D7?logo=azuredevops&logoColor=white"
  fi
  badges+="[![CI (Azure)](${az_img})](https://dev.azure.com/${az_org}/${az_proj}/_build) "
fi
# Python badge — version from .env PYTHON_VERSION, else the floor of
# requires-python in pyproject.toml (root or orchestrator/ subdir).
py_ver="$(_from_env PYTHON_VERSION)"
if [ -z "$py_ver" ]; then
  for pp in pyproject.toml orchestrator/pyproject.toml; do
    [ -f "$pp" ] || continue
    py_ver="$(sed -n -E 's/.*requires-python[^0-9]*([0-9]+\.[0-9]+).*/\1/p' "$pp" | head -n1)"
    [ -n "$py_ver" ] && break
  done
fi
if [ -n "$py_ver" ]; then
  badges+="![Python](https://img.shields.io/badge/python-${py_ver}-3776AB?logo=python&logoColor=white) "
fi
badges="${badges% }"

BADGES="$badges" python3 - "$readme" <<'PY'
import os, re, sys
path = sys.argv[1]
s = open(path, encoding="utf-8").read()
block = "<!-- BADGES:START -->\n" + os.environ["BADGES"] + "\n<!-- BADGES:END -->"
if "<!-- BADGES:START -->" not in s:
    raise SystemExit("no <!-- BADGES:START --> marker in " + path)
s = re.sub(r"<!-- BADGES:START -->.*?<!-- BADGES:END -->", lambda _: block, s, flags=re.S)
open(path, "w", encoding="utf-8").write(s)
PY

echo "updated badges in $readme:"
sed -n '/BADGES:START/,/BADGES:END/p' "$readme"
