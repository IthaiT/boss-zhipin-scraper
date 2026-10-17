#!/usr/bin/env bash
# Package the boss-zhipin-scraper skill for ClawHub publishing.
#
# Usage:
#   scripts/package-skill.sh              # stage current version -> dist/
#   scripts/package-skill.sh bump         # bump patch version (SKILL.md + boss_cdp_raw.py), then stage
#   scripts/package-skill.sh bump 2.4.0   # stage with an explicit version
#
# The staged folder is what ClawHub publishes: SKILL.md, scripts/, data/,
# LICENSE, README.md. Everything else (repo meta, tests, venv) stays out.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$REPO_ROOT/dist"
SKILL_MD="$REPO_ROOT/SKILL.md"
RAW_PY="$REPO_ROOT/scripts/boss_cdp_raw.py"

current_version() {
  sed -n 's/^  version: "\(.*\)"/\1/p' "$SKILL_MD" | head -n1
}

version_in_raw_py() {
  grep -m1 '__version__' "$RAW_PY" | sed 's/.*"\(.*\)".*/\1/'
}

bump_patch() {
  local ver="$1"
  local major minor
  major="${ver%%.*}"
  minor="${ver#*.}"; minor="${minor%%.*}"
  local patch="${ver##*.}"
  echo "$major.$minor.$((patch + 1))"
}

set_version() {
  local ver="$1"
  sed -i '' "s/^  version:.*/  version: \"$ver\"/" "$SKILL_MD"
  sed -i '' "s/^__version__ = .*/__version__ = \"$ver\"/" "$RAW_PY"
}

MODE="${1:-pack}"

if [[ "$MODE" == "bump" ]]; then
  OLD_VER="$(current_version)"
  if [[ -n "${2:-}" ]]; then
    NEW_VER="$2"
  else
    NEW_VER="$(bump_patch "$OLD_VER")"
  fi
  set_version "$NEW_VER"
  echo "version: $OLD_VER -> $NEW_VER"
elif [[ "$MODE" != "pack" ]]; then
  echo "unknown mode: $MODE (use: pack | bump [version])" >&2
  exit 1
fi

VERSION="$(current_version)"

# Consistency gate: SKILL.md and the raw script must agree.
RAW_VER="$(version_in_raw_py)"
if [[ "$VERSION" != "$RAW_VER" ]]; then
  echo "ERROR: version mismatch SKILL.md=$VERSION vs boss_cdp_raw.py=$RAW_VER" >&2
  exit 1
fi

STAGE="$DIST_DIR/boss-zhipin-scraper-$VERSION"
rm -rf "$STAGE"
mkdir -p "$STAGE/scripts" "$STAGE/data"

cp "$SKILL_MD" "$STAGE/SKILL.md"
cp "$REPO_ROOT/scripts/boss_cdp_raw.py" "$STAGE/scripts/"
cp "$REPO_ROOT/scripts/job_summary.py" "$STAGE/scripts/"
cp "$REPO_ROOT/data/city_codes.json" "$STAGE/data/"
cp "$REPO_ROOT/LICENSE" "$STAGE/LICENSE" 2>/dev/null || true
cp "$REPO_ROOT/README.md" "$STAGE/README.md"

# Post-stage validation: referenced files must exist, no junk inside.
for ref in scripts/boss_cdp_raw.py scripts/job_summary.py data/city_codes.json; do
  if [[ ! -f "$STAGE/$ref" ]]; then
    echo "ERROR: SKILL.md references $ref but it is missing from the stage" >&2
    exit 1
  fi
done

if find "$STAGE" -name "__pycache__" -o -name ".DS_Store" -o -name "*.pyc" | grep -q .; then
  echo "ERROR: junk files leaked into the stage" >&2
  exit 1
fi

echo "staged: $STAGE"
find "$STAGE" -type f | sed "s|$STAGE/||"
