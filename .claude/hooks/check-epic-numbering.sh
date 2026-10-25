#!/usr/bin/env bash
# check-epic-numbering.sh — the MECHANICAL aferição of epic numbering in `specs/epics/` — change
# 2026-09-numeracao-de-epicos, R1 (name form), R2 (unique number), R3 (unique name), R4 (never reused,
# never renumbered) and R5 (the legacy file).
#
# WHY IT LIVES IN .claude/hooks/: `class: portable` in .claude/adopt/manifest.yaml, same precedent as
# check-release-changelog.sh. The archive gate (verify-archived-gates.sh) delegates to it in every PR,
# and the adoption `verify` runs the installed copy without --base.
#
# THE TERMS (design.md → "Termos"; the single source, summarised here):
#   - epic file = every `specs/epics/*.md` (no recursion, dotfiles included), except
#     `specs/epics/LEGADO-NUMERACAO.md`. Form = `^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*\.md$`; number = first
#     three chars; name = what follows `NNN-`, without `.md`.
#   - collision = two epic files with the same number or the same name; three files = three pairs.
#   - legacy file: only lines starting with "- `" are read; form
#     "- `<A.md>` e `<B.md>` — <motivo>" (order free; file names with `.md`, no path). A read line
#     without that form is malformed; a well-formed one whose pair does not exist or does not collide
#     is a dead dispensation; an empty motive (blank, a whole `<…>`, [SPECIFY], TODO, N/A — case-blind)
#     fails. A line with the pair and nothing after it is a missing motive, not malformed.
#   - tree rules read the DISK (`<raiz>/specs/epics/`), committed or not; base, starting point and
#     history always come from git.
#   - PR rules (only with --base): starting point = `git merge-base <base> HEAD`; new epic = epic file
#     on disk absent from the starting point's tree (by file name). History max = the highest in-form
#     number in `git log <base> --full-history --diff-filter=AR --name-only -- specs/epics/` united with
#     the base's tree (`000` if none). A new epic with number ≤ max is reuse. A new epic whose name is
#     that of a starting-point epic the PR removed is renumbering. A legacy line naming a new epic is
#     not declarable (the pair is not counted as declared). Without --base every pair is declarable.
#   - PR to main: last `/`-segment of <base> is `main` AND the repo has a `dev` branch
#     (`refs/heads/dev`, or `refs/remotes/<remote>/dev` when <base> is `<remote>/main`) → the PR rules
#     do not apply, and that is SAID. Without a `dev` branch a PR to main applies them.
#   - base that does not resolve → FAIL; base resolves but no merge-base (shallow) → FAIL (I3); shallow
#     checkout with a merge-base → AVISO (the max may be underestimated), the check still runs.
#   - collision between two NEW epics (both absent from the starting point): the "os dois são novos"
#     variant (controller resolution W6 of the consistency report, round 6).
#   - PASS stats: "máximo" = the highest number in the tree, or in the base history when that is higher
#     and the PR rules ran — the number the next epic must exceed.
#
# --sugerir-legado: prints ONLY one ready legacy line per undeclared, declarable collision
# ("- `<A>` e `<B>` — <motivo>", the motive left for the human) on stdout and exits 0; a check that
# could not run (base, merge-base, unfinished awk) still exits 1 on stderr.
#
# N6 ANCHORS: each discriminator line ends in `# G-<name>` — a line mark that names the rule the line
# carries: G-form, G-num, G-slug, G-reuse,
# G-legmal, G-legdead, G-legmot, G-legnew (a pair with a new epic), G-renum, G-hist (reading the base
# history), G-main (the promotion dispensation). Every marked line is a whole statement. The control
# (each anchor deleted in a copy, its isolated case changing result) was made once and is recorded in the
# evidence.md of the change that created them; no suite repeats it.
#
# READ-ONLY (N4): never writes anything. N1: one listing of the tree, one of the base, one of the
# starting point, one `git log` of the directory, one awk pass.
#
# Usage: check-epic-numbering.sh [--base <ref>] [--sugerir-legado] [<raiz>]   (raiz default: cwd)
# Exit 0 = PASS, n.a. or suggestions printed (all said). Exit 1 = at least one FAIL. Exit 2 = usage.
#
# Portability: bash + POSIX awk (runs under mawk: no gensub, no {n,m}, no \b; text reaches awk as input
# files, and the only value passed in is the numeric flag EPIC_PR_RULES through ENVIRON — never `awk -v`,
# whose escape processing corrupts text), LC_ALL=C.
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
hk_git_env_clean   # the repository read (the base, the history) is the root's own: see hooks-lib.sh → hk_git_env_clean
set -uo pipefail
export LC_ALL=C

bad=0; SUG=0
fail() { echo "FAIL - numeração de épicos: $1" >&2; bad=1; }
say() { [ "$SUG" -eq 1 ] || echo "$1"; }
usage() { echo "uso: check-epic-numbering.sh [--base <ref>] [--sugerir-legado] [<raiz>]" >&2; exit 2; }

# Arguments, base and root by the library (R3): writes BASE, HAS_BASE and R (relative roots anchored
# with `./`) and the array HK_FLAGS, where --sugerir-legado is this check's one flag and any other is usage.
hk_base_root_flags "$@" || usage
for hk_f in ${HK_FLAGS[@]+"${HK_FLAGS[@]}"}; do case "$hk_f" in --sugerir-legado) SUG=1 ;; *) usage ;; esac; done
EP="$R/specs/epics"
LEG="$EP/LEGADO-NUMERACAO.md"

if [ ! -d "$EP" ]; then
  say "numeração de épicos: sem specs/epics/ — n.a."
  exit 0
fi

# PR rules: PR=1 only when the base resolves, it is not a promotion, and a starting point exists.
# CANNOT_RUN=1 is set at each point the check itself could not run — read at the end of
# --sugerir-legado (not re-derived from PR/PROMO/HAS_BASE there).
PR=0; PROMO=0; MB=""; CANNOT_RUN=0
if [ "$HAS_BASE" -eq 1 ]; then
  if ! hk_base_resolves "$R" "$BASE"; then
    fail "base $BASE não resolve (git rev-parse)"; CANNOT_RUN=1
  else
    has_dev() {
      git -C "$R" rev-parse --verify --quiet refs/heads/dev >/dev/null 2>&1 && return 0
      case "$BASE" in
        */*/*) return 1 ;;
        */*)   git -C "$R" rev-parse --verify --quiet "refs/remotes/${BASE%%/*}/dev" >/dev/null 2>&1 ;;
        *)     return 1 ;;
      esac
    }
    if hk_pr_to_main "$BASE" && has_dev; then PROMO=1; fi   # G-main
    if [ "$PROMO" -eq 1 ]; then
      say "numeração de épicos: PR para main — as regras de reuso, de renumeração e de par com épico novo são da PR para dev e não foram aplicadas"
    elif ! MB="$(git -C "$R" merge-base "$BASE" HEAD 2>/dev/null)" || [ -z "$MB" ]; then
      fail "sem ponto de partida entre $BASE e HEAD (checkout raso?)"; CANNOT_RUN=1
    else
      PR=1
      if [ "$(git -C "$R" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
        say "AVISO numeração de épicos: checkout raso — o máximo da história do base pode estar subestimado"
      fi
    fi
  fi
else
  say "numeração de épicos: sem base — as regras de reuso, de renumeração e de par com épico novo não foram aplicadas"
fi

# The inputs of the one awk pass (one name or path per line). The three are invoked indirectly — run_awk
# calls them, and hk_awk_records runs run_awk — hence the SC2329 directives.
# shellcheck disable=SC2329
list_head() {
  local f b
  shopt -s nullglob dotglob
  for f in "$EP"/*.md; do
    [ -f "$f" ] || continue
    b="${f##*/}"
    [ "$b" = LEGADO-NUMERACAO.md ] && continue
    printf '%s\n' "$b"
  done | sort
}
# shellcheck disable=SC2329
list_tree() { git -C "$R" -c core.quotePath=false ls-tree --name-only "$1" -- specs/epics/ 2>/dev/null; }
# shellcheck disable=SC2329
list_hist() {
  git -C "$R" -c core.quotePath=false log "$BASE" --full-history --diff-filter=AR --name-only --format= \
    -- specs/epics/ 2>/dev/null
}

# The one awk pass. Inputs: ARGV[1] head epic names (disk, sorted), ARGV[2] starting-point tree paths,
# ARGV[3] base tree paths, ARGV[4] base history paths (all /dev/null without PR rules), ARGV[5] the
# legacy file (/dev/null when absent). Output records, one per line:
#   F<TAB>msg (FAIL)  L<TAB>line (a legacy suggestion)  S<TAB>stats (always last — its absence means awk
#   did not finish).
# shellcheck disable=SC2016 # the program is awk, not shell: nothing in it is meant to expand
PROG='
function fail(m) { print "F\t" m }
function trim(v) { sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v); return v }
function base(p) { sub(/^.*\//, "", p); return p }
function in_form(f) { return f ~ /^[0-9][0-9][0-9]-[a-z0-9]+(-[a-z0-9]+)*\.md$/ }
function num(f) { return substr(f, 1, 3) }
function slug(f) { f = substr(f, 5); sub(/\.md$/, "", f); return f }
function key(a, b) { return ((a "") < (b "")) ? a SUBSEP b : b SUBSEP a }
function collide(a, b) { return a != b && (a in well_formed) && (b in well_formed) && (num(a) == num(b) || slug(a) == slug(b)) }
# is_new(f) — f is new in this PR. No `PR &&` needed here: mark_new is the only writer of `isnew`,
# and it only populates it when PR is true — the guarantee lives there, once.
function is_new(f) { return f in isnew }
function why(a, b) {
  if (is_new(a) && is_new(b)) return "(os dois são novos nesta PR: renomeie um deles antes de o id circular)"
  if (is_new(a)) return "(" a " é novo nesta PR: renomeie-o antes de o id circular)"
  if (is_new(b)) return "(" b " é novo nesta PR: renomeie-o antes de o id circular)"
  return "(colisão antiga: declare o par em LEGADO-NUMERACAO.md)"
}
# A path from git is an epic path iff its directory is specs/epics (ls-tree/log restrict the pathspec).
function epic_path(p) { return p ~ /(^|\/)specs\/epics\/[^\/]+\.md$/ }
function legacy_line(   rest, a, b, m, k, f, wf, dead, miss, lm) {
  if (index($0, "- `") != 1) return
  rest = $0
  wf = match(rest, /^- `[^`\/]+\.md` e `[^`\/]+\.md`/)
  if (wf) { m = trim(substr(rest, RLENGTH + 1)); wf = (m == "" || index(m, "—") == 1) }
  if (!wf) fail("LEGADO-NUMERACAO.md linha " FNR " malformada (forma: - `NNN-nome.md` e `NNN-nome.md` — motivo)")   # G-legmal
  if (!wf) return
  a = substr(rest, 4); sub(/`.*$/, "", a)
  b = substr(rest, 4 + length(a) + 5); sub(/`.*$/, "", b)
  m = trim(substr(m, length("—") + 1))
  f = is_new(a) ? a : (is_new(b) ? b : "")
  if (f != "") { fail("LEGADO-NUMERACAO.md linha " FNR " declara " f ", novo nesta PR — um id novo não se declara, renomeia-se"); return }   # G-legnew
  dead = ""
  if (!(a in present) || !(b in present)) {
    miss = (!(a in present)) ? a : ""
    if (!(b in present)) miss = (miss == "" ? b : miss ", " b)
    dead = "não existem (ausente: " miss ")"
  }
  else if (!collide(a, b)) dead = "não colidem"
  if (dead != "") { fail("LEGADO-NUMERACAO.md linha " FNR " declara " a " e " b ", que " dead); return }   # G-legdead
  lm = tolower(m)
  if (m == "" || m ~ /^<[^>]*>$/ || lm == "[specify]" || lm == "todo" || lm == "n/a") fail("LEGADO-NUMERACAO.md linha " FNR " sem motivo")   # G-legmot
  k = key(a, b)
  if (!(k in decl)) { decl[k] = 1; npairs++ }
}
BEGIN { PR = ENVIRON["EPIC_PR_RULES"] + 0; hmax = -1; tmax = -1; npairs = 0; n = 0 }
FILENAME == ARGV[1] {
  f = $0; if (f == "") next
  present[f] = 1; ord[++n] = f
  if (in_form(f)) { well_formed[f] = 1; if (hk_seq_num(num(f)) > tmax) tmax = hk_seq_num(num(f)) }
  if (!in_form(f)) fail(f " fora da forma NNN-<nome>.md")   # G-form
  next
}
FILENAME == ARGV[2] {
  if (epic_path($0)) {
    f = base($0); inmb[f] = 1
    if (in_form(f)) { k = slug(f); if (k in mbname) mbname[k] = mbname[k] SUBSEP f; else mbname[k] = f }
  }
  next
}
FILENAME == ARGV[3] { if (epic_path($0) && in_form(base($0)) && hk_seq_num(num(base($0))) > hmax) hmax = hk_seq_num(num(base($0))); next }
FILENAME == ARGV[4] { if (epic_path($0) && in_form(base($0)) && hk_seq_num(num(base($0))) > hmax) hmax = hk_seq_num(num(base($0))); next }   # G-hist
FILENAME == ARGV[5] { if (!started) { started = 1; mark_new() }; legacy_line(); next }
function mark_new(   i, f) {
  if (!PR) return
  for (i = 1; i <= n; i++) { f = ord[i]; if (!(f in inmb)) isnew[f] = 1 }
}
END {
  if (!started) mark_new()
  if (hmax < 0) hmax = 0
  # R2/R3 — every pair of in-form epics, in sorted order.
  for (i = 1; i <= n; i++) {
    a = ord[i]; if (!(a in well_formed)) continue
    for (j = i + 1; j <= n; j++) {
      b = ord[j]; if (!(b in well_formed)) continue
      if (!collide(a, b)) continue
      k = key(a, b)
      if (num(a) == num(b) && !(k in decl)) fail("número " num(a) " repetido: " a " e " b " " why(a, b))   # G-num
      if (slug(a) == slug(b) && !(k in decl)) fail("nome " slug(a) " repetido: " a " e " b " " why(a, b))   # G-slug
      if (!(k in decl) && !(is_new(a) || is_new(b))) print "L\t- `" a "` e `" b "` — <motivo>"
    }
  }
  # R4 — reuse and renumbering (PR rules only).
  if (PR) {
    for (i = 1; i <= n; i++) {
      f = ord[i]; if (!is_new(f) || !(f in well_formed)) continue
      if (hk_seq_num(num(f)) <= hmax) fail(f " é novo com número " num(f) ", e o máximo que já existiu no base é " sprintf("%03d", hmax))   # G-reuse
      if (slug(f) in mbname) { mc = split(mbname[slug(f)], mbl, SUBSEP); for (mi = 1; mi <= mc; mi++) if (!(mbl[mi] in present)) { fail(f " renumera " mbl[mi] " — o id do épico é permanente"); break } }   # G-renum
    }
  }
  mx = tmax; if (PR && hmax > mx) mx = hmax; if (mx < 0) mx = 0
  print "S\t" n " épicos; " npairs " pares de legado; máximo " sprintf("%03d", mx)
}
'

# shellcheck disable=SC2329 # invoked indirectly: hk_awk_records runs it
run_awk() {
  local legf=/dev/null
  [ -f "$LEG" ] && legf="$LEG"
  if [ "$PR" -eq 1 ]; then
    # HK_AWK_CHANGELOG in front only for hk_seq_num (the epic NNN, octal-proof on busybox); no changelog read.
    EPIC_PR_RULES=1 awk "$HK_AWK_CHANGELOG$PROG" <(list_head) <(list_tree "$MB") <(list_tree "$BASE") <(list_hist) "$legf"
  else
    # Same reason: HK_AWK_CHANGELOG is here only for hk_seq_num (see hooks-lib.sh → R4); no changelog read.
    EPIC_PR_RULES=0 awk "$HK_AWK_CHANGELOG$PROG" <(list_head) /dev/null /dev/null /dev/null "$legf"
  fi
}

# This check's record handler; the loop, the S record (HK_STATS) and the sentinel are the library's
# (hk_awk_records, R3). F = a FAIL (with --sugerir-legado nothing printed, nothing set — that mode's
# exit comes from CANNOT_RUN, not from a finding), L = one legacy suggestion line.
sugg=""
# shellcheck disable=SC2329 # invoked indirectly: hk_awk_records calls it per record
epic_record() {
  case "$1" in
    F) [ "$SUG" -eq 1 ] || fail "$2" ;;
    L) sugg="$sugg$2"$'\n' ;;
  esac
}
# No stats record = awk did not finish: never a silent pass (I3) — exit 1 at once, in either mode.
if ! hk_awk_records epic_record run_awk; then
  echo "FAIL - numeração de épicos: leitura de $EP não terminou (awk)" >&2
  exit 1
fi

if [ "$SUG" -eq 1 ]; then
  printf '%s' "$sugg"
  # Only a check that could not run fails here: base that does not resolve, or no starting point —
  # CANNOT_RUN is set once, at each of those two fail() call sites, not re-derived here.
  [ "$CANNOT_RUN" -eq 1 ] && exit 1
  exit 0
fi

hk_pass_line "numeração de épicos" "$bad"; exit $?
