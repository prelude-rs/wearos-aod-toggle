#!/usr/bin/env bash
# check-release-changelog.sh — the MECHANICAL aferição of the root release changelog (`CHANGELOG.md`,
# keep-a-changelog) against the change ledger (`specs/CHANGELOG.md`) — change
# 2026-09-changelog-de-release, R4 (coverage + position) and R5 (the PR to `main`).
#
# WHY IT LIVES IN .claude/hooks/ AND NOT IN tests/: `tests/check-spec-layout.sh` is never-copy, so an
# aferição there never reaches an adopting repo. This file is `class: portable` in
# .claude/adopt/manifest.yaml, same precedent as check-tasks.sh and check-report.sh. The archive gate
# (verify-archived-gates.sh) delegates to it, so it runs in every PR of the kit and of every adopter
# that already calls that gate with the base ref.
#
# THE TOKENS (design.md → "Forma do changelog de release"; the single source, not restated in full):
#   - section `^## \[(.+)\]` (optional ` - AAAA-MM-DD` after); `Unreleased` literal, anything else is a
#     version. A section's body runs to the next `## ` line (no link footer — it would make the last
#     section "change" at every release). Trailing blank lines of a body are not content.
#   - item = a line starting `- ` inside a section; it must END in `(seq N)` or `(seq N, #P)`
#     (trailing blanks tolerated). A `- ` line outside a section is free text.
#   - `**Changes de release (sem item):** seq N, N, …` | `nenhuma` — optional (absent ≡ `nenhuma`);
#     the listed seqs are out of coverage. `**Ledger anterior a este arquivo:** seq ≤ N` — the seqs ≤ N
#     are out of coverage; the label with a value that does not match fails (I3). First line wins for
#     each label (a later one can only make the check stricter, never pass by omission).
#   - ledger seq = `^\| *[0-9]+ *\|` in specs/CHANGELOG.md.
# The section, its name, its item, its seq, its text and the ledger seq line are read through the
# library's HK_AWK_CHANGELOG (R4 of 2026-10-biblioteca-comum-dos-hooks) — the definitions above, written
# once there and shared with sdd-release and tests/check-spec-layout.sh; the decisions stay here.
#
# WITH --base <ref> (design.md → "Termos de posição"): the base versions are read with
# `git -C <raiz> show <ref>:./…` (process substitution — nothing is written). A ref that does not
# resolve FAILS (I3); a resolvable base without CHANGELOG.md is the file's birth and switches the
# position rules off, SAID in the output (N5). "Para main" iff the last `/`-segment of <ref> is `main`;
# the R5 rules (Unreleased empty; tag `v<versão>` of the SECOND closed section, AVISO only) apply
# whenever the base resolves, birth included — the first promotion of the kit is exactly that case.
#
# N6 ANCHORS: each discriminator line ends in `# F-<name>` — a line mark that names the rule the line
# carries (the control, each anchor deleted in a copy, was made once and is recorded in the evidence.md of
# the change that created them; no suite repeats it): F-missing, F-dup, F-noref, F-marco
# (value check + the exclusion), F-release (the exclusion), F-relitem, F-decl, F-imut (closed section
# immutable), F-pos (destination of a new seq), F-head (header immutability), F-close (closings =
# declarations), F-unrel (Unreleased on a PR to main). Every marked line is a whole statement.
#
# READ-ONLY (N4): never writes anything. N1: one awk pass over the four inputs, no per-seq shell loop.
#
# Usage: check-release-changelog.sh [--base <ref>] [<raiz>]   (raiz default: cwd)
# Exit 0 = PASS, n.a. or birth (all said). Exit 1 = at least one FAIL. Exit 2 = usage error.
#
# Portability: bash + POSIX awk (runs under mawk: no gensub, no {n,m}, no \b; text reaches awk through
# ENVIRON, never `awk -v`, whose escape processing corrupts it), LC_ALL=C.
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
{ declare -F hk_base_root_flags hk_base_resolves hk_pr_to_main hk_awk_records hk_pass_line hk_git_env_clean >/dev/null && [ -n "${HK_AWK_CHANGELOG-}" ]; } || { echo "sdd-kit: biblioteca dos hooks incompleta: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não roda sem ela (instalação incompleta?)" >&2; exit 1; }
hk_git_env_clean   # the repository read (the base) is the root's own: see hooks-lib.sh → hk_git_env_clean
set -uo pipefail
export LC_ALL=C

bad=0
fail() { echo "FAIL - changelog de release: $1" >&2; bad=1; }
usage() { echo "uso: check-release-changelog.sh [--base <ref>] [<raiz>]" >&2; exit 2; }

# Arguments, base and root by the library (R3): writes BASE, HAS_BASE and R (relative roots anchored
# with `./`) and the array HK_FLAGS; this check has no flag besides --base, so any in HK_FLAGS is usage.
{ hk_base_root_flags "$@" && [ "${#HK_FLAGS[@]}" -eq 0 ]; } || usage
LEDGER="$R/specs/CHANGELOG.md"
CL="$R/CHANGELOG.md"

if [ ! -f "$LEDGER" ]; then
  echo "changelog de release: sem ledger de changes (specs/CHANGELOG.md) — n.a."
  exit 0
fi
if [ ! -f "$CL" ]; then
  fail "CHANGELOG.md ausente na raiz, e o repo tem ledger de changes"
  exit 1
fi

POS=0; MAIN=0
if [ "$HAS_BASE" -eq 1 ]; then
  if ! hk_base_resolves "$R" "$BASE"; then
    fail "base $BASE não resolve (git rev-parse)"
    HAS_BASE=0
  else
    hk_pr_to_main "$BASE" && MAIN=1
    if git -C "$R" cat-file -e "$BASE:./CHANGELOG.md" 2>/dev/null; then
      POS=1
    else
      echo "changelog de release: base $BASE sem CHANGELOG.md — nascimento, regras de posição não se aplicam"
    fi
  fi
fi

# The one awk pass. Inputs: ARGV[1] head ledger, ARGV[2] head changelog, ARGV[3] base ledger, ARGV[4]
# base changelog (/dev/null when position rules are off). Output records, one per line:
#   F<TAB>msg (FAIL)  W<TAB>msg (AVISO)  P<TAB>version (the previous closed section, for R5's tag
#   warning)  S<TAB>stats (always last — its absence means awk did not finish).
# Keys are (p, …) with p = "h" (head) or "b" (base). The library's HK_AWK_CHANGELOG goes in front of
# this program (run_awk); the text of a section is HK_CL_TEXT[p SUBSEP name] (hk_cl_open/hk_cl_add).
# shellcheck disable=SC2016 # the program is awk, not shell: nothing in it is meant to expand
PROG='
function fail(m) { print "F\t" m }
function warn(m) { print "W\t" m }
function trim(v) { sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v); return v }
function first(l) { sub(/,.*$/, "", l); return l }
function ledger_line(p,   s) {
  s = hk_ledger_seq($0)
  if (s < 0) return
  if (!((p, s) in ledger_count)) ledger_order[p, ++ledger_n[p]] = s
  ledger_count[p, s]++
}
function cl_line(p,   v, name, s, a, k, nk, ok, c) {
  if (hk_cl_is_boundary($0)) {
    cur[p] = ""
    if (hk_cl_is_section($0)) {
      name = hk_cl_name($0)
      cur[p] = name; hk_cl_open(p SUBSEP name, $0)
      if (name != "Unreleased") { closed[p, ++nclosed[p]] = name; isclosed[p, name] = 1 }
    }
    return
  }
  c = cur[p]
  if (c != "") hk_cl_add(p SUBSEP c, $0)
  if (index($0, DLAB) == 1 && !dseen[p]) {
    dseen[p] = 1
    v = trim(substr($0, length(DLAB) + 1))
    ok = (v == "nenhuma" || v ~ /^seq [0-9]+(, *[0-9]+)*$/)
    if (!ok && p == "h") fail("declaração das changes de release malformada (linha " FNR ")")   # F-decl
    if (ok && v != "nenhuma") {
      sub(/^seq /, "", v); nk = split(v, a, /, */)
      for (k = 1; k <= nk; k++) { s = hk_seq_num(a[k]); if (!((p, s) in decl)) { decl[p, s] = 1; decl_order[p, ++decl_n[p]] = s } }
    }
  }
  if (index($0, MLAB) == 1 && !mseen[p]) {
    mseen[p] = 1
    v = trim(substr($0, length(MLAB) + 1)); marco_raw[p] = v
    ok = (v ~ /^seq ≤ [0-9]+$/)
    if (!ok && p == "h") fail("marco de nascimento declarado sem valor (linha " FNR ")")   # F-marco
    if (ok) { sub(/^seq ≤ /, "", v); has_marco[p] = 1; marco[p] = hk_seq_num(v) }
  }
  if (p == "h" && c != "" && hk_cl_is_item($0)) {
    if (c == "Unreleased") nunrel++
    s = hk_cl_item_seq($0); ok = (s >= 0)
    if (ok) {
      item_count[s]++; item_lines[s] = (item_count[s] > 1 ? item_lines[s] ", " : item_lines[s]) FNR; item_sec[s, item_count[s]] = c
    }
    if (!ok) fail("linha " FNR " é item sem (seq N)")   # F-noref
  }
}
BEGIN {
  DLAB = "**Changes de release (sem item):**"; MLAB = "**Ledger anterior a este arquivo:**"
  BASE = ENVIRON["CRC_BASE"]; POS = ENVIRON["CRC_POS"] + 0; MAIN = ENVIRON["CRC_MAIN"] + 0
}
FILENAME == ARGV[1] { ledger_line("h"); next }
FILENAME == ARGV[2] { cl_line("h"); next }
FILENAME == ARGV[3] { ledger_line("b"); next }
FILENAME == ARGV[4] { cl_line("b"); next }
END {
  # R4 coverage — every ledger seq exactly once as an item, minus the declared exclusions.
  nrel = 0; nmar = 0; ncov = 0
  for (i = 1; i <= ledger_n["h"]; i++) {
    s = ledger_order["h", i]
    if (ledger_count["h", s] > 1) warn("seq " s " aparece " ledger_count["h", s] " vezes no ledger de changes — um item cobre só uma")
    isrel = 0
    if (("h", s) in decl) isrel = 1   # F-release
    if (isrel && item_count[s] > 0) fail("seq " s " é change de release e tem item (linha " first(item_lines[s]) ") — a seção é ela")   # F-relitem
    if (isrel) { nrel++; continue }
    if (has_marco["h"] && s <= marco["h"]) { nmar++; continue }   # F-marco
    if (item_count[s] == 0) { fail("seq " s " ausente"); continue }   # F-missing
    if (item_count[s] > 1) { fail("seq " s " aparece " item_count[s] " vezes (linhas " item_lines[s] ")"); continue }   # F-dup
    ncov++
  }
  # R4 position — only when the base has the file.
  if (POS) {
    n_new_closed = 0; new_closed_list = ""
    for (i = 1; i <= nclosed["h"]; i++) {
      n = closed["h", i]
      if (!(("b", n) in isclosed)) { newc[n] = 1; n_new_closed++; new_closed_list = (n_new_closed > 1 ? new_closed_list ", " : new_closed_list) "[" n "]" }
    }
    for (i = 1; i <= nclosed["b"]; i++) {
      n = closed["b", i]
      if (!(("h", n) in isclosed) || HK_CL_TEXT["h" SUBSEP n] != HK_CL_TEXT["b" SUBSEP n]) fail("seção fechada " n " mudou em relação a " BASE)   # F-imut
    }
    for (i = 1; i <= ledger_n["h"]; i++) {
      s = ledger_order["h", i]
      if (("b", s) in ledger_count) continue
      for (j = 1; j <= item_count[s]; j++) {
        sec = item_sec[s, j]
        if (sec != "Unreleased" && !(sec in newc)) fail("seq " s " é nova nesta PR e está em [" sec "], que não é Unreleased nem seção fechada nesta PR")   # F-pos
      }
    }
    if (mseen["b"] && (!mseen["h"] || marco_raw["h"] != marco_raw["b"])) fail("marco de nascimento mudou em relação a " BASE)   # F-head
    if (!mseen["b"] && mseen["h"]) fail("marco de nascimento apareceu depois do nascimento em relação a " BASE)   # F-head
    for (i = 1; i <= decl_n["b"]; i++) { s = decl_order["b", i]; if (!(("h", s) in decl)) fail("declaração das changes de release perdeu a seq " s " em relação a " BASE) }   # F-head
    n_new_decl = 0; new_decl_list = ""
    for (i = 1; i <= decl_n["h"]; i++) {
      s = decl_order["h", i]
      if (("b", s) in decl) continue
      n_new_decl++; new_decl_list = (n_new_decl > 1 ? new_decl_list ", " : new_decl_list) s   # never `name (expr)`: busybox reads it as a call
      if (n_new_closed == 0) fail("seq " s " declarada como release numa PR que não fecha seção em relação a " BASE)   # F-head
      if (!(("h", s) in ledger_count) || (("b", s) in ledger_count)) fail("seq " s " declarada como release não é nova no ledger em relação a " BASE)   # F-head
    }
    if (n_new_closed != n_new_decl) fail("esta PR fecha " n_new_closed " seção(ões) (" (new_closed_list == "" ? "nenhuma" : new_closed_list) ") e declara " n_new_decl " change(s) de release (" (new_decl_list == "" ? "nenhuma" : "seq " new_decl_list) ") — cada fechamento é uma change de release que declara a própria seq")   # F-close
  }
  # R5 — the PR to main.
  if (MAIN) {
    if (nunrel > 0) fail("Unreleased tem " nunrel " item(ns) numa PR para main")   # F-unrel
    if (nclosed["h"] >= 2) print "P\t" closed["h", 2]
  }
  print "S\t" ncov " seqs cobertas; " nrel " de release; " nmar " antes do marco"
}
'

# shellcheck disable=SC2329 # invoked indirectly: hk_awk_records runs it
run_awk() {
  if [ "$POS" -eq 1 ]; then
    CRC_BASE="$BASE" CRC_POS=1 CRC_MAIN="$MAIN" awk "$HK_AWK_CHANGELOG$PROG" "$LEDGER" "$CL" \
      <(git -C "$R" show "$BASE:./specs/CHANGELOG.md" 2>/dev/null) \
      <(git -C "$R" show "$BASE:./CHANGELOG.md" 2>/dev/null)
  else
    CRC_BASE="$BASE" CRC_POS=0 CRC_MAIN="$MAIN" awk "$HK_AWK_CHANGELOG$PROG" "$LEDGER" "$CL" /dev/null /dev/null
  fi
}

# This check's record handler; the loop, the S record (HK_STATS) and the sentinel are the library's
# (hk_awk_records, R3). F = a FAIL, W = an AVISO line, P = the previous closed section (R5's tag warning).
prev=""
# shellcheck disable=SC2329 # invoked indirectly: hk_awk_records calls it per record
cl_record() {
  case "$1" in
    F) fail "$2" ;;
    W) echo "AVISO changelog de release: $2" ;;
    P) prev="$2" ;;
  esac
}
# No stats record = awk did not finish: never a silent pass (I3) — here a FAIL, and the check goes on to
# the tag aferição.
hk_awk_records cl_record run_awk || fail "leitura de $CL não terminou (awk)"

# R5 — AVISO only: publishing is a later human act. A shallow checkout degrades it (no tags seen).
if [ "$MAIN" -eq 1 ] && [ -n "$prev" ]; then
  grep -qxF "v$prev" <<< "$(git -C "$R" tag -l "v$prev" 2>/dev/null)" \
    || echo "AVISO changelog de release: release $prev sem tag v$prev"
fi

hk_pass_line "changelog de release" "$bad"; exit $?
