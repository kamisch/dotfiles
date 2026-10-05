#!/usr/bin/env bash
# PreToolUse(Bash) gate: the first MR-creating command per (session, repo) is denied
# until Claude runs the doc/docstring staleness scan. The retry passes.
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")

grep -qE 'glab[[:space:]]+mr[[:space:]]+create|gh[[:space:]]+pr[[:space:]]+create|merge_request\.create' <<<"$cmd" || exit 0

# Resolve the target repo: a leading `cd <dir> &&` wins over the session cwd.
dir=$(jq -r '.cwd' <<<"$input")
if [[ $cmd =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]\&\;]+) ]]; then
  target=${BASH_REMATCH[1]/#\~/$HOME}
  [[ $target = /* ]] || target="$dir/$target"
  dir=$target
fi
repo=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "$dir")

session=$(jq -r '.session_id' <<<"$input")
marker="${TMPDIR:-/tmp}/claude-doc-scan-${session}-$(printf '%s' "$repo" | md5sum | cut -c1-12)"
[[ -e $marker ]] && exit 0
touch "$marker"

reason="Before creating this MR, scan $repo for outdated documentation: if the repo has a review-docs command, invoke it with argument mr; otherwise diff the branch against its merge-base with the default branch and check every doc, README, CLAUDE.md, and docstring that describes the changed code (renamed/removed params, defaults, flags, config keys, paths, behavior). Fix every outdated item, commit and push the fixes, and list them for the user. Then retry the same MR command; it will not be blocked again."
jq -n --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
