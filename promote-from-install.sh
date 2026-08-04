#!/usr/bin/env bash
# Promote the working (installed) skill into this release repo.
#
# Direction is deliberately ONE-WAY: install -> repo.
#   ~/.claude/skills/create-ixmap   working copy: testing and evolving
#   this repo                       release staging: diff, review, commit, push
#
# It never pulls repo -> install (that would clobber work in progress) and never
# deletes repo-only files (LICENSE.txt, these scripts).
#
#   ./promote-from-install.sh              # dry run: what would change
#   ./promote-from-install.sh --apply      # copy, then show the staged diff
#   ./promote-from-install.sh --apply --skip-checks
#
# Default source can be overridden:  SKILL_SRC=/some/path ./promote-from-install.sh

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SKILL_SRC:-$HOME/.claude/skills/create-ixmap}"
APPLY=0
SKIP_CHECKS=0
for a in "$@"; do
  case "$a" in
    --apply)       APPLY=1 ;;
    --skip-checks) SKIP_CHECKS=1 ;;
    -h|--help)     sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

[ -d "$SRC" ] || { echo "source not found: $SRC" >&2; exit 2; }
cd "$REPO" || exit 2

# Files that live only in the release repo and must never be touched or reported
# as drift. Keep this list in sync if you add release tooling.
is_repo_only() {
  case "$1" in
    .git|.gitignore|LICENSE.txt|check-skill.sh|promote-from-install.sh) return 0 ;;
    *) return 1 ;;
  esac
}

printf '\033[1mPromote\033[0m  %s\n     ->  %s\n\n' "$SRC" "$REPO"

# A dirty tree means the diff you are about to review would mix the promotion
# with unrelated edits. Stop rather than muddy the review step.
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "Repo has uncommitted changes:"
  git status --short | sed 's/^/  /'
  echo
  echo "Commit or stash them first, so the diff you review is only the promotion."
  exit 1
fi

# ------------------------------------------------------------- classify files
CHANGED=(); NEW=(); GONE=()
while IFS= read -r p; do
  b="$(basename "$p")"
  [ "$b" = ".DS_Store" ] && continue
  if [ ! -e "$REPO/$b" ]; then NEW+=("$b")
  elif ! cmp -s "$p" "$REPO/$b"; then CHANGED+=("$b")
  fi
done < <(find "$SRC" -maxdepth 1 -type f)

for p in "$REPO"/*; do
  b="$(basename "$p")"
  [ -e "$p" ] || continue
  is_repo_only "$b" && continue
  [ "$b" = ".DS_Store" ] && continue
  [ -e "$SRC/$b" ] || GONE+=("$b")
done

if [ ${#CHANGED[@]} -eq 0 ] && [ ${#NEW[@]} -eq 0 ] && [ ${#GONE[@]} -eq 0 ]; then
  echo "Already in sync — nothing to promote."
  exit 0
fi

[ ${#CHANGED[@]} -gt 0 ] && { echo "Modified (${#CHANGED[@]}):"; printf '  M  %s\n' "${CHANGED[@]}"; }
[ ${#NEW[@]}     -gt 0 ] && { echo "New (${#NEW[@]}) — will need 'git add':"; printf '  +  %s\n' "${NEW[@]}"; }
[ ${#GONE[@]}    -gt 0 ] && {
  echo "In repo but NOT in the working copy (${#GONE[@]}) — left untouched, remove by hand if intended:"
  printf '  ?  %s\n' "${GONE[@]}"; }

if [ "$APPLY" -eq 0 ]; then
  printf '\nDry run. Re-run with --apply to promote.\n'
  exit 0
fi

# ------------------------------------------------------------------- checks
if [ "$SKIP_CHECKS" -eq 0 ] && [ -x "$REPO/check-skill.sh" ]; then
  printf '\n\033[1mRunning checks against the working copy\033[0m\n'
  if ! "$REPO/check-skill.sh" "$SRC"; then
    printf '\nChecks failed — nothing promoted. Fix the working copy, or pass --skip-checks.\n'
    exit 1
  fi
fi

# -------------------------------------------------------------------- copy
printf '\n'
for b in "${CHANGED[@]}" "${NEW[@]}"; do
  cp "$SRC/$b" "$REPO/$b" && echo "  copied $b"
done

printf '\n\033[1mStaged-for-review diff\033[0m\n'
git --no-pager diff --stat
printf '\nNext:\n  git diff              # review\n  git add -p            # stage deliberately\n  git commit && git push\n'
[ ${#NEW[@]} -gt 0 ] && printf '  git add %s\n' "$(printf '%s ' "${NEW[@]}")"
exit 0
