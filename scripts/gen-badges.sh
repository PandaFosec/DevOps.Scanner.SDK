#!/usr/bin/env bash
# Regenerate the README CI badges between the placeholder markers:
#   <!-- BADGES:START --> ... <!-- BADGES:END -->
#
# Emits a badge per CI target that applies to this checkout. Both are STATIC
# shields.io labels (always publicly renderable, so they never show as a broken
# image icon on the "wrong" platform) that LINK to their respective CI page:
#   * GitHub  — always, derived from the `origin` GitHub remote.
#   * Azure   — only when the org/project are configured:
#                 git config badges.azure-org      "<your-org>"
#                 git config badges.azure-project  "<your-project>"
#
# Want a LIVE pass/fail Azure badge instead of the static label? Set
#   git config badges.azure-live true
# and enable "anonymous badge access" on the Azure pipeline (otherwise it
# renders as a broken icon). GitHub live badges don't render for private repos,
# so GitHub stays a static label.
#
# Usage: scripts/gen-badges.sh [README.md]
set -euo pipefail

readme="${1:-README.md}"
[ -f "$readme" ] || { echo "no $readme" >&2; exit 1; }

gh_slug="$(git remote get-url origin 2>/dev/null | sed -E 's#.*github\.com[:/]##; s#\.git$##' || true)"
az_org="$(git config --get badges.azure-org || true)"
az_proj="$(git config --get badges.azure-project || true)"

badges=""
if [ -n "$gh_slug" ]; then
  badges+="[![CI (GitHub)](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)](https://github.com/${gh_slug}/actions/workflows/ci.yml) "
fi
if [ -n "$az_org" ] && [ -n "$az_proj" ]; then
  if [ "$(git config --get badges.azure-live || true)" = "true" ]; then
    # Live status — renders only if the pipeline has anonymous badge access.
    az_img="https://dev.azure.com/${az_org}/${az_proj}/_apis/build/status%2Fazure-pipeline-ci?branchName=master"
  else
    # Static label — always renders, links to the pipeline page.
    az_img="https://img.shields.io/badge/CI-Azure%20Pipelines-0078D7?logo=azuredevops&logoColor=white"
  fi
  badges+="[![CI (Azure)](${az_img})](https://dev.azure.com/${az_org}/${az_proj}/_build) "
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
