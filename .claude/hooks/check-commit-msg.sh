#!/usr/bin/env bash
# check-commit-msg.sh — commit-msg git hook (git is its only caller, via the .git/hooks/commit-msg that the
# adoption installs).
# Enforces the two or three NON-NEGOTIABLE git rules deterministically.
# Install: cp .claude/hooks/check-commit-msg.sh .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg
# (or wire via husky/lefthook so juniors get it automatically)
#
# Common hook library, loaded FIRST (before `set`, before the argument). Installed as .git/hooks/commit-msg
# this file lives far from it; git runs hooks with the cwd at the root of the working tree (non-bare
# repos), so the common case is the cheap one: try .claude/hooks/hooks-lib.sh relative to the cwd first
# (no fork). Only when it isn't readable there — called from elsewhere, e.g. from a subdirectory, or
# GIT_DIR/GIT_WORK_TREE pointing somewhere else — fall back to `git rev-parse --show-toplevel` to find
# the same root the slow way. Without it in either place, every commit is refused, exit 1, naming the
# path the fallback tried — also on a branch or worktree whose tree predates the library (R2 of
# 2026-10-biblioteca-comum-dos-hooks; the way out is a base that has it: rebase or merge `dev`).
# `[ -r ]` + `command .`: a plain failed `.` is fatal under POSIXLY_CORRECT and would exit before the message.
# The EXIT trap around the two attempts (fd 9, `|| exit` on the second only, HK_DIR recomputed in the trap, `trap - EXIT`; exit 1): see hooks-lib.sh → "Who loads it".
trap 'HK_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude/hooks"; echo "✗ commit-msg: biblioteca dos hooks ausente ou ilegível: $HK_DIR/hooks-lib.sh — reinstale os hooks do kit" >&9; exit 1' EXIT
HK_DIR="./.claude/hooks"
{ [ -r "$HK_DIR/hooks-lib.sh" ] && command . "$HK_DIR/hooks-lib.sh"; } 9>&2 2>/dev/null || {
  HK_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude/hooks"
  { [ -r "$HK_DIR/hooks-lib.sh" ] && command . "$HK_DIR/hooks-lib.sh" || exit; } 9>&2 2>/dev/null
}
trap - EXIT

set -euo pipefail
MSG_FILE="$1"
SUBJECT="$(head -n1 "$MSG_FILE")"

# RULE 1 — Sellers type-prefixed subject (scope optional). Types per git-practices skill.
if ! grep -qE '^(feat|fix|refact|refactor|docs|test|chore|perf)(\([a-z0-9._-]+\))?: .+' <<< "$SUBJECT"; then
  echo "✗ commit-msg: o assunto deve ser 'tipo: descrição' (tipo ∈ feat|fix|refact|docs|test|chore — veja a skill git-practices)" >&2
  exit 1
fi

# RULE 2 — Subject length.
if [ "${#SUBJECT}" -gt 72 ]; then
  echo "✗ commit-msg: o assunto tem ${#SUBJECT} chars (máx 72)" >&2
  exit 1
fi

# RULE 3 — feat/fix/refact commits reference their change-id (skip for docs/test/chore).
if grep -qE '^(feat|fix|refact|refactor|perf)' <<< "$SUBJECT" ; then
  if ! grep -qE 'Refs?: [a-z0-9-]+' "$MSG_FILE"; then
    echo "✗ commit-msg: commits feat/fix/refact devem referenciar seu change-id, ex.: 'Refs: 2026-06-jwt-keycloak R3'" >&2
    exit 1
  fi
fi
exit 0
