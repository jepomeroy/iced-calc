#!/usr/bin/env bash
# Fail unless the iced-calc version in Cargo.toml is new.
#
# Usage: scripts/check-version.sh [base-version]
#
# Checks that the current version:
#   - has no existing release tag (v<version>)
#   - is greater than the highest existing v* tag
#   - is greater than [base-version] when given (e.g. main's version, for PRs)
#
# Prints the version on stdout and writes version=<v> to $GITHUB_OUTPUT if set.
set -euo pipefail

base=${1:-}

version=$(cargo metadata --no-deps --format-version 1 \
  | jq -r '.packages[] | select(.name == "iced-calc") | .version')

fail() {
  echo "::error file=Cargo.toml::$1" >&2
  exit 1
}

if git rev-parse -q --verify "refs/tags/v$version" >/dev/null; then
  fail "Version $version is already released (tag v$version exists). Bump the version in Cargo.toml."
fi

latest=$(git tag --list 'v*' | sed 's/^v//' | sort -V | tail -n1)
if [ -n "$latest" ] && ! dpkg --compare-versions "$version" gt "$latest"; then
  fail "Version $version is not greater than the latest release $latest. Bump the version in Cargo.toml."
fi

if [ -n "$base" ] && ! dpkg --compare-versions "$version" gt "$base"; then
  fail "Version $version is not greater than the base branch version $base. Bump the version in Cargo.toml."
fi

echo "OK: $version is new (latest release: ${latest:-none}${base:+, base branch: $base})" >&2
[ -n "${GITHUB_OUTPUT:-}" ] && echo "version=$version" >> "$GITHUB_OUTPUT"
echo "$version"
