#!/usr/bin/env bash
# Cut a release locally: sync all versions -> commit -> annotated tag -> push (atomic).
# The release.yml CI then verifies the tag's manifests and opens a DRAFT GitHub release
# (you fill in the notes and Publish). The pushed tag's commit is always version-accurate.
#
# Usage: scripts/release.sh <version> [--dry-run]
#   scripts/release.sh 2026.6.9            # real release
#   scripts/release.sh 2026.6.9 --dry-run  # preview the version sync, change nothing
set -euo pipefail
shopt -s nullglob

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || {
  echo "release: cannot resolve repo root" >&2
  exit 1
}
cd "$root" || {
  echo "release: cannot cd to repo root" >&2
  exit 1
}
die() {
  printf 'release: %s\n' "$*" >&2
  exit "${2:-1}"
}

ver="${1:-}"
mode="${2:-}"
[[ -n "$ver" ]] || die "usage: scripts/release.sh <version> [--dry-run]" 2
ver="${ver#v}"
[[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version '$ver' (want N.N.N)" 2
tag="v$ver"
files=(*/.claude-plugin/plugin.json .claude-plugin/marketplace.json)
repo_slug="${RELEASE_REPO_SLUG:-HerbertGao/herbertgao-skills}"

validate_origin_remote() {
  local remote_url
  remote_url="$(git remote get-url --push origin 2>/dev/null || git remote get-url origin 2>/dev/null)" ||
    die "cannot read origin remote"
  case "$remote_url" in
  "https://github.com/$repo_slug" | "https://github.com/$repo_slug.git" | "git@github.com:$repo_slug.git" | "ssh://git@github.com/$repo_slug.git")
    ;;
  *)
    die "origin remote '$remote_url' does not match release repo '$repo_slug'; update origin or set RELEASE_REPO_SLUG"
    ;;
  esac
}

validate_versions() {
  local f got
  for f in "${files[@]}"; do
    if [[ "$f" == ".claude-plugin/marketplace.json" ]]; then
      got="$(jq -r '.metadata.version // empty' "$f")"
    else
      got="$(jq -r '.version // empty' "$f")"
    fi
    [[ "$got" == "$ver" ]] || die "$f version '$got' != requested '$ver'"
  done
}

validate_marketplaces() {
  command -v jq >/dev/null 2>&1 || die "jq not found (install jq)"

  # A Claude <plugin>/ dir absent from the marketplace
  # version-bumps, passes CI, and ships un-installable via /plugin install.
  local cmf=".claude-plugin/marketplace.json" p entry d dirs=(*/.claude-plugin/)
  # fail closed: nullglob would silently run zero checks if the layout broke
  [[ ${#dirs[@]} -gt 0 ]] || die "no Claude plugin dirs matched */.claude-plugin/ — layout/glob broke"
  for d in "${dirs[@]}"; do
    p="${d%/.claude-plugin/}"
    jq -e --arg s "./$p" '.plugins[] | select(.source == $s)' "$cmf" >/dev/null ||
      die "$cmf missing entry for $p"
  done

  # forward, Claude side: every entry must point at a real manifest whose name matches
  local csrc cname
  while IFS= read -r entry; do
    cname="$(jq -r '.name // empty' <<<"$entry")"
    csrc="$(jq -r '.source // empty' <<<"$entry")"
    [[ -n "$cname" && -n "$csrc" ]] || die "$cmf has an entry without name/source"
    [[ -f "$csrc/.claude-plugin/plugin.json" ]] ||
      die "$cmf entry '$cname' points to missing manifest: $csrc/.claude-plugin/plugin.json"
    [[ "$(jq -r '.name // empty' "$csrc/.claude-plugin/plugin.json")" == "$cname" ]] ||
      die "$csrc/.claude-plugin/plugin.json name != marketplace entry '$cname'"
  done < <(jq -c '.plugins[]' "$cmf")

  # Every Claude plugin ships at least one skill.
  for d in "${dirs[@]}"; do
    p="${d%/.claude-plugin/}"
    compgen -G "$p/skills/*/SKILL.md" >/dev/null || die "$p has no skills/*/SKILL.md — the skill itself is missing"
  done

  # The specs carry runtime strings their own evaluators match by literal. A stray
  # character there disarms a gate silently, and prose review is a bad detector for it.
  env -u SKIP_CATALOG_CHECK -u AGENCY_AGENTS scripts/check-format.py || die "format contract violated (contracts/format.json) — fix before releasing"
}

if [[ "$mode" == "--dry-run" ]]; then
  echo "release: DRY-RUN $tag — version sync preview only (no commit / tag / push):"
  # Snapshot exact current bytes (tracked OR untracked, incl. user WIP) and restore on exit,
  # so a dry-run never reverts to HEAD / never destroys uncommitted edits.
  snap="$(mktemp -d)" || die "mktemp failed"
  # shellcheck disable=SC2329  # invoked indirectly via the EXIT trap below
  _dry_restore() {
    local f
    for f in "${files[@]}"; do [[ -e "$snap/$f" ]] && cp "$snap/$f" "$f"; done
    rm -rf "$snap"
  }
  trap _dry_restore EXIT
  for f in "${files[@]}"; do
    [[ -e "$f" ]] || continue
    mkdir -p "$snap/$(dirname "$f")"
    cp "$f" "$snap/$f"
  done
  validate_marketplaces
  scripts/bump-version.sh "$ver"
  validate_versions
  git --no-pager diff -- "${files[@]}" || true
  echo "release: (dry-run) restoring originals; a real run would commit, tag $tag, and push."
  exit 0
fi

# prechecks (fail loud, never half-release)
[[ "$(git branch --show-current)" == "main" ]] || die "not on main"
[[ -z "$(git status --porcelain)" ]] || die "working tree dirty (incl. untracked) — commit or stash first"
validate_origin_remote
validate_marketplaces
git fetch -q origin main || die "git fetch failed"

# recovery: a prior atomic push may have aborted, leaving the tag local-only (origin has neither
# the bump commit nor the tag). Re-push both atomically instead of dying unrecoverably.
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
  remote_tag="$(git ls-remote --tags origin "refs/tags/$tag")" || die "cannot reach origin to check tag $tag — fix connectivity and rerun"
  [[ -z "$remote_tag" ]] || die "tag $tag already released (exists on origin)"
  validate_versions
  tag_commit="$(git rev-parse "$tag^{}")"
  head_commit="$(git rev-parse HEAD)"
  [[ "$tag_commit" == "$head_commit" ]] ||
    die "tag $tag points to $tag_commit but HEAD is $head_commit; history changed after tag creation. Recreate it at HEAD with 'git tag -fa $tag -m $tag' and rerun"
  echo "release: tag $tag exists locally at HEAD but not on origin (prior push aborted) — recovering"
  git push -q --atomic origin main "refs/tags/$tag" ||
    die "recovery push failed — if origin/main moved ahead, 'git pull --rebase origin main' then rerun; otherwise fix connectivity and rerun"
  echo "release: recovered — pushed main + $tag."
  exit 0
fi

# normal path: require main exactly in sync before mutating
[[ "$(git rev-parse HEAD)" == "$(git rev-parse FETCH_HEAD)" ]] || die "local main != origin/main — sync first"

scripts/bump-version.sh "$ver"
validate_versions
git add -- "${files[@]}"
git diff --cached --quiet && die "nothing to bump (already $ver everywhere)"
git commit -q -m "chore(release): 版本统一到 $ver"
git tag -a "$tag" -m "$tag"
# atomic: main + tag land together or neither — no silent half-release
git push -q --atomic origin main "refs/tags/$tag" ||
  die "push failed — local commit+tag kept; fix connectivity and rerun 'scripts/release.sh $ver' to recover"
echo "release: pushed $tag — CI is drafting the GitHub release."
echo "  edit notes & Publish: https://github.com/$repo_slug/releases"
