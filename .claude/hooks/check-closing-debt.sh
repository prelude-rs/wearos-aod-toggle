#!/usr/bin/env bash
# check-closing-debt.sh — the closing-debt AVISO for specs/proposed/ and specs/active/ (change
# 2026-09-change-parada-em-active: R6 as amended, N4, N5, N6).
#
# WHY IT LIVES IN .claude/hooks/: `class: portable` in .claude/adopt/manifest.yaml, same precedent as
# check-release-changelog.sh and check-epic-numbering.sh. `verify-archived-gates.sh` delegates to it in
# every PR (the THIRD delegation, same mold as those two).
#
# THE TERMS (design.md → "Termos"; the single source, summarised here):
#   - pasta de change = a direct subdirectory of specs/proposed/ or specs/active/.
#   - via rápida = the folder has a change.md whose first `^Mode:` field is `fast` (same reading as
#     verify-archived-gates.sh).
#   - concluída (specs/active/ only — a specs/proposed/ folder is still under discussion, there is no
#     evidence to close): formal flow = evidence.md exists and its first `^Verdict:` is COMPLETE;
#     via rápida = change.md's first `^Verdict:` is COMPLETE. Same readers as verify-archived-gates.sh.
#   - idade de uma pasta = whole days between "agora" and the most recent commit that touched it
#     (`git log -1 --format=%ct -- <pasta>`). A folder never committed has age 0 and is NEVER flagged.
#     "agora" = `date +%s`, or $SDD_DEBT_NOW (test seam, epoch seconds).
#   - parada = age > DEBT_DAYS (30 — 31 or more flags; the constant below).
#   - outside a git repo, ages cannot be measured: the hook says so (one AVISO) and only the
#     "concluída" warning still applies — printed WITHOUT the "(há N dias)" suffix, for BOTH forms
#     (controller resolution, design.md).
#   - shallow checkout: ages may be underestimated; the hook says so (one AVISO) BEFORE the per-folder
#     ones (I3: never a silent "nenhuma").
#
# N6 ANCHORS: each discriminator is a single whole-statement call site ending in `# H-<name>` —
# a line mark that names the rule the line carries (the control, each anchored line deleted in a copy,
# was made once and is recorded in the evidence.md of the change that created them; no suite repeats it):
# H-complete (a COMPLETE folder not archived — both forms), H-propstale (a stalled
# specs/proposed/ folder), H-actstale (a stalled specs/active/ folder). Every marked line is a whole
# statement (a single function call).
#
# READ-ONLY (N4): never writes anything. N1: one `git log -1` per folder (dezenas).
#
# Usage: check-closing-debt.sh [<raiz>]   (raiz default: cwd)
# Exit 0 on every run over a root — this is an AVISO, never a FAIL (R6 as amended: the hook only warns,
# it never blocks). The one exception is a usage error (bad arguments): exit 2, no counter line.
#
# Comments/logic in English, user-facing messages in pt-BR — spec-layout, "Language & rendering".
# Common hook library, loaded FIRST (before `set`, before any argument): without it this check exits 1
# naming it (R2 of 2026-10-biblioteca-comum-dos-hooks). `[ -r ]` + `command .`: a plain failed `.` is
# fatal under POSIXLY_CORRECT and would exit before the message. Found next to THIS file (BASH_SOURCE).
case "${BASH_SOURCE[0]}" in */*) HK_DIR="${BASH_SOURCE[0]%/*}" ;; *) HK_DIR=. ;; esac
# The EXIT trap around the load (fd 9, `|| exit`, HK_LIB_GONE, `trap - EXIT`; exit 1): see hooks-lib.sh → "Who loads it".
HK_LIB_GONE="sdd-kit: biblioteca dos hooks ausente ou ilegível: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não roda sem ela (instalação incompleta?)"
trap 'echo "$HK_LIB_GONE" >&9; exit 1' EXIT
{ [ -r "$HK_DIR/hooks-lib.sh" ] && command . "$HK_DIR/hooks-lib.sh" || exit; } 9>&2 2>/dev/null
trap - EXIT
declare -F verdict_of mode_of hk_git_env_clean >/dev/null || { echo "sdd-kit: biblioteca dos hooks incompleta: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não roda sem ela (instalação incompleta?)" >&2; exit 1; }
hk_git_env_clean   # the repository read (the folders' ages) is the root's own: see hooks-lib.sh → hk_git_env_clean
set -uo pipefail
export LC_ALL=C

DEBT_DAYS=30
NOW="${SDD_DEBT_NOW:-$(date +%s)}"

avisos=0
avisa() { echo "AVISO dívida de fechamento: $1"; avisos=$((avisos + 1)); }

usage() { echo "uso: check-closing-debt.sh [<raiz>]" >&2; exit 2; }

R=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -*) usage ;;
    *)  [ -z "$R" ] || usage; R="$1"; shift ;;
  esac
done
R="${R:-.}"
[ -d "$R" ] || usage

PROP="$R/specs/proposed"
ACT="$R/specs/active"

if [ ! -d "$PROP" ] && [ ! -d "$ACT" ]; then
  echo "AVISOS: 0"
  echo "dívida de fechamento: sem specs/proposed nem specs/active — n.a."
  exit 0
fi

# verdict_of <file> — the verdict reader (R6) is defined once, in hooks-lib.sh, loaded above.
# mode_of <file> — the `Mode:` reader is defined once, in hooks-lib.sh (R1 of 2026-10-hooks-sem-restos); this
# check hides grep's line at its call (`2>/dev/null`), as it always did.

IN_GIT=0
if command -v git >/dev/null 2>&1 && git -C "$R" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IN_GIT=1
fi

if [ "$IN_GIT" -eq 0 ]; then
  avisa "fora de um repo git — as idades não se medem"
elif [ "$(git -C "$R" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
  avisa "checkout raso — as idades podem estar subestimadas"
fi

# age_days <pasta> — whole days since the last commit that touched <pasta>. A folder never committed
# (git log prints nothing for its path) has age 0 — "nunca commitada" never flags (Termos).
age_days() {
  local rel ts
  rel="${1#"$R"/}"
  ts="$(git -C "$R" log -1 --format=%ct -- "$rel" 2>/dev/null)"
  if [ -z "$ts" ]; then echo 0; return 0; fi
  echo $(( (NOW - ts) / 86400 ))
}

# list_subdirs <pasta> — direct subdirectories of <pasta>, one per line; nothing when <pasta> is absent
# or empty.
list_subdirs() {
  local base="$1" d
  [ -d "$base" ] || return 0
  shopt -s nullglob
  for d in "$base"/*/; do printf '%s\n' "${d%/}"; done
  shopt -u nullglob
}

# check_stale <pasta-relativa> <rótulo> <idade> — "<rótulo>" (Mensagens do aviso de dívida); one
# definition for both specs/proposed/ ("proposta parada") and specs/active/ ("implementação parada") —
# <pasta-relativa> and <rótulo> are the only difference between them. <idade> is computed once per
# folder, in the loop below, and passed in here AND to check_complete, so a COMPLETE specs/active/
# folder pays for `git log` once, not twice.
check_stale() {
  local rel="$1" rotulo="$2" n="$3"
  [ "$IN_GIT" -eq 1 ] || return 0
  [ "$n" -gt "$DEBT_DAYS" ] || return 0
  avisa "$rel sem commit há $n dias ($rotulo)"
}

# check_complete <pasta> <id> <idade> — "concluída e não arquivada", both forms (Mensagens do aviso de
# dívida); outside git the "(há N dias)" suffix is dropped (controller resolution). <idade> is the age
# computed once per folder in the loop below (shared with check_stale).
check_complete() {
  local d="$1" id="$2" n="$3" cm="$1/change.md" ev="$1/evidence.md" mode="" is_fast=0 concluida=0 suf=""
  [ -f "$cm" ] && mode="$(mode_of "$cm" 2>/dev/null)"
  if [ "$mode" = "fast" ]; then
    is_fast=1
    [ -f "$cm" ] && [ "$(verdict_of "$cm")" = "COMPLETE" ] && concluida=1
  else
    [ -f "$ev" ] && [ "$(verdict_of "$ev")" = "COMPLETE" ] && concluida=1
  fi
  [ "$concluida" -eq 1 ] || return 0
  [ "$IN_GIT" -eq 1 ] && suf=" (há $n dias)"
  if [ "$is_fast" -eq 1 ]; then
    avisa "specs/active/$id é via rápida com change.md COMPLETE e não foi arquivada${suf}"
  else
    avisa "specs/active/$id tem evidence COMPLETE e não foi arquivada${suf}"
  fi
}

nprop=0; nact=0

while IFS= read -r d; do
  [ -n "$d" ] || continue
  nprop=$((nprop + 1))
  id="${d##*/}"
  n=0; [ "$IN_GIT" -eq 1 ] && n="$(age_days "$d")"
  check_stale "specs/proposed/$id" "proposta parada" "$n"   # H-propstale
done < <(list_subdirs "$PROP")

while IFS= read -r d; do
  [ -n "$d" ] || continue
  nact=$((nact + 1))
  id="${d##*/}"
  n=0; [ "$IN_GIT" -eq 1 ] && n="$(age_days "$d")"
  check_complete "$d" "$id" "$n"    # H-complete
  check_stale "specs/active/$id" "implementação parada" "$n"    # H-actstale
done < <(list_subdirs "$ACT")

if [ "$avisos" -eq 0 ]; then
  echo "dívida de fechamento: nenhuma ($nprop propostas, $nact em implementação)"
fi
echo "AVISOS: $avisos"
exit 0
