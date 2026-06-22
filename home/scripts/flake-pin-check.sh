#!/usr/bin/env bash
# Weekly check for upstream updates to the *pinned* gaming inputs in ~/myflake.
# These inputs are deliberately frozen (zig2nix / cargo locks), so `nixupdate`
# never moves them. This only NOTIFIES (via msmtp/Proton Bridge); the bump stays
# manual — see pkgs/falcond/default.nix for the lock-regen procedure.
#
# Best-effort: any network/API failure is logged and skipped (never fails the
# unit, never spams). Mail is sent only when something is actually behind.
set -uo pipefail

FLAKE="$HOME/myflake"
LOCK="$FLAKE/flake.lock"
RECIPIENT="your-email@example.com"
API="https://api.github.com"

gh() { curl -fsSL --max-time 20 -H "Accept: application/vnd.github+json" "$@"; }

[ -r "$LOCK" ] || { echo "no flake.lock at $LOCK" >&2; exit 0; }

updates=""

# Commit-pinned flake inputs: compare locked rev vs default-branch HEAD.
check_commit() {
  local node="$1" owner="$2" repo="$3" label="$4"
  local cur latest ahead
  cur=$(jq -r --arg n "$node" '.nodes[$n].locked.rev // empty' "$LOCK")
  [ -n "$cur" ] || { echo "WARN: no locked rev for $node" >&2; return 0; }
  latest=$(gh "$API/repos/$owner/$repo/commits/HEAD" | jq -r '.sha // empty')
  [ -n "$latest" ] || { echo "WARN: API failed for $owner/$repo" >&2; return 0; }
  [ "$cur" = "$latest" ] && return 0
  ahead=$(gh "$API/repos/$owner/$repo/compare/$cur...$latest" | jq -r '.ahead_by // "?"')
  updates+="* ${label}: ${ahead} new commit(s)
    pinned: ${cur:0:12}
    latest: ${latest:0:12}
    diff:   https://github.com/${owner}/${repo}/compare/${cur:0:12}...${latest:0:12}

"
}

# Tag-pinned source (read version from the package def): compare vs latest release.
check_release() {
  local owner="$1" repo="$2" label="$3" file="$4"
  local cur latest
  cur=$(grep -oP 'version\s*=\s*"\K[^"]+' "$file" | head -1)
  [ -n "$cur" ] || { echo "WARN: no version in $file" >&2; return 0; }
  latest=$(gh "$API/repos/$owner/$repo/releases/latest" | jq -r '.tag_name // empty' | sed 's/^v//')
  [ -n "$latest" ] || { echo "WARN: API failed for $owner/$repo" >&2; return 0; }
  [ "$cur" = "$latest" ] && return 0
  updates+="* ${label}: ${cur} -> ${latest} (new release)
    notes:  https://github.com/${owner}/${repo}/releases/tag/v${latest}

"
}

check_commit  "falcond-src"      "PikaOS-Linux" "falcond"          "falcond"
check_commit  "falcond-profiles" "PikaOS-Linux" "falcond-profiles" "falcond-profiles"
check_release "sched-ext" "scx-loader" "scx-loader" "$FLAKE/pkgs/scx-loader/default.nix"

[ -n "$updates" ] || { echo "all pinned inputs current"; exit 0; }

count=$(grep -c '^\*' <<<"$updates")
{
  echo "To: ${RECIPIENT}"
  echo "Subject: [nixos] ${count} pinned input(s) have upstream updates"
  echo "Content-Type: text/plain; charset=utf-8"
  echo
  echo "Pinned gaming inputs in ~/myflake have newer upstream versions:"
  echo
  printf '%s' "$updates"
  echo "These are intentionally pinned. To bump: update the rev/tag, regenerate"
  echo "the lock (see comment in pkgs/falcond/default.nix), then nixswitch."
} | msmtp -t

echo "notified: ${count} update(s)"
