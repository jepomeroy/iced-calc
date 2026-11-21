#!/usr/bin/env bash
# Decide whether the changes between two commits affect the shipped package.
#
# Usage: scripts/needs-release.sh <base-ref> [head-ref]
#
# Prints "true" if any changed file could change the .deb, "false" if every
# changed file is on the ignore list below. Writes release=<bool> to
# $GITHUB_OUTPUT if set. Prints "true" when the diff can't be computed.
set -euo pipefail

base=${1:-}
head=${2:-HEAD}

# Files that never change the built .deb. `*` also matches `/`, so `*.md`
# covers Markdown anywhere and `.github/*` covers everything under .github/.
is_ignored() {
  case "$1" in
    *.md | LICENSE* | \
    .github/* | .gitignore | .editorconfig | .vscode/* | \
    justfile | bacon.toml | rustfmt.toml | .rustfmt.toml | clippy.toml | \
    scripts/check-version.sh | scripts/needs-release.sh | scripts/build-apt-repo.sh)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

result=true
if [ -n "$base" ] && [ "$base" != "0000000000000000000000000000000000000000" ] \
   && files=$(git diff --name-only "$base" "$head" 2>/dev/null); then
  result=false
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if is_ignored "$f"; then
      echo "  ignored: $f" >&2
    else
      echo "  release: $f" >&2
      result=true
    fi
  done <<< "$files"
else
  echo "Could not diff '$base'..'$head'; assuming a release is needed." >&2
fi

echo "needs release: $result" >&2
[ -n "${GITHUB_OUTPUT:-}" ] && echo "release=$result" >> "$GITHUB_OUTPUT"
echo "$result"
