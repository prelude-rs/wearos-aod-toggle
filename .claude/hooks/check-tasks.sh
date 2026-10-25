#!/usr/bin/env bash
# check-tasks.sh — the MECHANICAL AUTHORIZATION of tasks.md. Replaces the human plan-review gate
# (change 2026-09-tasks-sem-gate-2).
#
# WHAT IT ASSERTS, and why this IS the authorization: if every functional requirement in spec.md maps
# to at least one task AND every task cites a requirement that exists, then the plan is PROVABLY a
# decomposition of the approved spec+design — nothing more, nothing less. That is stronger than the
# `Status: Approved` flag it replaces, which asserted nothing checkable.
#
# WHY IT LIVES IN .claude/hooks/ AND NOT IN tests/: `tests/` is `class: kit-local`/`never-copy` in
# .claude/adopt/manifest.yaml, so a check there NEVER reaches an adopting repo — the adopter would get
# the gate's removal (doctrine travels via the portable skills) and not the assertion that replaces it.
# Precedent: `verify-archived-gates.sh` is also a CI check rather than a Claude hook, lives here, and is
# `portable`. This directory is "portable enforcement scripts", not "Claude Code hooks".
#
# TWO FORMS, ONE JUDGMENT (change 2026-09-design-com-decomposicao). The plan now lives in the DESIGN:
# `design.md` carries a `## Decomposição` section whose `### Task N` blocks each declare `**Refs:**`
# (and optionally `**Visual:** sim`), and `tasks.md` becomes a derived LEDGER of execution state with no
# `Refs` column at all. So this check reads BY FORM: a design that carries the section puts coverage,
# phantoms, the cap and the VISUAL assertion on the blocks, and the ledger — when it exists — is
# aferido AGAINST them; a design without it runs the previous path unchanged. There is no
# grandfathering flag, no date and no allowlist in that decision: the form of the artifact decides.
# A missing ledger is NOT a failure in the new form (it is generated at implementation start), but it is
# never silent either — it prints a `say` line.
# ONE FOLDER, IN UNITS (2026-10-check-tasks-por-dentro, R2) — no unit mixes the two forms:
#   check_change         the form-neutral preamble (fast-lane SKIP, spec.md, the form detection, the
#                        proposal SKIPs), the spec.md table, and the DISPATCH; it declares the folder's
#                        variables and the plan interface, and reads no plan of either form
#   precheck_new_form    the new form's precondition: the block count, the empty-decomposition SKIP
#   read_plan_new_form   the plan in design.md § Decomposição, and (h)
#   read_ledger_new_form the derived ledger, aferido against the blocks: (f), (g), the closing rows
#   judge_sot_decl       the spec's "Seções do SoT afetadas" declaration (R4 of 2026-10-check-tasks-defeitos)
#   precheck_old_form    the old form's precondition: tasks.md must exist (its FAIL alone ends the run
#                        with exit 3)
#   read_plan_old_form   the plan in tasks.md
#   judge_plan           (a)–(e) on the plan interface, blind to the form that filled it
# The units share check_change's locals by bash dynamic scoping (the idiom of alarm_class).
#
# EVERY READ IS BY NAME OR BY VALUE, NEVER BY POSITION OR BY TEXT SCAN. That is not style: this lineage
# catalogued fifteen instances of "proxy vs. thing" — position for name, ordinal for name, scan for
# value, "contains" for anchored — several of them committed while fixing the previous one. The NINE
# reading points are `Refs` (by header name), the acceptance cell (by header name), `Visual` (by cell
# value), `NO-TASK:` (anchored at cell start), the closing rows (`Task` and `Refs` by header name,
# with `Refs = all` as the structural discriminator — token presence alone is NOT sufficient), and the
# four the new form adds: the FORM ITSELF (a line that is exactly `## Decomposição`, never "contains"),
# the implementation blocks (by their `### Task N` heading, never by proximity), each block's requirement
# list (by the `**Refs:**` LABEL at the start of a field line, first one wins, never by scanning the
# block for `R\d+`), and the ledger's task number (by the `#` COLUMN NAME — the old form reads it at
# index 0, a proxy that merely happens to be right).
# The spec's "Seções do SoT afetadas" declaration (R4 of 2026-10-check-tasks-defeitos) is OUTSIDE the
# nine: it is read by the library's sot_decl_of (hooks-lib.sh), the archive gate's own reader, not here.
# The fifth was added on 2026-09-10 after the validation-gate showed this very header claiming four
# while the closing-row read used a fixed index and an unanchored match: the two techniques it denies.
# Invariant I3 of epic 003 demands that a MENTION never pass for a WRITE, and these nine are where it
# would break.
# THE NEW-FORM LEDGER IS READ ONE WAY (2026-10-check-tasks-por-dentro, R1): the check and the generator
# find its header, name its columns and test its closing rows through the SAME definitions —
# `find_ledger_header`, `ledger_col` (ANCHORED: the cell that IS `#`/`Task`/`Visual`, never one that
# merely contains the name), `refs_col`, the three token tests `names_validation_gate`,
# `starts_with_signoff` and `has_closing_token`, and the line reader `is_ledger_sep`/`ledger_line_kind` —
# so the two can no longer disagree about the same ledger. Three things stay per reader, on purpose:
# WHICH rows each submits to the closing tests (Ricardo, 2026-10-08 — see those definitions); the table's
# extent (what a non-table line before the first data row means: `ledger_line_kind`, mode `check` or
# `gen`); and the old-form tasks.md, which only the check reads and which keeps its own "contains" column
# reads.
#
# Usage: check-tasks.sh [dir...]             (default: every folder in specs/proposed/ and specs/active/)
#        check-tasks.sh --ledger <dir>       (refresh that folder's tasks.md TABLE from the design; the
#                                             file must already exist — copy specs/templates/tasks.md.
#                                             `--ledger` is a mode, accepted anywhere in the argv.)
#        check-tasks.sh --estado <dir>       (print the new-form ledger's STATE, one line per task:
#                                             `N<TAB>VISUAL|—<TAB>Status`, closing rows left out. Exit 3 =
#                                             old form (design without `## Decomposição`), 2 = a named
#                                             refusal (stdout empty), accepted anywhere in the argv.)
#        check-tasks.sh --transcricao [dir...]  (the launcher passes this right before transcribing a
#                                             design: in specs/proposed/, a design without
#                                             `## Decomposição` FAILs instead of SKIPping — accepted
#                                             anywhere in the argv, same idiom as `--ledger`.)
#
# In specs/proposed/ (a change still under discussion, before Gate 1.5): a folder with no design.md is
# SKIPped named (cobertura e report n.a.); a folder whose design has no `## Decomposição` SKIPs too in
# the default mode and FAILs under `--transcricao`; a folder whose design HAS the section but ZERO
# `### Task N` blocks (the shape `specs/templates/design.md` has the moment it is copied into a new
# proposal) SKIPs too, named, but ONLY in the default mode — under `--transcricao` it falls through to
# the normal coverage aferição, unchanged (2026-10-hooks-defeitos-e-pin, R1); tasks.md is never required
# there (the ledger is born in specs/active/, at implementation start). specs/active/ keeps today's
# rules unchanged.
# Exit 0 = every folder authorized. Exit 1 = at least one is not, for a reason other than the one of exit 3
# (or for that reason AND another); the output names the culprit.
# Exit 2 = the `--ledger` generator refused (usage, or a precondition it names).
# Exit 3 = at least one folder is not authorized and EVERY failure of the run is the old form's missing
# `tasks.md` ("tasks.md ausente.") — no other FAIL in the same run. The launcher's design transcription
# decides by this code (not by the text): it can create the ledger and go on.
#
# Comments/logic in English, user-facing messages in pt-BR — spec-layout, "Language & rendering".
# Common hook library, loaded FIRST (before `set`, before any argument — so even `--ledger`, whose 2 is
# the generator's refusal): without it this check exits 1 naming it (R2 of
# 2026-10-biblioteca-comum-dos-hooks). `[ -r ]` + `command .`: a plain failed `.` is fatal under
# POSIXLY_CORRECT and would exit before the message. Found next to THIS file (BASH_SOURCE).
case "${BASH_SOURCE[0]}" in */*) HK_DIR="${BASH_SOURCE[0]%/*}" ;; *) HK_DIR=. ;; esac
# The EXIT trap around the load (fd 9, `|| exit`, HK_LIB_GONE, `trap - EXIT`; exit 1): see hooks-lib.sh →
# "Who loads it".
HK_LIB_GONE="sdd-kit: biblioteca dos hooks ausente ou ilegível: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não roda sem ela (instalação incompleta?)"
trap 'echo "$HK_LIB_GONE" >&9; exit 1' EXIT
{ [ -r "$HK_DIR/hooks-lib.sh" ] && command . "$HK_DIR/hooks-lib.sh" || exit; } 9>&2 2>/dev/null
trap - EXIT
{ declare -F mode_of strip_html_comments sot_decl_of sot_sections hk_sot_heading_lines hk_git_env_clean >/dev/null && [ -n "${HK_AWK_SHC-}" ]; } || { echo "sdd-kit: biblioteca dos hooks incompleta: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não roda sem ela (instalação incompleta?)" >&2; exit 1; }
hk_git_env_clean   # the repository read (the SoT at HEAD) is the cwd's: see hooks-lib.sh → hk_git_env_clean
set -uo pipefail

fail=0
other_fail=0   # R3 (2026-10-check-tasks-defeitos): 1 once any FAIL OTHER than "tasks.md ausente." (old form, no ledger) ran
avisos=0   # global counter for the R2 onde-dentro alarm; printed once, after the folder loop, always.
sot_head=""; sot_head_read=0   # R4: `sot_sections HEAD`, read once per run, only when a folder declares a heading
transcricao_mode=0   # --transcricao (2026-09-change-parada-em-active): a GLOBAL, written by the entry point's
                      # argv scan and read by check_change.

# --- table reading --------------------------------------------------------------------------------
# SENT — the cell reader's SENTINEL for an escaped pipe. It used to be `§`, a PRINTABLE glyph, and the
# new form made that a live corruption: the generated ledger writes `design.md § Task N`, so a human
# typing `§` in a `Notas` cell (e.g. "ver design.md § Task 1") had it turned into a BARE `|` the moment
# `cell_at` unescaped the cell — the generator would then write a row whose arity the check rejects.
# The fix (Ricardo, 2026-09-21) is a CONTROL character: `\001` cannot appear in a markdown artifact, so
# the round trip is closed for every printable text, in both forms, without touching the template or the
# pointer's glyph. Built with `printf` rather than written as `\x01` inside the sed script because
# `\xNN` is a GNU extension — a literal byte in the script is what POSIX sed reads everywhere.
SENT="$(printf '\001')"
# cells <row> -> one trimmed cell per line. `\|` is normalised to SENT BEFORE splitting: an escaped pipe
# is markdown for a literal pipe and must NOT split the row. Idiom copied from
# tests/check-epic-closing.sh, which carries it because escaped pipes already bit this repo.
cells() { printf '%s' "$1" | sed 's/\\|/'"$SENT"'/g' | awk -F'|' '{for(i=2;i<NF;i++){gsub(/^ +| +$/,"",$i); print $i}}'; }
ncells() { cells "$1" | wc -l | tr -d ' '; }
# cell_at <row> <0-based index> -> the cell's TEXT (an escaped pipe comes back as a literal `|`).
cell_at() { cells "$1" | sed -n "$(( $2 + 1 ))p" | sed 's/'"$SENT"'/|/g'; }
# cell_raw <row> <0-based index> -> the cell exactly AS WRITTEN in the source row (`\|` stays escaped).
# The generator preserves cells by copying them back into a row, and a cell read as TEXT would lose the
# escape and break the row's arity on the next read. Same reader, different exit: text for judging, raw
# for rewriting.
cell_raw() { cells "$1" | sed -n "$(( $2 + 1 ))p" | sed 's/'"$SENT"'/\\|/g'; }
# idx_of <header-row> <needle> -> 0-based indices of cells containing needle, one per line
idx_of() { cells "$1" | grep -n "$2" | cut -d: -f1 | awk '{print $1-1}'; }
# idx_re <header-row> <ERE> -> 0-based indices of cells MATCHING the ERE, one per line. The cells are
# already trimmed, so `^` and `$` anchor the whole cell.
# WHY NEITHER "CONTAINS" NOR "EQUALS": the "contains" read of idx_of is right for finding a column
# whose name carries a qualifier, but WRONG for a detector that fires on the column's mere presence —
# a cell that only MENTIONS the name (`Notas (sem Refs — agora no design)`) would fire it. Exact
# equality fixes that and breaks the other half: the kit's OWN legacy spelling of the column is
# `Refs (R*)` (the header of 43 archived ledgers), so an equality detector for `Refs` never sees the
# very copy it exists to catch. The read that holds both ends is an ANCHORED PREFIX: the cell must
# BEGIN with `Refs` and the next character must be a space, a `(`, or the end of the cell — so
# `Refs`, `Refs (R*)` and `Refs R*` all fire, while `Notas (sem Refs — agora no design)` (no prefix)
# and `Referências` (letter follows) do not.
idx_re() { cells "$1" | grep -nE "$2" | cut -d: -f1 | awk '{print $1-1}'; }

# --- the ledger, read ONE way (R1) ----------------------------------------------------------------
# The check's two readers and the generator read the ledger through these definitions, each written
# once (C:S1: the header loop, the column grammar, the `Refs` prefix and the closing tokens used to be
# spelled in each reader). NOT a definition here, on purpose (Ricardo, 2026-10-08): WHICH rows a reader
# submits to the closing tests. The check judges the last two rows of the table's run
# (`closing_gate_row`/`closing_signoff_row`, in (d)); the generator takes, anywhere in the table, the first
# non-numeric row that passes each test and writes it at the end. The tests are one; the choice of the
# row to test stays two, byte for byte as before.
#
# find_ledger_header <tasks.md> — the first line that is `|`…`#`…`|`. WRITES the caller's
# `ledger_hdr_row` (the line), `ledger_hdr_line` (its number; 0 when there is none) and
# `ledger_hdr_cells` (its cell count, by ncells; computed only when the header is found, 0 otherwise)
# by dynamic scoping: the caller declares the three. Returns 0.
find_ledger_header() {
  local n=0 line
  ledger_hdr_row=""; ledger_hdr_line=0; ledger_hdr_cells=0
  while IFS= read -r line; do
    n=$((n + 1))
    case "$line" in \|*\#*\|*) ledger_hdr_row="$line"; ledger_hdr_line=$n; break ;; esac
  done < "$1"
  [ "$ledger_hdr_line" -eq 0 ] || ledger_hdr_cells="$(ncells "$ledger_hdr_row")"
  return 0
}
# is_ledger_sep <line> — 0 when the line is the table's markdown separator row (only `|`, `:`, `-` and
# spaces): not data, for the check and for the generator.
is_ledger_sep() { grep -qE '^[|: -]+$' <<< "$1"; }
# ledger_line_kind <line> <started> <check|gen> — what a line below the ledger header is to the
# reader. WRITES the global `LEDGER_KIND`: `sep` (a `|` line that is_ledger_sep), `row` (any other `|`
# line), and for a line that does not start with `|`: `skip` in mode `check` while <started> is 0 (no
# data row read yet), `end` in every other case. <started> is ignored in mode `gen`. Returns 0.
# THE MODE IS THE READER'S, and the two readings differ ON PURPOSE (design of 2026-10-hooks-sem-restos,
# "Data modeling"): the check tolerates a non-table line — a blank, a line of prose — before the first
# data row and reads the rows below it; the generator ends the table there, and its own bookkeeping
# (`break_n`/`break_kind`/`resume_n`) refuses the resumed table by name. Past the first data row both
# end the table. One definition, so the two readings sit side by side in one place.
LEDGER_KIND=""
ledger_line_kind() {
  case "$1" in
    \|*) if is_ledger_sep "$1"; then LEDGER_KIND=sep; else LEDGER_KIND=row; fi ;;
    *) if [ "$3" = check ] && [ "$2" -eq 0 ]; then LEDGER_KIND=skip; else LEDGER_KIND=end; fi ;;
  esac
  return 0
}
# ledger_col <header-row> <name> -> the 0-based index of the first cell that IS <name> once trimmed;
# empty when none is. The ANCHORED grammar — the generator's, which only rewrites a header that is its
# own byte for byte, so it could never adopt "contains" without accepting headers it refuses. Names:
# `#`, `Task`, `Visual`, `Status`, `Commit`, `Notas` (none carries an ERE metacharacter).
ledger_col() { idx_re "$1" "^$2\$" | head -1; }
# REFS_HDR_ERE / refs_col <header-row> -> the index of the first cell of the `Refs` family (`Refs`,
# `Refs (R*)`, `Refs (R*/N*)`), by ANCHORED PREFIX; empty when none. The only column read by prefix —
# idx_re's comment says why. (g) and the generator's refusal of an old-form ledger.
REFS_HDR_ERE='^Refs([[:space:]]|\(|$)'
refs_col() { idx_re "$1" "$REFS_HDR_ERE" | head -1; }
# The three closing-row TOKEN tests. Each is named for the TOKEN it tests, not for the row a reader
# submits to it (that choice is per reader, above). Three, not two: "mentions either token, in any text"
# is another question than "the Task cell names the gate" or "the Task cell starts with the sign-off",
# and folding it into those would change verdicts (Decisions log).
# BASH BUILTINS, NOT A grep PER ROW (N5 of 2026-10-check-tasks-defeitos: a process per closing row, per
# folder, was most of what the change added to the run). The class is `grep -i`'s, measured code point
# by code point: ASCII letters in explicit `[Xx]` brackets — never `${1,,}`, which maps `İ` to `i` where
# `grep -i` does not — and a cell holding `ı`, `ſ` or `İ` goes to grep itself, because `ı` and `ſ` are the
# only code points GNU grep -i folds into a letter of these tokens (C.UTF-8, en_US.UTF-8, pt_BR.UTF-8)
# and `İ` is where a lowercasing reader departs from it. `[[:space:]]` is the locale's in both readers.
# On the here-string fallback a cell never holds a newline, so the one the here-string appends matches
# exactly what a pipe did, and the status is grep's, with no producer in a pipe under pipefail.
# The `[Xx]` classes above and the `grep -i` patterns in the two functions below are ONE class written
# twice: change one, change the other.
TOK_GATE_GLOB='*[Vv][Aa][Ll][Ii][Dd][Aa][Tt][Ii][Oo][Nn]-[Gg][Aa][Tt][Ee]*'
TOK_SIGN_GLOB='*[Ss][Ii][Gg][Nn]-[Oo][Ff][Ff]*'
TOK_SIGN_ERE='^\*{0,2}[[:space:]]*([Hh][Uu][Mm][Aa][Nn][[:space:]]+)?[Ss][Ii][Gg][Nn]-[Oo][Ff][Ff]'
# tok_folds <text> — 0 when the text holds one of the three code points above (the grep fallback).
tok_folds() { case "$1" in *ı*|*ſ*|*İ*) return 0 ;; esac; return 1; }
# names_validation_gate <Task-cell> — 0 if the cell CONTAINS `validation-gate`, case-insensitively.
names_validation_gate() {
  if tok_folds "$1"; then grep -qi 'validation-gate' <<< "$1"; return; fi
  # shellcheck disable=SC2254  # the variables ARE glob patterns
  case "$1" in $TOK_GATE_GLOB) return 0 ;; esac; return 1
}
# starts_with_signoff <Task-cell> — 0 if the cell STARTS with the `sign-off` token (optional `**` and
# `Human `), case-insensitively. Anchored, not "contains": see (d).
starts_with_signoff() {
  if tok_folds "$1"; then grep -qiE '^\*{0,2}[[:space:]]*(Human[[:space:]]+)?sign-off' <<< "$1"; return; fi
  [[ $1 =~ $TOK_SIGN_ERE ]]
}
# closing_kind <Task-cell> -> CLOSING_KIND = `signoff`, `gate` or empty: the ONE class of a closing row,
# for the reader that COUNTS them (the new form's repeated-row test and the generator's choice). Written
# to a variable, not printed: a `$(…)` per row was two subshells (N5). The sign-off is tested FIRST — it
# is anchored at the cell's start, while the gate matches anywhere — so `sign-off após validation-gate`
# is a sign-off. (d) stays positional and does not call this.
CLOSING_KIND=""
closing_kind() {
  CLOSING_KIND=""
  if starts_with_signoff "$1"; then CLOSING_KIND=signoff
  elif names_validation_gate "$1"; then CLOSING_KIND=gate
  fi
}
# repeated_closing <token> <lines> -> REPEATED_CLOSING = "<token> nas linhas a e b" (or "a, b e c") when
# the space-separated list names MORE than one file line, empty otherwise: the repeated-closing-row
# clause, shared by the check's FAIL and the generator's refusal so the two name the same thing in the
# same words. Written to a variable, not printed (N5, as closing_kind).
REPEATED_CLOSING=""
repeated_closing() {
  local tok="$1" out="" n rest
  REPEATED_CLOSING=""
  # shellcheck disable=SC2086
  set -- $2
  [ "$#" -gt 1 ] || return 0
  rest=$#
  for n in "$@"; do
    rest=$((rest - 1))
    if [ -z "$out" ]; then out="$n"; elif [ "$rest" -eq 0 ]; then out="$out e $n"; else out="$out, $n"; fi
  done
  REPEATED_CLOSING="$tok nas linhas $out"
}
# count_closing <Task-cell> <line> — the ONE counting of a closing row, shared by the check and the
# generator: closing_kind classifies the cell (left in CLOSING_KIND for the caller) and the line is
# appended to the CALLER's gate_lns / sign_lns (dynamic scope). Each caller keeps its own messages.
count_closing() {
  closing_kind "$1"
  case "$CLOSING_KIND" in
    gate) gate_lns="$gate_lns $2" ;;
    signoff) sign_lns="$sign_lns $2" ;;
  esac
  return 0
}
# repeated_closings — REP_GATE / REP_SIGN, from the caller's gate_lns / sign_lns, one repeated_closing per
# token; the check and the generator word their own message around them.
REP_GATE=""; REP_SIGN=""
repeated_closings() {
  repeated_closing "validation-gate" "$gate_lns"; REP_GATE="$REPEATED_CLOSING"
  repeated_closing "sign-off" "$sign_lns"; REP_SIGN="$REPEATED_CLOSING"
  return 0
}
# Physical (cd -P) on purpose, unlike the lexical is_proposed_dir: a link in active/ pointing at an
# archive folder is NOT judged by the rule that starts to FAIL, and a link from outside specs/ to a live
# folder IS (the suite's symlink cases lock both).
# is_live_dir <dir> -> 0 when the PHYSICAL directory (cd -P) sits under specs/proposed/ or specs/active/:
# its parent is named `proposed` or `active` and its grandparent `specs`. Where the repeated-closing-row
# rule and R4 apply; an archived folder is not judged by them. check_change asks it ONCE per folder (its
# `live`). One subshell for the physical path; parent and grandparent by parameter expansion (`pwd -P`
# prints an absolute path with no trailing `/`, so `${p%/*}` is dirname and `${p##*/}` basename; at the
# root both come out empty instead of `/`, and neither is `proposed`, `active` or `specs` either way).
is_live_dir() {
  local p parent gp
  p="$(cd -P -- "${1%/}" 2>/dev/null && pwd -P)" || return 1
  p="${p%/*}"; parent="${p##*/}"
  p="${p%/*}"; gp="${p##*/}"
  { [ "$parent" = "proposed" ] || [ "$parent" = "active" ]; } && [ "$gp" = "specs" ]
}
# has_closing_token <text> — 0 if the text MENTIONS `validation-gate` or `sign-off` anywhere,
# case-insensitively: the check's guard for a non-numeric `#` and the generator's split-table resume.
has_closing_token() {
  if tok_folds "$1"; then grep -qiE 'validation-gate|sign-off' <<< "$1"; return; fi
  # shellcheck disable=SC2254  # the variables ARE glob patterns
  case "$1" in $TOK_GATE_GLOB|$TOK_SIGN_GLOB) return 0 ;; esac; return 1
}

# expand_ids <text> -> R-ids, one per line. Expands ranges (R1–R7, R1—R7, R1-R7, R1-7) because they
# exist in the corpus (2026-07-30-2026-07-fog-no-epico) and a plain grep loses the middle of the range.
expand_ids() {
  printf '%s' "$1" | sed 's/[–—]/-/g' \
    | awk '{
        s=$0
        while (match(s, /R[0-9]+[[:space:]]*-[[:space:]]*R?[0-9]+/)) {
          r=substr(s,RSTART,RLENGTH); rest=substr(s,RSTART+RLENGTH)
          split(r,p,/[[:space:]]*-[[:space:]]*R?/); a=p[1]; sub(/^R/,"",a); b=p[2]
          for(i=a+0;i<=b+0;i++) print "R" i
          s=rest
        }
        print s
      }' \
    | grep -oE 'R[0-9]+[a-z]?' | sort -u
}

# expand_ids_any <text> -> R-ids AND N-ids. FOR (h) ONLY, and the asymmetry is the point: coverage
# ((a)/(b)) is about FUNCTIONAL requirements, so `expand_ids` stays R-only and an `N*` id contributes
# nothing to it; but a block whose `**Refs:**` names only `N1` is a LEGAL task (an NFR-measurement
# one — `specs/templates/design.md` writes `**Refs:** R1, N2` in its own Task 1), and (h) must not
# read it as "bloco sem requisito". So (h) asks "does this line name ANY id?" with this reader, while
# the coverage math keeps asking "which R* does it name?" with the other.
#
# THE N-id IS READ AT A TOKEN BOUNDARY, not anywhere in the text: an unanchored `N[0-9]+` finds an id
# inside a longer word (`ISO-N9000`, `EN9100`), and (h) — whose whole job is to catch a `**Refs:**`
# line that names no requirement — would then read a standards citation as a requirement and stay
# quiet. The id must be at the start of the text or follow a character that cannot be part of a token:
# no letter, no digit, and NO HYPHEN, because a hyphenated token is one word. (No `\b`: mawk has none.
# grep -oE keeps the boundary character in the match, so `sed` trims back to the `N`.) The hyphen
# exclusion costs nothing here: `expand_ids` expands R-ranges only, N-ranges were never expanded, and
# (h) asks only whether ANY id is present — the first id of `N1-N3` still answers that.
expand_ids_any() {
  { expand_ids "$1"
    printf '%s' "$1" | grep -oE '(^|[^A-Za-z0-9-])N[0-9]+[a-z]?' | sed 's/^[^N]*//' || true
  } | grep -v '^$' | sort -u
}

# strip_html_comments <file> — the body with every `<!-- ... -->` span removed, one output line per input
# line (line numbers preserved): defined once, in hooks-lib.sh (R1 of 2026-10-hooks-sem-restos), loaded above.

# blank_fences <body> -> the same body with every line of every fenced block — the fence lines
# included — replaced by an EMPTY line. One output line per input line, so LINE NUMBERS ARE PRESERVED,
# exactly as in strip_html_comments (hooks-lib.sh): (g) still points the human at a real line of the
# real file.
# WHY IT EXISTS: a fenced `### Task 2` + `**Refs:** R2` is an EXAMPLE, not a plan. Without this the
# check credited R2 as covered and counted the fake block against the cap, while the Superpowers brief
# extractor — which IS fence-aware — never dispatched it: the check would authorize a plan nobody
# could execute. Same "mention is not a write" invariant (I3) as every other reading point here.
#
# BOTH FENCE SPELLINGS, AND INDENTED ONES. CommonMark opens a fence on ``` OR ~~~ and allows up to
# three leading spaces — and a fence nested in a list item is indented by construction, which is
# exactly how a design quotes an example block inside a bullet. A reader that only knew column-zero
# backticks left those two spellings as holes of the same shape as the one this function was written
# to close. The opening fence's CHARACTER is remembered and only that character closes the block, so
# a ~~~ line quoted inside a ``` block does not end it (and vice versa) — the toggle-on-anything
# version would have reopened the rest of the file as prose.
blank_fences() {
  printf '%s\n' "$1" | awk '
    {
      line = $0; sub(/^[[:space:]]+/, "", line)
      if (infence) {
        if ((fc == "`" && line ~ /^```/) || (fc == "~" && line ~ /^~~~/)) { infence = 0; fc = "" }
        print ""; next
      }
      if (line ~ /^```/) { infence = 1; fc = "`"; print ""; next }
      if (line ~ /^~~~/) { infence = 1; fc = "~"; print ""; next }
      print
    }
  '
}

# BLOCK_AWK — the grammar of a `### Task N` block, spelled ONCE: awk program text made only of function
# definitions, concatenated IN FRONT of each block reader's own program (`awk "$BLOCK_AWK"'…'`, the
# idiom of the library's HK_AWK_CHANGELOG). Its readers: blocks_of (opens on is_task_open, closes on
# is_section_end), justif_of (stops on either) and the old form's `**Visual:** sim` reader in tasks.md
# (opens on is_task_open; its own end, any `^###`, is the old format's rule and stays in it). The
# regexes are static — no ENVIRON, no -v — so the three awks read the same bytes as before. The four:
#   is_task_open(l)   a block OPENS: `^###`, optional blanks, `Task`, optional blanks, a digit (the old
#                     form's `[0-9]+` was the same prefix test)
#   is_section_end(l) a block CLOSES at a level-2 heading: `^##` followed by a blank
#   is_visual_mark(l) the `**Visual:** sim` mark: a field line (starts with `**`) carrying the marker
#   task_num(l)       the N of an opening line: the `### Task` prefix stripped, then everything from the
#                     first non-digit on (`### Task 0` → 0; the numbering check judges it, not this)
# None of the three barred forms: no call-space-paren concatenation, no brace interval, no pipe.
# shellcheck disable=SC2016 # awk program text: nothing in it is meant to expand
BLOCK_AWK='
function is_task_open(l) { return (l ~ /^###[[:space:]]*Task[[:space:]]*[0-9]/) }
function is_section_end(l) { return (l ~ /^##[[:space:]]/) }
function task_num(l,   n) { n = l; sub(/^###[[:space:]]*Task[[:space:]]*/, "", n); sub(/[^0-9].*$/, "", n); return n }
function is_visual_mark(l) { return (l ~ /^\*\*/ && l ~ /\*\*Visual:\*\*[[:space:]]*sim/) }
'

# blocks_of <comment-stripped design body> -> one TAB-separated record per implementation block:
#   N <TAB> VISUAL|— <TAB> 1|0 <TAB> <text after the block's first `**Refs:**` label>
# The third field (1 = yes, 0 = no) says whether the block HAS a `**Refs:**` field line at all, which
# the fourth cannot: an absent label and a label with an empty value both yield empty text, and (h)
# must tell them apart to name the right defect.
#
# The body is read through `blank_fences` FIRST: a ``` fenced `### Task N` is an example of the form,
# never a block. Everything else reads the blanked body, so the two states cannot disagree.
#
# A block OPENS at `^### Task N` and CLOSES at the next `^### Task`, at the next LEVEL-2 heading
# (`^## `) or at EOF. Level-2 closes it because a `**Refs:**` line in a LATER section (`## Apêndice`)
# was otherwise attributed to the last block — a field line of a section that is not a block at all.
# Deeper/other `###` headings still do NOT close it (a block may carry sub-headings).
#
# HEADING GRAMMAR — an ACCEPTED DIVERGENCE, documented rather than fixed: the Superpowers brief
# extractor dispatches on `^#+[ \t]+Task[ \t]+[0-9]+` (ANY heading level) while this check opens a
# block only on `^###`. So `#### Task 3` is not a block here — it counts for neither the cap (c) nor
# coverage (a). The kit's template writes `### Task N` and a deeper heading inside a block is a step,
# not a task; aligning the two grammars would make every sub-heading a task. If a design ever needs
# `#### Task`, change the grammar (BLOCK_AWK, above) on purpose, with a fixture.
#
# Reading points, all by name:
#   - `**Refs:**` by LABEL at the start of a field line; the FIRST one in the block wins (a second is
#     ignored here and the consistency-gate's report may point at it).
#   - `**Visual:** sim` by the same field-line discipline the old form uses inside tasks.md: the line
#     must START with `**`, so a CITATION of the marker in prose is not a marking.
# Emitted as data (not judged here) so the `--ledger` generator can consume the same reader.
blocks_of() {
  blank_fences "$1" | awk "$BLOCK_AWK"'
    function flush() { if (n != "") print n "\t" vis "\t" has "\t" refs }
    is_task_open($0) {
      flush()
      n=task_num($0)
      vis="—"; has=0; refs=""; next
    }
    is_section_end($0) { flush(); n=""; next }
    n != "" && has == 0 && /^\*\*Refs:\*\*/ { refs=$0; sub(/^\*\*Refs:\*\*/,"",refs); has=1 }
    # no `next` above: the Refs line is ALSO a field line: an author may write
    # `**Refs:** R1 · **Visual:** sim` on it (the template uses separate lines), and R1 reads the mark
    # there too
    n != "" && is_visual_mark($0) { vis="VISUAL" }
    END { flush() }
  '
}

# justif_of <comment-stripped design body> -> ausente | vazia | presente — the SIZING JUSTIFICATION's
# state (change 2026-09-teto-vira-justificativa, R2/R3). Read ONLY where the template teaches it: from
# the literal `## Decomposição` line to the first line that opens a block — BLOCK_AWK's is_task_open,
# as in blocks_of — or the next `## ` heading (its is_section_end), through the SAME two filters (the
# caller passes the comment-stripped body; blank_fences here). So a label inside `<!-- -->`, inside a fence
# or inside a
# `### Task N` block is never read (R3): "ausente", and the FAIL says where to write it.
# The label is ANCHORED at column zero, bold with the colon inside; the FIRST labelled line wins. The
# value is the rest of the line, trimmed. `vazia` = empty, or ENTIRELY a placeholder: `<…>` (anything
# between `<` and `>` with no other text), `[SPECIFY]`, `TODO`, `N/A` (the last three case-blind). Any
# other text is `presente` — the check affers PRESENCE; merit is the consistency-gate's 6c.
# JUSTIF_LABEL is the label, spelled ONCE: justif_of reads it through ENVIRON (never `awk -v`, whose
# escape processing would touch it; under LC_ALL=C `index` and `length` count bytes, as with the
# literal), and the (c) FAIL interpolates it into the message.
JUSTIF_LABEL='**Justificativa de dimensionamento:**'
justif_of() {
  blank_fences "$1" | JUSTIF_LABEL="$JUSTIF_LABEL" LC_ALL=C awk "$BLOCK_AWK"'
    BEGIN { label = ENVIRON["JUSTIF_LABEL"] }
    !in_sec { if ($0 == "## Decomposição") in_sec = 1; next }
    is_task_open($0) || is_section_end($0) { exit }
    index($0, label) == 1 {
      v = substr($0, length(label) + 1)
      sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v)
      lv = tolower(v)
      if (v == "" || v ~ /^<[^>]*>$/ || lv == "[specify]" || lv == "todo" || lv == "n/a") st = "vazia"
      else st = "presente"
      exit
    }
    END { print (st == "" ? "ausente" : st) }
  '
}

# has_decomp <comment-stripped design body> — 0 when the body, fences blanked, has a line that IS
# exactly `## Decomposição` (never "contains"): the FORM DETECTION, spelled once. The check's form
# detection and the generator's precondition call it, so the generator can never emit a ledger for a
# form the check would judge by the other path. Capture first, then grep a here-string — never
# `producer | grep -q` as a condition under pipefail: grep -q exits on the first match, a producer still
# writing (busybox awk, or any awk past its output buffer) dies of SIGPIPE, and pipefail turns the match
# into a failure (measured: 196/200 with busybox).
has_decomp() { grep -qx '## Decomposição' <<< "$(blank_fences "$1")"; }

# read_blocks <comment-stripped design body> — THE block count (R4), read once per folder, new form
# only. WRITES the caller's `blocks` (blocks_of's records) and `n_blocks` (its non-empty lines) and
# declares neither: bash dynamic scoping lands both in check_change's locals (called from
# precheck_new_form) or in gen_ledger's. The proposal SKIP, the new form's `impl` and the generator's
# "0 blocos" refusal all
# read `n_blocks`. Returns 0.
read_blocks() {
  blocks="$(blocks_of "$1")"
  n_blocks="$(printf '%s' "$blocks" | grep -c . || true)"
  return 0
}

say()  { echo "  $1"; }
bad()  { echo "FAIL - $1" >&2; fail=1; other_fail=1; }
# bad_no_ledger — the ONE failure that is not "other": the old form without tasks.md. Same print as `bad`, but
# `other_fail` stays as it was, so the run can tell "only this" (exit 3) from "this and more" (exit 1).
bad_no_ledger() { echo "FAIL - $1" >&2; fail=1; }
# print_aviso_line — the R2 alarm's own printer: UNindented, line-anchored `AVISO `, stdout (it is not a
# failure). Separate from `say()`, which indents, so the alarm's own `^AVISO ` contract cannot drift.
print_aviso_line() { echo "$1"; }
# alarm_class <label> <ere> — one onde-dentro class: match the ERE against the acceptance cell
# (`$acc`), and on a match increment `avisos` and print one AVISO line via print_aviso_line. `acc`,
# `spec`, `id` and `avisos` are the caller's (check_change's) locals / the global counter — visible
# here via bash dynamic scoping, no need to pass them.
alarm_class() { # label ere
  local m
  m="$(printf '%s' "$acc" | grep -oE "$2" | head -1)"
  [ -n "$m" ] || return 0
  avisos=$((avisos + 1))
  print_aviso_line "AVISO $spec:$id [$1] ${m:0:100}"
}

# Lexical on purpose (the proposal rules follow where the folder was WRITTEN, not where it points): a link in
# proposed/ whose target is outside gets the proposal rules but not R2/R4 (those use the physical
# is_live_dir).
# is_proposed_dir <dir> -> true (0) when the path sits DIRECTLY under specs/proposed/: its PARENT
# directory is named "proposed" AND that directory's PARENT is named "specs". Lexical only (no disk
# access) — NOT "the path contains /proposed/ somewhere": an active/ folder nested under a tree whose
# grandparent happens to be named "proposed" (e.g. a clone checked out at .../proposed/repo/specs/
# active/<id>) must stay active/, never flip to proposed rules by a substring match higher up the path.
is_proposed_dir() {
  local d="${1%/}" parent gp
  parent="$(basename -- "$(dirname -- "$d")")"
  gp="$(basename -- "$(dirname -- "$(dirname -- "$d")")")"
  [ "$parent" = "proposed" ] && [ "$gp" = "specs" ]
}

# --- one change folder ----------------------------------------------------------------------------
# check_change <dir> — the form-neutral preamble and the DISPATCH (R2): it reads neither the spec.md
# table (read_spec_requirements) nor a plan of either form. It declares, at its top level and with an
# initializer, every folder variable and
# the whole plan interface below, so each folder starts from the same values; the units it calls read
# and write them by bash dynamic scoping and declare none of them (a `local` there would vanish on
# return). Order of the calls is contract: the form's precondition before the spec, the form's plan
# reader after it, then judge_plan.
check_change() {
  # ---- the folder ----
  local d="${1%/}" spec="${1%/}/spec.md" tasks="${1%/}/tasks.md" change="${1%/}/change.md"
  local name=""
  name="$(basename -- "$d")"
  local design="${1%/}/design.md" decomp=0 dbody="" is_prop=0
  # The plan's block count (R4): written by read_blocks, once, inside precheck_new_form — new form only.
  local blocks="" n_blocks=0
  # The spec's requirement ids and its `NO-TASK:` exemptions, written by read_spec_requirements.
  local ids="" exempt=""

  # ---- the PLAN INTERFACE: written by the form's reader, read by judge_plan ----
  # Whichever form is in force, its reader (read_plan_new_form + read_ledger_new_form, or
  # read_plan_old_form) fills these, and judge_plan never learns which one did — the table "A interface
  # do plano" of the design of 2026-10-check-tasks-por-dentro lists writer and reader of each:
  #   tref              requirement ids the plan cites                         (a)(b)
  #   impl              implementation task count                              (c)
  #   blk_visual        tasks whose BLOCK asserts `**Visual:** sim`            (e)
  #   led_visual        tasks the LEDGER marks VISUAL                          (e)
  #   closing_gate_row, closing_signoff_row, task_idx, refs_idx, closing_ready
  #                     the closing rows and the columns to read them by       (d)
  #   ledger_present    there is a ledger to compare against                   (e)
  #   justif_state      (c)'s sizing justification: ausente | vazia | presente (c)
  # `refs_idx` stays empty in the new form — there is no `Refs` column there, which is exactly why (d)'s
  # structural discriminator degrades to the two tokens, and why (g) exists so that nothing passes BY
  # OMISSION of `Refs`. `ledger_present` stays 1 in the old form (precheck_old_form fails a folder
  # without tasks.md before this point is reached); the new form sets it to 0 before the ledger is
  # generated, and (e) is then skipped, not failed. `justif_state` is written only by the new form, and
  # only above 16 blocks; the old form leaves it empty.
  local tref=""
  local impl=0
  local blk_visual=""
  local led_visual=""
  local closing_gate_row=""
  local closing_signoff_row=""
  local task_idx=""
  local refs_idx=""
  local closing_ready=0
  local ledger_present=1
  local justif_state=""
  # 1 when the folder sits physically under specs/proposed/ or specs/active/ (is_live_dir), asked once, at
  # the new form's dispatch; read by read_ledger_new_form and judge_sot_decl. The old form never reads it.
  local live=0

  # Via rápida: a `Mode: fast` change has no spec/tasks by design (spec-layout → "Via rápida").
  # SKIP WITH A STATED REASON — never silence, which is what makes a skip legible instead of benign.
  if [ -f "$change" ] && [ "$(mode_of "$change" 2>/dev/null)" = "fast" ]; then
    say "$name: SKIP — Mode: fast (via rápida não tem spec.md/tasks.md, por desenho)"
    return 0
  fi

  [ -f "$spec" ]  || { bad "$name: spec.md ausente — não há de onde tirar os requisitos."; return 0; }

  # ---- FORM DETECTION, and it reads nothing but the form ----
  # `decomp` = design.md exists AND its body — comment-stripped AND fence-blanked — has a line that IS
  # exactly `## Decomposição`. Exact line, never "contains": every other artifact in this repo that
  # MENTIONS the heading (templates, skills, this very change's spec) would otherwise flip the form. No
  # date, no SHA, no allowlist — the artifact's shape is the whole decision. Done here, before the
  # ledger guard, because in the new form a missing ledger is legitimate.
  # THROUGH THE SAME TWO FILTERS AS EVERY OTHER READING POINT (I3): a ``` fenced `## Decomposição` is a
  # QUOTE of the form (a design that documents the convention quotes it), not the section. Without the
  # fence filter an old-form change whose design quoted the heading became new-form with ZERO blocks —
  # every requirement uncovered and the ledger "orphaned": two bogus FAILs from a mention. Measured:
  # zero archived designs in either corpus carry the line at all, so this is verdict-neutral on the
  # corpus and the suite asserts that count.
  if [ -f "$design" ]; then
    dbody="$(strip_html_comments "$design")"
    has_decomp "$dbody" && decomp=1 # C-form
  fi

  # ---- PROPOSED-ONLY short-circuits (2026-09-change-parada-em-active, R3/R4;
  # 2026-10-hooks-defeitos-e-pin, R1) ----
  # A change still under discussion (specs/proposed/) need not have a design or a decomposition
  # yet: requiring tasks.md there would fail every spec-only proposal (measured in round 1 on a bko
  # Draft). A NAMED SKIP in both cases — never silence (N5). With `--transcricao` (the launcher
  # passes it right before transcribing the design) the second case FAILs: Gate 1.5 itself requires
  # the plan, while CI must not go red while the design is still being written.
  #
  # A THIRD case (R1) — the section EXISTS but carries ZERO `### Task N` blocks — reads the plan, so it
  # is the new form's precondition (precheck_new_form, below), at this same point: before the spec.md
  # table is ever read, so (same as the two SKIPs here) no `AVISO` line fires.
  is_proposed_dir "$d" && is_prop=1
  if [ "$is_prop" -eq 1 ]; then
    if [ ! -f "$design" ]; then
      say "$name: SKIP — proposta sem design — cobertura e report n.a."
      return 0
    fi
    if [ "$decomp" -eq 0 ]; then
      if [ "$transcricao_mode" -eq 1 ]; then
        bad "$name: design sem ## Decomposição — não se aprova o HOW sem o plano"
      else
        say "$name: SKIP — proposta com design sem decomposição — n.a."
      fi
      return 0
    fi
  fi

  # Each form's precondition, dispatched — here, before the spec is read, because the order is
  # contract. NEW FORM (precheck_new_form): the block count, and the named SKIP of a proposal whose
  # decomposition is empty; the ledger is derived state generated at implementation start, handled in
  # read_plan_new_form. OLD FORM (precheck_old_form): tasks.md IS the plan, so its absence is fatal.
  if [ "$decomp" -eq 1 ]; then
    precheck_new_form || return 0
  else
    precheck_old_form || return 0
  fi

  read_spec_requirements || return 0

  # ---- the plan: design.md § Decomposição (new form) OR tasks.md (old form), dispatched ------------
  # Each form's reader fills the plan interface declared at the top; judge_plan then judges it, blind
  # to the form that fed it.
  if [ "$decomp" -eq 1 ]; then
    # ================ NEW FORM: the plan is design.md § Decomposição — read_plan_new_form ===========
    # `live` once per folder (is_live_dir), for the two live-only rules: the repeated closing row
    # (read_ledger_new_form) and R4 (judge_sot_decl).
    is_live_dir "$d" && live=1
    read_plan_new_form
    # R4: the SoT declaration, only here — after every SKIP of today and only once the plan was read in the
    # new form (design.md → "Onde R4 roda no check"). The old form never reaches it.
    judge_sot_decl
  else
    # ================ OLD FORM: the plan is tasks.md — read_plan_old_form ===========================
    # It returns 1 after one of the five FAILs that end the check (no ledger header, zero or more than
    # one `Refs` cell, no `Task` cell, fewer than two rows): the folder is then left unjudged, as before.
    read_plan_old_form || return 0
  fi
  judge_plan
  return 0
}

# read_spec_requirements — no arguments; the spec.md requirements table, found BY NAME. READS `name`,
# `spec`. WRITES `ids` (the requirement ids, sorted and unique) and `exempt` (the `NO-TASK:` ones):
# check_change's locals, by bash dynamic scoping — only its own internals are `local`. Prints the
# onde-dentro alarm's AVISO lines (alarm_class). Its arity and empty-motive FAILs do not end the check;
# it returns 1 after one of the three FAILs that do (no header naming `Requirement`, no `Acceptance`
# cell, no R* at all), and check_change returns; 0 otherwise.
read_spec_requirements() {
  # ---- requirements table (spec.md), found BY NAME ----
  # Both the requirement table and the NFR table start with `| ID |`; the requirement one is the one
  # whose header names `Requirement`. Measured: exactly one such header in 43 of 43 specs.
  local shdr shdr_n=0 line n=0
  while IFS= read -r line; do
    n=$((n + 1))
    case "$line" in
      \|*ID*\|*) if grep -q 'Requirement' <<< "$(cells "$line")"; then shdr="$line"; shdr_n=$n; break; fi ;;
    esac
  done < "$spec"
  if [ "$shdr_n" -eq 0 ]; then
    bad "$name: spec.md sem tabela de requisitos (nenhum header com 'Requirement')."; return 1
  fi

  local acc_idx; acc_idx="$(idx_of "$shdr" 'Acceptance' | head -1)"
  if [ -z "$acc_idx" ]; then
    bad "$name: spec.md — header da tabela de requisitos sem célula 'Acceptance'; o token NO-TASK: seria ilegível."; return 1
  fi
  local shdr_cells; shdr_cells="$(ncells "$shdr")"

  # Requirement rows: collect ids, NO-TASK exemptions, and arity violations.
  local i=0
  while IFS= read -r line; do
    i=$((i + 1))
    [ "$i" -le "$shdr_n" ] && continue
    case "$line" in
      \|*R[0-9]*\|*) : ;;
      \|*) continue ;;
      *) continue ;;
    esac
    local id; id="$(cell_at "$line" 0)"
    case "$id" in R[0-9]*) : ;; *) continue ;; esac
    # ARITY, on the requirements table too — the side that reads NO-TASK: needs the same guard the
    # ledger side has for Refs. A row with a bare pipe splits differently and the acceptance cell would
    # be read truncated, which is the silent-misread path.
    if [ "$(ncells "$line")" -ne "$shdr_cells" ]; then
      bad "$name: spec.md linha $i — aridade divergente ($(ncells "$line") células contra $shdr_cells do header). Pipe nu numa célula? Escape com \\|."
      continue
    fi
    ids="$ids$id
"
    local acc; acc="$(cell_at "$line" "$acc_idx")"

    # --- onde-dentro alarm (R2): begin ---
    # "The spec says WHAT, not WHERE-inside" (design 2026-09-spec-so-what → "Fronteira"). Three classes,
    # each an ERE over the acceptance cell, checked in this fixed order. This is an ALARM, not a gate:
    # it prints to stdout (never stderr) and NEVER changes `fail` — the judgment of public-verification
    # vs. reaches-the-internal is the consistency-gate's 6b sub-check, not this mechanical pass. A cell
    # can match more than one class (measured: 65 marks in 55 cells across the kit's own archive), so
    # each class is tested independently and each match gets its own AVISO line and counts once.
    # arquivo:linha — no backtick requirement: naming the deliverable FILE is allowed (fronteira
    # decidida); the `:NNN` line pointer is what crosses into onde-dentro. The extension list is closed
    # and lives here, per the design table.
    alarm_class 'arquivo:linha' '[A-Za-z0-9_./-]+\.(sh|py|md|yml|yaml|json|ts|tsx|go|sql|toml|java|kt):[0-9]+'
    # símbolo — a bare `identifier()` or `${VAR}`/`$VAR`, between backticks (the corpus never names a
    # bare identifier as onde-dentro without the code-span marking it as code).
    alarm_class 'símbolo' '`[A-Za-z_][A-Za-z0-9_]*\(\)`|`\$\{?[A-Z_][A-Z0-9_]*\}?`'
    # comando — a CLOSED list of executables (design's contract; a new one enters by change), backtick
    # code-span so `[^\`]+` has a right edge. This list is for RECOGNITION; the public-vs-internal split
    # among what it recognizes is the gate's 6b, not this alarm's.
    alarm_class 'comando' '`(bash|sh|grep|rg|git|python3?|sed|awk|pnpm|npm|yarn|go|mvn|gradle|make|curl|docker|kubectl|helm|pytest|ruff|eslint|tsc|cargo) [^`]+`'
    # --- onde-dentro alarm (R2): end ---

    # NO-TASK: ANCHORED at the start of the cell, never "contains". Measured on this very change: R5's
    # acceptance cell contains the token at offset 391/725 as a MENTION (its subject is registering the
    # token), and a "contains" read would exempt it by a rule nobody invoked. Same discipline as the
    # kit's other machine-read tokens, anchored at line start (`^Status:`, `^Verdict:`).
    case "$acc" in
      NO-TASK:*)
        local motive; motive="$(printf '%s' "$acc" | sed 's/^NO-TASK:[[:space:]]*//')"
        if [ -z "$motive" ]; then
          bad "$name: spec.md $id — 'NO-TASK:' sem motivo. Nunca passar por omissão: declare por quê."
        else
          exempt="$exempt$id
"
        fi
        ;;
    esac
  done < "$spec"

  ids="$(printf '%s' "$ids" | grep -v '^$' | sort -u)"
  if [ -z "$ids" ]; then
    bad "$name: spec.md não declara nenhum requisito R* — a aferição de cobertura passaria vacuamente."; return 1
  fi
  exempt="$(printf '%s' "$exempt" | grep -v '^$' | sort -u)"
  return 0
}

# judge_sot_decl — no arguments; R4 of 2026-10-check-tasks-defeitos: the spec's "Seções do SoT afetadas"
# declaration, read by THE reader the archive gate uses (sot_decl_of, hooks-lib.sh), so that a declaration
# the gate would fail at archive time fails here, in specs/proposed/ or specs/active/ (is_live_dir: the
# physical parent and grandparent — an archived folder is never judged by it, nor one that merely sits
# deeper under specs/active/; check_change's `live`). READS `name`, `spec`, `live`. WRITES
# `fail`/`other_fail` (by `bad`), the global `avisos` and, once per run, `sot_head`/`sot_head_read`.
# Returns 0.
#   - MISSING (no filled row and no token) and EMPTY (token without a motive) FAIL, naming the folder;
#   - NODELTA passes; CONFLICT (table and token together) is not judged here — the archive gate fails it;
#   - each HEADING is looked up in `sot_sections HEAD` (the repository of the current directory, like the
#     gate) by the gate's own lookup, hk_sot_heading_lines (text equality): absent or repeated →
#     `AVISO <pasta> [sot] …`, counted in
#     `avisos`, never a FAIL (a new section only exists after the archive's rewrite, and the gate checks it
#     there). No SoT at HEAD (SOT-DELETED, or NOSECTIONS) → one AVISO saying existence was not checked (I3:
#     never silent). A heading declared twice in the same spec is looked up once (the gate dedupes too).
judge_sot_decl() {
  local out tag h seen="" lines
  [ "$live" -eq 1 ] || return 0
  out="$(sot_decl_of "$spec")"
  case "$out" in
    MISSING) bad "$name: declaração de seções do SoT ausente — a seção \"Seções do SoT afetadas\" não tem linha preenchida nem SOT-NO-DELTA: <motivo> (spec-layout, regra 5(b))"; return 0 ;;
    EMPTY)   bad "$name: SOT-NO-DELTA sem motivo — escreva o motivo depois do token, na mesma linha (spec-layout, regra 5(b))"; return 0 ;;
  esac
  while IFS=$'\t' read -r tag h; do
    [ "$tag" = HEADING ] && [ -n "$h" ] || continue
    case "
$seen" in *"
$h
"*) continue ;; esac
    seen="$seen$h
"
    if [ "$sot_head_read" -eq 0 ]; then sot_head="$(sot_sections HEAD)"; sot_head_read=1; fi
    case "$sot_head" in
      SOT-DELETED|NOSECTIONS)
        avisos=$((avisos + 1))
        print_aviso_line "AVISO $name [sot] SoT ausente no HEAD — a existência dos headings não foi aferida"
        return 0 ;;
    esac
    # The gate's lookup, shared (hk_sot_heading_lines, hooks-lib.sh): HK_SOT_COUNT 0 = absent, 2+ = repeated.
    hk_sot_heading_lines "$sot_head" "$h"; lines="$HK_SOT_LINES"
    if [ "$HK_SOT_COUNT" -eq 0 ]; then
      avisos=$((avisos + 1))
      print_aviso_line "AVISO $name [sot] heading que não existe no SoT atual: \"$h\" — uma seção nova só existe depois da reescrita do arquivamento; o gate de arquivamento a confere"
    else
      if [ "$HK_SOT_COUNT" -ge 2 ]; then
        avisos=$((avisos + 1))
        print_aviso_line "AVISO $name [sot] heading repetido no SoT atual: \"$h\" (linhas $lines)"
      fi
    fi
  done <<< "$out"
  return 0
}

# --- the NEW FORM's units (R2): the plan is design.md § Decomposição ------------------------------
# All three run inside check_change and read and write ITS locals by bash dynamic scoping (the idiom
# of alarm_class): none declares any of check_change's folder or interface variables — a `local` here
# would vanish on return and the judgment would read the initial value. Only their own internals are
# `local` — read_ledger_new_form's loop counters `i`/`line` included: they are its own locals, not
# check_change's. None reads the old form's plan (tasks.md as the plan, its numeric rows); check_change
# dispatches here only when `decomp` is 1.

# precheck_new_form — no arguments. READS `name`, `dbody`, `is_prop`, `transcricao_mode`. WRITES
# `blocks` and `n_blocks` (by read_blocks). A proposal outside `--transcricao` whose `## Decomposição`
# carries ZERO `### Task N` blocks — exactly the shape `specs/templates/design.md` has the moment it is
# copied into a new proposal (its only example block sits INSIDE the `<!-- ... -->` comment, so
# `blocks_of` reads none) — is a NAMED SKIP (2026-10-hooks-defeitos-e-pin, R1), here, before the
# spec.md table is ever read: no `AVISO` line fires, and a spec whose requirements are all `NO-TASK:`
# still SKIPs instead of being read as approved. Returns 1 after that SKIP, and check_change returns;
# 0 otherwise. With `--transcricao` the proposal falls through to the new-form reading, which FAILs an
# uncovered requirement and PASSes an all-`NO-TASK:` spec.
precheck_new_form() {
  read_blocks "$dbody"
  if [ "$is_prop" -eq 1 ] && [ "$transcricao_mode" -eq 0 ] && [ "$n_blocks" -eq 0 ]; then
    say "$name: SKIP — proposta com decomposição vazia — n.a."
    return 1
  fi
  return 0
}

# read_plan_new_form — no arguments; the plan in design.md § Decomposição. READS `name`, `tasks`,
# `dbody`, `blocks`, `n_blocks`. WRITES `impl` (= `n_blocks`), `tref`, `blk_visual`, `justif_state`,
# `ledger_present` and, by read_ledger_new_form, the rest of the plan interface. Returns 0.
read_plan_new_form() {
  local bnums
  impl="$n_blocks"
  bnums="$(printf '%s\n' "$blocks" | grep -v '^$' | cut -f1)"

  # Numbering is 1..k, ascending, no repeats and no holes — the LEDGER IS INDEXED BY N, so an
  # ambiguous or absent number makes (f) uncomputable. Fail loudly instead of comparing sets that
  # cannot be compared.
  if [ "$impl" -gt 0 ]; then
    local dup gap zero
    # N < 1 first: `### Task 0` is not a legal block number, and the hole detector below cannot see
    # it (a list starting at 0 has no hole before its own first element). Named, never silent.
    zero="$(printf '%s\n' "$bnums" | grep -v '^$' | awk '$1+0 < 1' | sort -n -u | tr '\n' ' ' | sed 's/ *$//')"
    [ -n "$zero" ] && bad "$name: design.md § Decomposição — bloco '### Task N' com N menor que 1: $zero. A numeração vai de 1 a k; não há task 0."
    dup="$(printf '%s\n' "$bnums" | sort -n | uniq -d | tr '\n' ' ' | sed 's/ *$//')"
    [ -n "$dup" ] && bad "$name: design.md § Decomposição — N repetido entre os blocos '### Task N': $dup. O ledger é indexado por N."
    gap="$(printf '%s\n' "$bnums" | grep -v '^$' | awk '$1+0 >= 1' | sort -n -u | awk '{while(++p<$1+0) print p}' | tr '\n' ' ' | sed 's/ *$//')"
    [ -n "$gap" ] && bad "$name: design.md § Decomposição — buraco(s) na numeração dos blocos: $gap. N vai de 1 a k, crescente, sem buracos."
  fi

  local bn bvis has_refs brefs bids noref="" badref=""
  while IFS="$(printf '\t')" read -r bn bvis has_refs brefs; do
    [ -n "$bn" ] || continue
    # Coverage is fed by the R* reader ONLY: a block that names just `N1` is legal and simply
    # contributes nothing to (a).
    bids="$(expand_ids "$brefs")"
    if [ -n "$bids" ]; then
      tref="$tref$bids
"
    fi
    if [ "$has_refs" != 1 ]; then
      noref="$noref'### Task $bn' "
    elif [ -z "$(expand_ids_any "$brefs")" ]; then
      badref="$badref'### Task $bn' "
    fi
    if [ "$bvis" = "VISUAL" ]; then
      blk_visual="$blk_visual$bn
"
    fi
  done <<EOF
$blocks
EOF

  # (h) a block that cites NO requirement. INDEPENDENT of (a) by design: coverage of the spec can be
  # complete and this block still be work nobody asked for (I1). TWO STATES, TWO MESSAGES, because
  # they are two different defects and the human fixes them differently: no `**Refs:**` line at all
  # vs. a line that names no id the kit knows (`R*` or `N*`). Nothing passes by omission of the
  # line, and nothing passes by omission of the value.
  if [ -n "$noref" ]; then                                                                 # C-norefs
    bad "$name: bloco(s) sem linha '**Refs:**': ${noref% }. Uma task sem requisito é trabalho que a spec não pediu."  # C-norefs
  fi                                                                                       # C-norefs
  if [ -n "$badref" ]; then                                                                # C-norefs
    bad "$name: bloco(s) com '**Refs:**' sem nenhum id R*/N*: ${badref% }. Uma task sem requisito é trabalho que a spec não pediu."  # C-norefs
  fi                                                                                       # C-norefs

  # (c)'s input, NEW FORM only (change 2026-09-teto-vira-justificativa): above 16 blocks the design's
  # `**Justificativa de dimensionamento:**` line is read (justif_of) into `justif_state`. The old form
  # never reads it, so there `justif_state` stays empty and (c) keeps its old message byte for byte
  # (R4). The `# D-justif` line is the discriminator, a line marker (no suite deletes it today): without
  # it `justif_state` stays empty and a justified 17-block design falls back to the old FAIL.
  [ "$n_blocks" -gt 16 ] && justif_state="$(justif_of "$dbody")"                           # D-justif

  # ---- the ledger (tasks.md), when it exists: DERIVED state, aferido CONTRA os blocos -------------
  if [ ! -f "$tasks" ]; then
    # NOT a failure, and not silence either (N5): before implementation starts the ledger legitimately
    # does not exist — (d)(e)(f)(g) simply have nothing to read, while (a)(b)(c)(h) still decide.
    ledger_present=0
    say "$name: ledger ausente — nasce no início da implementação (check-tasks.sh --ledger)"
  else
    read_ledger_new_form "$bnums"
  fi
  return 0
}

# read_ledger_new_form <bnums> — the derived ledger, aferido against the blocks (`<bnums>`: the block
# numbers, one per line). READS `name`, `tasks`, `live`. WRITES `led_visual`, `task_idx`, `closing_gate_row`,
# `closing_signoff_row`, `closing_ready`. Its FAILs do not end the check: the judgment still runs. The
# two header FAILs (no ledger table; no `#` or `Task` cell) end the ledger's reading there. Returns 0.
read_ledger_new_form() {
  local bnums="$1"
  local ledger_hdr_row ledger_hdr_line=0 ledger_hdr_cells=0
  find_ledger_header "$tasks"
  if [ "$ledger_hdr_line" -eq 0 ]; then
    bad "$name: tasks.md sem tabela de ledger (nenhum header '| # |')."
    return 0
  fi
  # (g) OBSOLETE COPY of the plan: next to a design that carries `## Decomposição`, a `Refs` cell
  # or a `### Task N` heading in tasks.md means the plan was duplicated and the two copies can
  # disagree. Names the FILE and the LINE (N5) — line numbers survive the comment strip.
  # BY ANCHORED PREFIX, neither "contains" nor "equals": the detector fires on the column's
  # PRESENCE, so a header cell that merely NAMES the word (`Notas (sem Refs — agora no design)`)
  # must not fire it — but the kit's own legacy spelling is `Refs (R*)`, and an equality read
  # would let exactly the copy this exists to catch through in silence. See idx_re and refs_col.
  local refs_hdr                                                                       # C-obsolete
  refs_hdr="$(refs_col "$ledger_hdr_row")"                                             # C-obsolete
  if [ -n "$refs_hdr" ]; then                                                          # C-obsolete
    bad "$name: tasks.md linha $ledger_hdr_line — header do ledger com célula 'Refs' ao lado de um design com '## Decomposição': cópia obsoleta do plano. Os requisitos vivem nos blocos '### Task N' do design."  # C-obsolete
  fi                                                                                   # C-obsolete
  local tblk_n                                                                         # C-obsolete
  # Fence-aware, same reader the design side uses: a ``` fenced `### Task 1` in the ledger is an
  # example of the form (the template quotes one), never a duplicated plan.
  tblk_n="$(blank_fences "$(strip_html_comments "$tasks")" | grep -n '^###[[:space:]]*Task' | head -1 | cut -d: -f1)"  # C-obsolete
  if [ -n "$tblk_n" ]; then                                                            # C-obsolete
    bad "$name: tasks.md linha $tblk_n — heading '### Task' no ledger ao lado de um design com '## Decomposição': cópia obsoleta do plano."  # C-obsolete
  fi                                                                                   # C-obsolete

  # Columns BY NAME — `#` included. The old form reads the number at index 0, a proxy that merely
  # happens to be right in 43 of 43 corpus ledgers; the header names the column, so name it.
  # ANCHORED, by ledger_col — the generator's grammar (R1): a cell that IS the name, so a header
  # cell that only contains it (`Nota sobre Task`, `Ref #`) is not read as the column, and a
  # qualified name (`Task (design)`) is not the column either — for the check as for the generator.
  local num_idx vis_idx
  num_idx="$(ledger_col "$ledger_hdr_row" '#')"
  task_idx="$(ledger_col "$ledger_hdr_row" 'Task')"
  vis_idx="$(ledger_col "$ledger_hdr_row" 'Visual')"
  if [ -z "$num_idx" ] || [ -z "$task_idx" ]; then
    bad "$name: tasks.md — header do ledger sem célula '#' ou 'Task'; as linhas seriam ilegíveis."
    return 0
  fi

  # The ledger table is the CONTIGUOUS run of `|` rows that follows its header: the closing rows
  # are the last two rows OF THAT TABLE, and in the new form their `#` cell is `—`, so the old
  # form's "last two numeric rows" read would not find them at all.
  local lrows="" started=0 i=0 line
  while IFS= read -r line; do
    i=$((i + 1))
    [ "$i" -le "$ledger_hdr_line" ] && continue
    ledger_line_kind "$line" "$started" check
    case "$LEDGER_KIND" in end) break ;; skip|sep) continue ;; esac
    started=1
    lrows="$lrows$i:$line
"
  done < "$tasks"

  local rec rno rline nlrows=0 lnums="" num tc gate_lns="" sign_lns=""
  while IFS= read -r rec; do
    [ -n "$rec" ] || continue
    rno="${rec%%:*}"; rline="${rec#*:}"
    nlrows=$((nlrows + 1))
    closing_gate_row="$closing_signoff_row"; closing_signoff_row="$rline"
    if [ "$(ncells "$rline")" -ne "$ledger_hdr_cells" ]; then
      bad "$name: tasks.md linha $rno — aridade divergente ($(ncells "$rline") células contra $ledger_hdr_cells do header). Pipe nu numa célula? Escape com \\|."
      continue
    fi
    num="$(cell_at "$rline" "$num_idx")"
    # A closing row carries `—` in `#`. The read is "NOT all digits" rather than "matches the
    # dash": `—` is multibyte and matching it would make the read locale-dependent. Only a
    # CLOSING row (token `validation-gate`/`sign-off` in its Task cell) may skip the set; any
    # other non-numeric `#` (e.g. `1a`) is a row the generator never emits — skipping it in
    # silence would let (f) pass on a set that never saw it, so it fails, naming the cell.
    case "$num" in
      ''|*[!0-9]*)
        tc="$(cell_at "$rline" "$task_idx")"
        has_closing_token "$tc" \
          || bad "$name: tasks.md linha $rno — célula '#' não numérica ('$num') numa linha que não é de fechamento (validation-gate/sign-off); o ledger é indexado por N."
        # The COUNT of closing rows, by closing_kind (one class); the repeated one is judged below.
        count_closing "$tc" "$rno"
        continue ;;
    esac
    # (f) duplicate `#`: the set comparison below uses `sort -u`, which would fuse two `| 1 |`
    # rows into {1} and match the blocks — so a repeat is caught HERE, naming the number.
    case "
$lnums" in
      *"
$num
"*) bad "$name: tasks.md linha $rno — task $num repetida no ledger ('#' duplicado; uma linha por bloco '### Task N')." ;;
    esac
    lnums="$lnums$num
"
    # VISUAL by CELL VALUE, never by scanning the row — same discipline as the old form.
    if [ -n "$vis_idx" ] && [ "$(cell_at "$rline" "$vis_idx")" = "VISUAL" ]; then
      led_visual="$led_visual$num
"
    fi
  done <<EOF
$lrows
EOF

  # (f) ledger ↔ decomposição: the set of numeric `#` cells must BE the set of block Ns.
  local lnums_s bnums_s extra falta
  lnums_s="$(printf '%s' "$lnums" | grep -v '^$' | sort -u || true)"
  bnums_s="$(printf '%s\n' "$bnums" | grep -v '^$' | sort -u || true)"
  extra="$(comm -23 <(printf '%s\n' "$lnums_s") <(printf '%s\n' "$bnums_s") | grep -v '^$' | sort -n | tr '\n' ' ' | sed 's/ *$//')"
  [ -n "$extra" ] && bad "$name: task $extra no ledger sem bloco '### Task N' no design (o gerador nunca apaga linha — o humano decide)."
  falta="$(comm -13 <(printf '%s\n' "$lnums_s") <(printf '%s\n' "$bnums_s") | grep -v '^$' | sort -n | tr '\n' ' ' | sed 's/ *$//')"
  [ -n "$falta" ] && bad "$name: task $falta do design sem linha no ledger — rode \`check-tasks.sh --ledger\`."

  # A REPEATED closing row (more than one gate, or more than one sign-off): the check judges the last
  # two rows and the generator took the first of each token, so the two read different ledgers.
  # Only in proposed/ and active/ — a rule that starts to fail does not apply to the archive. The
  # row numbers are the file's. Each call asks `repeated_closing` about one token and reports what
  # it recorded in REPEATED_CLOSING (empty = no repetition).
  if [ "$live" -eq 1 ]; then
    repeated_closings
    [ -z "$REP_GATE" ] || bad "$name: linha de fechamento repetida no ledger — $REP_GATE (uma de cada; o humano decide qual fica)."
    [ -z "$REP_SIGN" ] || bad "$name: linha de fechamento repetida no ledger — $REP_SIGN (uma de cada; o humano decide qual fica)."
  fi

  if [ "$nlrows" -lt 2 ]; then
    bad "$name: tasks.md tem $nlrows linha(s) no ledger; as duas de fechamento são obrigatórias."
  else
    closing_ready=1
  fi
  return 0
}

# --- the OLD FORM's units (R2): the plan is tasks.md ----------------------------------------------
# Both run inside check_change and read and write ITS locals by bash dynamic scoping (the idiom of
# alarm_class): neither declares any of check_change's folder or interface variables — a `local` here
# would vanish on return and the judgment would read the initial value. Only their own internals are
# `local`. Neither reads the new form's plan (design.md, its blocks); check_change dispatches here
# only when `decomp` is 0.

# precheck_old_form — no arguments. READS `name`, `tasks`. tasks.md IS the old form's plan, so its
# absence is fatal: today's FAIL (the sentence does not change; the launcher reads the run's exit 3
# instead of the text) and returns
# 1, and check_change returns before the spec is read. Returns 0 when tasks.md exists.
precheck_old_form() {
  if [ ! -f "$tasks" ]; then
    bad_no_ledger "$name: tasks.md ausente."; return 1
  fi
  return 0
}

# read_plan_old_form — no arguments; the plan in tasks.md. READS `name`, `tasks`. WRITES the plan
# interface: `tref`, `impl`, `led_visual`, `blk_visual`, `task_idx`, `refs_idx`, `closing_gate_row`,
# `closing_signoff_row`, `closing_ready`. Returns 1 after one of the five FAILs that end the check (no
# ledger header, zero or more than one `Refs` cell, no `Task` cell, fewer than two task rows) — the
# caller then leaves the folder unjudged; 0 otherwise. Column reads stay "contains" (idx_of) for
# `Refs`, `Task` and `Visual`, and the task number is the first cell (Decisions log).
read_plan_old_form() {
  # ---- ledger (tasks.md): the FIRST `|#|` table ----
  # Measured: 4 archived tasks.md carry a SECOND such table (the L0 capture). Reading the first is the
  # contract; if a future file inverted the order the check would fail loudly, not silently.
  local ledger_hdr_row ledger_hdr_line=0 ledger_hdr_cells=0
  find_ledger_header "$tasks"
  [ "$ledger_hdr_line" -eq 0 ] && { bad "$name: tasks.md sem tabela de ledger (nenhum header '| # |')."; return 1; }

  local refs_idx_all refs_n
  refs_idx_all="$(idx_of "$ledger_hdr_row" 'Refs')"
  refs_n="$(printf '%s' "$refs_idx_all" | grep -c . || true)"
  if [ "$refs_n" -eq 0 ]; then
    bad "$name: tasks.md — header sem célula 'Refs'. Sem ela a cobertura é INCOMPUTÁVEL, e o check não passa por não saber onde olhar."; return 1
  fi
  if [ "$refs_n" -gt 1 ]; then
    bad "$name: tasks.md — $refs_n células 'Refs' no header. O check falha em vez de escolher."; return 1
  fi
  refs_idx="$(printf '%s' "$refs_idx_all" | head -1)"

  # `Visual` column is OPTIONAL, and the asymmetry with `Refs` is deliberate: measured, 22 of 42
  # archived ledgers have no such column (it was born with 2026-07-06-2026-07-upgrade-preserva-tier3).
  # Without `Refs` coverage cannot be computed → failing high is the only honest exit. Without `Visual`
  # the answer is DETERMINATE: marking is opt-in and the template writes `—`, so no column means
  # nothing marked. (e) does not go vacuous: a `**Visual:** sim` block here is still a divergence.
  local vis_idx; vis_idx="$(idx_of "$ledger_hdr_row" 'Visual' | head -1)"
  # The `Task` column is found BY NAME too. Measured: it sits at index 1 in all 43 corpus ledgers, so a
  # fixed index would work TODAY — and that is exactly why it was wrong: the check's own header promises
  # every read is by name or by value, and an index that happens to be right is still a proxy.
  task_idx="$(idx_of "$ledger_hdr_row" 'Task' | head -1)"
  if [ -z "$task_idx" ]; then
    bad "$name: tasks.md — header sem célula 'Task'; as linhas de fechamento seriam ilegíveis."; return 1
  fi

  local rows="" i=0 line
  while IFS= read -r line; do
    i=$((i + 1))
    [ "$i" -le "$ledger_hdr_line" ] && continue
    case "$line" in \|*[0-9]*\|*) : ;; *) continue ;; esac
    local num; num="$(cell_at "$line" 0)"
    case "$num" in ''|*[!0-9]*) continue ;; esac
    if [ "$(ncells "$line")" -ne "$ledger_hdr_cells" ]; then
      bad "$name: tasks.md linha $i (task $num) — aridade divergente ($(ncells "$line") células contra $ledger_hdr_cells do header). Pipe nu numa célula? Escape com \\|."
      continue
    fi
    rows="$rows$line
"
    tref="$tref$(expand_ids "$(cell_at "$line" "$refs_idx")")
"
    # VISUAL read BY CELL VALUE, never by scanning the row: a task whose text merely MENTIONS the word
    # (e.g. one describing this very aferição) is not marked. This is how the dogfood of this change
    # caught the original defect.
    if [ -n "$vis_idx" ] && [ "$(cell_at "$line" "$vis_idx")" = "VISUAL" ]; then
      led_visual="$led_visual$num
"
    fi
  done < "$tasks"

  rows="$(printf '%s' "$rows" | grep -v '^$' || true)"
  local nrows; nrows="$(printf '%s' "$rows" | grep -c . || true)"
  [ "$nrows" -lt 2 ] && { bad "$name: tasks.md tem $nrows linha(s) de task; as duas de fechamento são obrigatórias."; return 1; }
  closing_gate_row="$(printf '%s' "$rows" | tail -2 | head -1)"
  closing_signoff_row="$(printf '%s' "$rows" | tail -1)"
  closing_ready=1
  impl=$(( nrows - 2 ))

  # (e)'s block side, OLD FORM: the `### Task N` blocks live in tasks.md itself. Blocks inside
  # `<!-- ... -->` do not count: a comment that MENTIONS the marker (the `Rules:` block does) is not a
  # marking. TWO discriminators here, and the corpus proved both necessary:
  #   1. BLOCK MEMBERSHIP — the marker must sit between its own `### Task N` heading and the NEXT `###`.
  #      Without the bound, "appears after heading N" was taken for "belongs to block N": measured, the
  #      archived `2026-07-05-2026-07-visual-checkpoint` was failed by this check because line 102 QUOTES
  #      the template text it was writing, 18 lines below `### Task 2`. Proximity is not membership.
  #   2. FIELD LINE, not citation — the line must START with `**` (the template writes
  #      `**Refs:** … · **Visual:** …`). Measured: 23 field lines in the corpus all start with `**`; the
  #      2 citations do not. Same discipline as the kit's line-anchored tokens.
  local body
  body="$(strip_html_comments "$tasks")"
  blk_visual="$(printf '%s' "$body" | awk "$BLOCK_AWK"'
      /^###/ { t="" }
      is_task_open($0) { t=task_num($0) }
      is_visual_mark($0) { if (t != "") print t }')"
  return 0
}

# --- the JUDGMENT (R2): blind to the form ---------------------------------------------------------
# judge_plan — no arguments. (a), the named grandfathering list, (b), (c), (d) and (e), in this order
# and with these messages. READS the plan interface (check_change's, filled by the form's reader) plus
# `name`, `ids`, `exempt` — and nothing that tells the form: not the design, not the ledger, not
# `decomp`. WRITES the global `avisos` and, by `bad`, `fail`; normalises `tref`, `led_visual` and
# `blk_visual` (the `sort -u`) in check_change's variables. Declares only its own internals. Returns 0.
judge_plan() {
  # (a) spec -> tasks, minus the NO-TASK: exemptions
  tref="$(printf '%s' "$tref" | grep -v '^$' | sort -u || true)"
  local missing
  missing="$(comm -23 <(printf '%s\n' "$ids") <(printf '%s\n' "$tref") | comm -23 - <(printf '%s\n' "$exempt") | tr '\n' ' ' | sed 's/ *$//')"
  # NAMED GRANDFATHERING (D3). These four archived changes predate this check and their gap is the very
  # class `NO-TASK:` covers going forward: three NEGATIVE requirements ("zero mudança de comportamento",
  # "registro histórico não é reescrito") and one EMPIRICAL-HUMAN verification. Retrofit was refused on
  # principle — an archived artifact is a record, and adding a `Refs` would change what the change
  # declared it had covered. So the allowlist covers the past and the token covers the future.
  # It is NOMINAL by design: it names the folder AND the requirement, so it can never silently absolve a
  # different gap in the same folder, nor the same gap in another folder. All four are OLD FORM; the
  # list is shared with the new form only because a nominal list can do no harm where no name matches.
  case "$name:$missing" in
    "2026-07-01-adopt-approve-command:R3"|\
    "2026-07-28-2026-07-vocabulario-encaixe-seam:R4"|\
    "2026-07-29-2026-07-disciplina-de-skill:R6"|\
    "2026-07-29-2026-07-seams-sob-teste:R6")
      say "$name: $missing dispensado pela allowlist nomeada (grandfathering D3 — requisito negativo ou de verificação humana, anterior ao check)"
      missing=""
      ;;
  esac

  [ -n "$missing" ] && bad "$name: requisito(s) sem task: $missing. Cada R* precisa de task, ou de 'NO-TASK: <motivo>' no critério de aceite."

  # (b) tasks -> spec
  local phantom
  phantom="$(comm -13 <(printf '%s\n' "$ids") <(printf '%s\n' "$tref") | tr '\n' ' ' | sed 's/ *$//')"
  [ -n "$phantom" ] && bad "$name: Refs cita requisito inexistente na spec: $phantom."

  # (c) 16 implementation tasks — the two closing rows never count (spec-layout rule 2). Old form
  # counts ledger rows minus two; new form counts `### Task N` blocks, where the closing rows are not
  # blocks at all. BY FORM (change 2026-09-teto-vira-justificativa), and blind to it here: in the NEW
  # form 16 is an ALARM — above it read_plan_new_form read the design's
  # `**Justificativa de dimensionamento:**` line into `justif_state`: absent or empty FAILs, with text
  # passes with one `AVISO <change> [dimensionamento]` counted in the global `avisos`. The OLD form never
  # reads it (`justif_state` stays empty) and keeps its message byte for byte (R4). The `# D-justif` line
  # (in read_plan_new_form) is the discriminator, a line marker (no suite deletes it today): without it
  # `justif_state` stays empty in both forms and a justified 17-block design falls back to the old FAIL.
  if [ "$impl" -gt 16 ]; then
    case "$justif_state" in
      presente)
        avisos=$((avisos + 1))
        print_aviso_line "AVISO $name [dimensionamento] $impl tasks — justificado"
        ;;
      ausente|vazia)
        local justif_detail=""
        [ "$justif_state" = vazia ] && justif_detail=" (placeholder ou sem texto)"
        bad "$name: $impl tasks na decomposição (alarme acima de 16) sem justificativa de dimensionamento — $justif_state$justif_detail; escreva '$JUSTIF_LABEL <motivo>' logo abaixo de '## Decomposição' (spec-layout regra 2)"
        ;;
      *)
        bad "$name: $impl linhas de implementação (teto 16, as duas de fechamento não contam). Divida a change."
        ;;
    esac
  fi

  # (d) closing rows: by TOKEN, not by wording. Measured: the template's exact wording matches 10 of 43
  # ledgers, the token pair matches 43 of 43 — the 33 deviations are legitimate authorial variation
  # (markup, language, added specificity). The template is the source of WHICH TOKENS are required, and
  # that is why they are identifiers the kit does not translate: translating them breaks this aferição.
  # THE BYPASS THIS GUARD EXISTS TO CLOSE (validation-gate, 2026-09-10): matching the token alone let a
  # folder with NO closing rows pass, as long as two implementation rows merely MENTIONED the tokens —
  # and the tasks.md of the change that wrote this check does mention them. Token presence is necessary
  # and NOT sufficient; the structural discriminator is the penultimate row's `Refs` cell, measured `all`
  # in 43 of 43 corpus ledgers (one reads `all, R8`), while an implementation row carries real IDs.
  # NEW FORM: there is no `Refs` column, so that discriminator does not exist and is not faked — what
  # replaces it is (g), which fails a ledger that still carries `Refs`, plus (f), which pins every
  # implementation row to a block. Nothing passes by omission.
  if [ "$closing_ready" -eq 1 ]; then
    if [ -n "$refs_idx" ]; then
      grep -qiw 'all' <<< "$(cell_at "$closing_gate_row" "$refs_idx")" \
        || bad "$name: penúltima linha de task não é a de fechamento — o \`Refs\` dela deveria ser \`all\` (é o que 43/43 do corpus fazem), e menção ao token numa linha de implementação não basta."
    fi
    names_validation_gate "$(cell_at "$closing_gate_row" "$task_idx")" \
      || bad "$name: penúltima linha de task não casa o token 'validation-gate' (casamento por TOKEN, não por redação)."
    # The LAST row needs its own discriminator, and the penultimate's does not transfer: `Refs` there is
    # `—` in only 40 of 43 — three legitimate sign-offs carry real `R*`. What IS universal, measured 43/43:
    # the `Task` cell STARTS with the token. So the rule is ANCHORED, not "contains" — the same discipline
    # as `NO-TASK:`, one level down. Without it, a legitimate penultimate plus an implementation row merely
    # MENTIONING `sign-off` passed, and the attack line the gate used is near-verbatim from task 10 of the
    # very tasks.md that ships this check.
    starts_with_signoff "$(cell_at "$closing_signoff_row" "$task_idx")" \
      || bad "$name: última linha de task não COMEÇA com o token 'sign-off' (ancorado, não \"contém\" — menção no meio de uma linha de implementação não é fechamento)."
  fi

  # (e) VISUAL consistency, both directions: the LEDGER's `Visual` column against the BLOCK's
  # `**Visual:** sim`. In the old form the block is in tasks.md; in the new form it is the design's
  # `### Task N`. The ledger column is a mechanical copy — the block is the assertion. SKIPPED when
  # there is no ledger to read (new form, pre-implementation): `led_visual` has nothing to compare against
  # and a design-only `**Visual:** sim` is not yet a divergence, just a plan that has not been turned
  # into a ledger row yet (N5, R4).
  if [ "$ledger_present" -eq 1 ]; then
    led_visual="$(printf '%s' "$led_visual" | grep -v '^$' | sort -u || true)"
    blk_visual="$(printf '%s' "$blk_visual" | grep -v '^$' | sort -u || true)"

    local in_ledger_only in_block_only
    in_ledger_only="$(comm -23 <(printf '%s\n' "$led_visual") <(printf '%s\n' "$blk_visual") | grep -v '^$' | tr '\n' ' ' | sed 's/ *$//')"
    in_block_only="$(comm -13 <(printf '%s\n' "$led_visual") <(printf '%s\n' "$blk_visual") | grep -v '^$' | tr '\n' ' ' | sed 's/ *$//')"
    [ -n "$in_ledger_only" ] && bad "$name: task(s) $in_ledger_only marcada(s) VISUAL no ledger sem '**Visual:** sim' no bloco '### Task N'."
    [ -n "$in_block_only" ] && bad "$name: task(s) $in_block_only com '**Visual:** sim' no bloco sem a marcação VISUAL no ledger."
  fi

  return 0
}

# --- the ledger generator (`--ledger <dir>`) ------------------------------------------------------
# THE GENERATOR OWNS THE HEADER. `specs/templates/tasks.md` carries the same two lines and a test
# asserts they are byte-identical — synchrony as an ACCEPTANCE CRITERION, not as a consequence. The
# alternative (the hook reading the template at runtime) was rejected in the design: the template is
# `portable`, an adopter with `upgrade: preserve` could diverge, and the generator would then emit
# ledgers this very check cannot read.
LEDGER_HDR='| # | Task | Visual | Status | Commit | Notas |'
LEDGER_SEP='|---|------|--------|--------|--------|-------|'

# ledger_row <cell>... -> one markdown row. An EMPTY cell renders as `| |` (one space), which is what
# the template's own example rows carry — the generated file has to be byte-identical to a ledger a
# human wrote from the template, or the idempotence claim is a claim about formatting, not about state.
ledger_row() {
  local out="|" c
  for c in "$@"; do
    if [ -z "$c" ]; then out="$out |"; else out="$out $c |"; fi
  done
  printf '%s\n' "$out"
}

gerr() { echo "ERRO - $1" >&2; }

# gen_ledger <dir> -> 0 on success (tasks.md written), 2 on a NAMED refusal. Writes NOTHING but
# tasks.md (N4) and never removes a row (a task deleted from the design stays in the ledger and the
# check's (f) names it — the human decides).
gen_ledger() {
  local d="${1%/}" name
  [ -d "$d" ] || { gerr "pasta '$1' não existe — o gerador não cria a mudança."; return 2; }
  name="$(basename -- "$d")"
  local design="$d/design.md" tasks="$d/tasks.md"

  # ---- precondition: the NEW FORM, with at least one block. Read by the SAME readers the check uses
  # (comment-stripped, fence-blanked, exact line), so the generator can never emit a ledger for a form
  # the check would judge by the other path.
  [ -f "$design" ] || { gerr "$name: design.md ausente — o ledger deriva da seção '## Decomposição' do design."; return 2; }
  local dbody; dbody="$(strip_html_comments "$design")"
  has_decomp "$dbody" || {
    gerr "$name: design.md sem '## Decomposição' — o gerador só existe para a forma nova (o plano vive no design)."; return 2; }
  # The generator's own `blocks`/`n_blocks`, filled by read_blocks — the check's block count, not a copy.
  local blocks="" n_blocks=0
  read_blocks "$dbody"
  [ "$n_blocks" -gt 0 ] || {
    gerr "$name: design.md § Decomposição com 0 blocos '### Task N' — não há o que gerar."; return 2; }

  # ---- precondition: the LEDGER FILE ITSELF must already exist. The generator fills a TABLE; it does
  # not author the file. `specs/templates/tasks.md` carries doctrine no generator can re-derive (the
  # `Status:`-line contract, the visual review rules, the closing rows' TOKEN convention, the
  # "this table is generated" note), so a from-scratch write would emit a ledger whose preamble is
  # silently MISSING — the tool inventing an artifact instead of filling one. Named refusal with the
  # copy instruction, per the human's standing posture: refuse rather than invent.
  [ -f "$tasks" ] || {
    gerr "$name: tasks.md ausente — copie specs/templates/tasks.md para $d/tasks.md e rode de novo (o gerador preenche a tabela; o preâmbulo do template é doutrina e não é inventado)"
    return 2; }

  # ---- read what already exists ----
  local prefix="" suffix="" extra_rows="" closing_gate_row="" closing_signoff_row="" gtmp=""
  local ledger_hdr_row="" ledger_hdr_line=0 ledger_hdr_cells=0 line
  find_ledger_header "$tasks"
  [ "$ledger_hdr_line" -gt 0 ] || { gerr "$name: tasks.md existe mas não tem tabela de ledger (nenhum header '| # |') — o gerador não sabe o que preservar."; return 2; }

  # A `Refs` cell next to a design that carries the section is the OLD FORM: an obsolete copy of the
  # plan. The generator REFUSES instead of converting it — a silent conversion would throw away the
  # `Refs` column (the only place the old plan's requirements lived) with nobody looking.
  if [ -n "$(refs_col "$ledger_hdr_row")" ]; then
    gerr "$name: tasks.md linha $ledger_hdr_line — header com célula 'Refs': cópia obsoleta do plano (forma antiga). Os requisitos vivem nos blocos '### Task N' do design; o gerador não converte em silêncio."
    return 2
  fi

  # Columns BY NAME, all six, anchored-exact (ledger_col, the check's grammar too) — the generator
  # owns the header, so a ledger whose header does not carry it is not a ledger this generator can
  # refresh. Named refusal, never a silent write that drops a column.
  local num_idx task_idx vis_idx sta_idx com_idx not_idx missing_col=""
  num_idx="$(ledger_col "$ledger_hdr_row" '#')";      [ -n "$num_idx" ]  || missing_col="$missing_col '#'"
  task_idx="$(ledger_col "$ledger_hdr_row" 'Task')";  [ -n "$task_idx" ] || missing_col="$missing_col 'Task'"
  vis_idx="$(ledger_col "$ledger_hdr_row" 'Visual')"; [ -n "$vis_idx" ]  || missing_col="$missing_col 'Visual'"
  sta_idx="$(ledger_col "$ledger_hdr_row" 'Status')"; [ -n "$sta_idx" ]  || missing_col="$missing_col 'Status'"
  com_idx="$(ledger_col "$ledger_hdr_row" 'Commit')"; [ -n "$com_idx" ]  || missing_col="$missing_col 'Commit'"
  not_idx="$(ledger_col "$ledger_hdr_row" 'Notas')";  [ -n "$not_idx" ]  || missing_col="$missing_col 'Notas'"
  if [ -n "$missing_col" ]; then
    gerr "$name: tasks.md linha $ledger_hdr_line — header do ledger sem a(s) célula(s)${missing_col}. O header do gerador é: $LEDGER_HDR"
    return 2
  fi

  # ...AND IT MUST BE THE GENERATOR'S HEADER, BYTE FOR BYTE (after trimming the line's own margins).
  # The by-name reads above are right for the rows the generator REWRITES, but every row it PRESERVES
  # verbatim (closing rows, orphans, anything else the human put in the table) is copied cell-for-cell
  # into a table whose header is then regenerated CANONICAL — so a ledger whose columns are merely
  # present in a DIFFERENT ORDER came out with its preserved rows silently misaligned against the new
  # header, and the check passed on the wreck. Remapping every preserved row would be the other fix;
  # this one is smaller and it cannot be wrong.
  local ledger_hdr_trim
  ledger_hdr_trim="$(printf '%s' "$ledger_hdr_row" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  if [ "$ledger_hdr_trim" != "$LEDGER_HDR" ]; then
    gerr "$name: header do ledger difere do header do gerador (linha $ledger_hdr_line): esperado '$LEDGER_HDR' — o gerador não reordena colunas; corrija à mão"
    return 2
  fi

  gtmp="$(mktemp -d)" || { gerr "$name: mktemp -d falhou."; return 2; }
  local i=0 ended=0 num tcell dup_first gate_lns="" sign_lns=""
  # TABELA PARTIDA — ANY non-pipe line inside the table (a blank line, a line of prose, an HTML
  # comment, a `- item`) used to END the scan: every row below it was read as `suffix`, so the
  # generator regenerated those tasks as PENDING *and* appended a second pair of closing rows below the
  # ones it had just copied into the suffix. `break_n` remembers the line that ended the table (any
  # interrupter, and `break_kind` names it: blank or not) and `resume_n` the first line below it that is
  # unmistakably a table row again — a numbered row, or a pipe row carrying a closing token. The scan
  # stops at the first markdown heading (the interrupter itself included): past a heading we are in
  # another section, and an L0-capture table there is a different table, not this one resumed
  # (4 archived ledgers carry exactly that).
  local break_n=0 break_kind='' resume_n=0 scan_done=0
  # A header with no rows yet is legitimate (the template ships one): the loop may read none.
  while IFS= read -r line; do
    i=$((i + 1))
    if [ "$i" -lt "$ledger_hdr_line" ]; then prefix="$prefix$line
"; continue; fi
    [ "$i" -eq "$ledger_hdr_line" ] && continue
    if [ "$ended" -eq 1 ]; then
      suffix="$suffix$line
"
      if [ "$break_n" -gt 0 ] && [ "$scan_done" -eq 0 ]; then
        case "$line" in
          \#*) scan_done=1 ;;
          *)
            if grep -qE '^\|[[:space:]]*[0-9]' <<< "$line"; then
              resume_n=$i; scan_done=1
            elif grep -qE '^\|' <<< "$line" && has_closing_token "$line"; then
              resume_n=$i; scan_done=1
            fi
            ;;
        esac
      fi
      continue
    fi
    # mode `gen`: any non-table line ends the table, before the first data row too. <started> is the
    # check's and a `gen` reading does not read it; 0 is passed so that the MODE alone makes the
    # difference — a ledger_line_kind that ignored it would read this table as the check does.
    ledger_line_kind "$line" 0 gen
    case "$LEDGER_KIND" in
      end)
        ended=1
        break_n=$i
        case "$line" in
          \#*) scan_done=1 ;;
          *[![:space:]]*) break_kind='linha fora da tabela' ;;
          *) break_kind='linha em branco' ;;
        esac
        suffix="$suffix$line
"
        continue ;;
      sep) continue ;;
    esac
    if [ "$(ncells "$line")" -ne "$ledger_hdr_cells" ]; then
      rm -rf "$gtmp"
      gerr "$name: tasks.md linha $i — aridade divergente ($(ncells "$line") células contra $ledger_hdr_cells do header). O gerador recusa em vez de reescrever a linha errada. Pipe nu numa célula? Escape com \\|."
      return 2
    fi
    num="$(cell_raw "$line" "$num_idx")"
    case "$num" in
      ''|*[!0-9]*)
        # Not a task row: a closing row (matched by TOKEN in the `Task` cell — names_validation_gate and
        # starts_with_signoff, the very tests (d) calls) or something else the human put there. Either way it
        # is PRESERVED VERBATIM. The SELECTION is the generator's own (Ricardo, 2026-10-08): the first
        # such row that passes each test, anywhere in the table.
        # The class is `closing_kind`'s (sign-off tested first) and the rows are COUNTED: a second row of
        # the same kind is refused below, before anything is written, so "the first one" is the only one.
        tcell="$(cell_at "$line" "$task_idx")"
        count_closing "$tcell" "$i"
        case "$CLOSING_KIND" in
          gate)
            [ -n "$closing_gate_row" ] || closing_gate_row="$line" ;;
          signoff)
            [ -n "$closing_signoff_row" ] || closing_signoff_row="$line" ;;
          *)
            extra_rows="$extra_rows$line
" ;;
        esac
        ;;
      *)
        # `#` REPEATED — the per-`#` record `t-N` is keyed by the number, so the second row simply
        # OVERWROTE the first and one line of execution state vanished with nobody looking. The
        # generator never removes a line: it refuses and names both.
        # ONE record per task, `t-N`: the line number, then the raw row. Every read of it is
        # `IFS= read -r` — the default IFS would trim the row's edges, and an orphan is copied byte for byte.
        if [ -f "$gtmp/t-$num" ]; then
          IFS= read -r dup_first < "$gtmp/t-$num"
          rm -rf "$gtmp"
          gerr "$name: ledger com '#' repetido: $num (linhas $dup_first, $i) — o gerador nunca remove linha; corrija à mão"
          return 2
        fi
        printf '%s\n%s\n' "$i" "$line" > "$gtmp/t-$num"
        ;;
    esac
  done < "$tasks"

  if [ "$resume_n" -gt 0 ]; then
    rm -rf "$gtmp"
    gerr "$name: tabela do ledger interrompida na linha $break_n ($break_kind) e retomada na linha $resume_n — junte a tabela à mão"
    return 2
  fi

  # A REPEATED closing row (R2): refused, naming the token and the lines, before the first write — the
  # file stays byte for byte. The generator never removes a line, so the human decides which one stays.
  repeated_closings
  if [ -n "$REP_GATE$REP_SIGN" ]; then
    rm -rf "$gtmp"
    gerr "$name: linha de fechamento repetida no ledger — ${REP_GATE}${REP_GATE:+${REP_SIGN:+; }}${REP_SIGN} — o gerador nunca remove linha; corrija à mão"
    return 2
  fi

  # ---- build the table ----
  # The loop DELETES NO RECORD: a `N` repeated in the design reads the same `t-N` twice (both rows
  # preserved, as before). The records it used go AFTER it; the ones left are the orphans.
  local body="" bn bvis gen=0 pres=0 st cm nt vis raw pres_ns=""
  while IFS="$(printf '\t')" read -r bn bvis _ _; do
    [ -n "$bn" ] || continue
    vis='—'; [ "$bvis" = "VISUAL" ] && vis='VISUAL'
    st="PENDING"; cm=""; nt=""
    if [ -f "$gtmp/t-$bn" ]; then
      { IFS= read -r _; IFS= read -r raw; } < "$gtmp/t-$bn"
      st="$(cell_raw "$raw" "$sta_idx")"; cm="$(cell_raw "$raw" "$com_idx")"; nt="$(cell_raw "$raw" "$not_idx")"
      pres_ns="$pres_ns $bn"
      pres=$((pres + 1))
    else
      gen=$((gen + 1))
    fi
    body="$body$(ledger_row "$bn" "design.md § Task $bn" "$vis" "$st" "$cm" "$nt")
"
  done <<EOF
$(printf '%s\n' "$blocks" | grep -v '^$' | sort -t"$(printf '\t')" -k1,1n)
EOF
  for bn in $pres_ns; do rm -f "$gtmp/t-$bn"; done

  # Rows whose `#` is numeric but has NO block are KEPT AS-IS, after the generated ones. The generator
  # never removes a row: a task deleted from the design is a decision, and the check's (f) puts it in
  # front of the human instead of the tool erasing the execution state silently.
  local orphan=0 orphan_ids="" f
  for f in "$gtmp"/t-*; do
    [ -e "$f" ] || continue
    { IFS= read -r _; IFS= read -r raw; } < "$f"
    body="$body$raw
"
    orphan=$((orphan + 1))
    orphan_ids="$orphan_ids${f##*/t-}
"
  done
  body="$body$extra_rows"

  # FECHAMENTO — three states, not two: `preservado` (both rows were there), `completado` (exactly one
  # was, so the generator added the OTHER) and `gerado` (neither). Folding the middle case into
  # "gerado" told the human the generator had authored both closing rows when it had in fact left one
  # of theirs in place — the opposite of what the word promises.
  local missing_fecho=0
  [ -n "$closing_gate_row" ] || { closing_gate_row="$(ledger_row '—' 'validation-gate' '—' 'PENDING' '' '')"; missing_fecho=$((missing_fecho + 1)); }
  [ -n "$closing_signoff_row" ] || { closing_signoff_row="$(ledger_row '—' 'sign-off → archive' '—' 'PENDING' '' '')"; missing_fecho=$((missing_fecho + 1)); }
  local fecho="preservado"
  [ "$missing_fecho" -eq 1 ] && fecho="completado"
  [ "$missing_fecho" -eq 2 ] && fecho="gerado"

  [ -n "$gtmp" ] && rm -rf "$gtmp"

  # ---- write: ONE temp file, ONE mv. Nothing else in the tree is touched (N4).
  # The MODE travels with the content: `mktemp` creates at 0600, so a plain mv turned every rewritten
  # ledger private to its author. `stat -c` is GNU and `stat -f` is BSD — try both, and 644 (an
  # explicit chmod, NOT the umask) when neither answers.
  local perms
  perms="$(stat -c '%a' "$tasks" 2>/dev/null || stat -f '%Lp' "$tasks" 2>/dev/null || true)"
  case "$perms" in ''|*[!0-7]*) perms=644 ;; esac
  local tmpf
  tmpf="$(mktemp "$tasks.XXXXXX")" || { gerr "$name: não consegui criar arquivo temporário ao lado de tasks.md."; return 2; }
  chmod "$perms" "$tmpf" 2>/dev/null || chmod 644 "$tmpf" 2>/dev/null || true
  printf '%s%s\n%s\n%s%s\n%s\n%s' \
    "$prefix" "$LEDGER_HDR" "$LEDGER_SEP" "$body" "$closing_gate_row" "$closing_signoff_row" "$suffix" > "$tmpf" || {
      rm -f "$tmpf"; gerr "$name: falha ao escrever $tasks."; return 2; }
  mv "$tmpf" "$tasks" || { rm -f "$tmpf"; gerr "$name: falha ao mover o temporário sobre $tasks."; return 2; }

  # ÓRFÃS SAEM SEPARADAS: folded into "preservada(s)" they were invisible — an orphan is a row whose
  # block VANISHED from the design, the one line in the ledger that needs a human decision, and the
  # summary was the only place it could have been named before (f) reproves the folder.
  local orphan_clause="" orphan_list
  if [ "$orphan" -gt 0 ]; then
    orphan_list="$(printf '%s' "$orphan_ids" | sort -n | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
    orphan_clause=", $orphan órfã(s) sem bloco: $orphan_list"
  fi
  echo "PASS - ledger: $((gen + pres + orphan)) linha(s) de task ($gen gerada(s), $pres preservada(s)$orphan_clause); fechamento $fecho"
  return 0
}

# --- the ledger's state (`--estado <dir>`; 2026-10-revisao-visual-unica, R3) -------------------------
# ledger_state <dir> -> 0, printing on stdout one line per TASK row of the new-form ledger, in table order:
# `N<TAB>VISUAL|—<TAB><Status cell>`. Visual is `VISUAL` only when the cell IS `VISUAL` (the check's read,
# by value); Status is the trimmed cell text, as written. The closing rows are not printed. 3 on the
# old form (a design without `## Decomposição` — its ledger is read by `Refs = all`, not here), so the
# launcher can name the hand-approval path by the CODE, not the text (the idiom of exit 3 in check mode).
# 2 on any other NAMED refusal (ERRO - …), nothing printed on stdout: folder, tasks.md or design.md missing; no ledger header; a header
# without `#`, `Task`, `Visual` or `Status`; a row whose arity differs from the header's; a non-numeric `#`
# on a row that is not a closing row. THE CONSUMER is the launcher's `visual` (it decides from these lines);
# this mode reads the ledger through the SAME definitions as the check and the generator
# (find_ledger_header, ledger_col, ledger_line_kind in mode `check`, cell_at, has_closing_token), so the
# three cannot disagree about which rows are tasks.
ledger_state() {
  local d="${1%/}" name
  [ -d "$d" ] || { gerr "pasta '$1' não existe."; return 2; }
  name="$(basename -- "$d")"
  local design="$d/design.md" tasks="$d/tasks.md"
  [ -f "$tasks" ] || { gerr "$name: tasks.md ausente — o ledger nasce no início da implementação (check-tasks.sh --ledger)."; return 2; }
  [ -f "$design" ] || { gerr "$name: design.md ausente — o estado do ledger sai do design aprovado."; return 2; }
  has_decomp "$(strip_html_comments "$design")" || {
    gerr "$name: design.md sem '## Decomposição' — forma antiga; o estado do ledger só é lido na forma nova."; return 3; }
  local ledger_hdr_row ledger_hdr_line=0 ledger_hdr_cells=0
  find_ledger_header "$tasks"
  [ "$ledger_hdr_line" -gt 0 ] || { gerr "$name: tasks.md sem tabela de ledger (nenhum header '| # |')."; return 2; }
  local num_idx task_idx vis_idx sta_idx
  num_idx="$(ledger_col "$ledger_hdr_row" '#')"; task_idx="$(ledger_col "$ledger_hdr_row" 'Task')"
  vis_idx="$(ledger_col "$ledger_hdr_row" 'Visual')"; sta_idx="$(ledger_col "$ledger_hdr_row" 'Status')"
  if [ -z "$num_idx" ] || [ -z "$task_idx" ] || [ -z "$vis_idx" ] || [ -z "$sta_idx" ]; then
    gerr "$name: tasks.md — header do ledger sem célula '#', 'Task', 'Visual' ou 'Status'."; return 2
  fi
  local started=0 i=0 line out="" num vis
  while IFS= read -r line; do
    i=$((i + 1))
    [ "$i" -le "$ledger_hdr_line" ] && continue
    ledger_line_kind "$line" "$started" check
    case "$LEDGER_KIND" in end) break ;; skip|sep) continue ;; esac
    started=1
    if [ "$(ncells "$line")" -ne "$ledger_hdr_cells" ]; then
      gerr "$name: tasks.md linha $i — aridade divergente ($(ncells "$line") células contra $ledger_hdr_cells do header)."; return 2
    fi
    num="$(cell_at "$line" "$num_idx")"
    case "$num" in
      ''|*[!0-9]*)
        has_closing_token "$(cell_at "$line" "$task_idx")" && continue
        gerr "$name: tasks.md linha $i — célula '#' não numérica ('$num') numa linha que não é de fechamento."; return 2 ;;
    esac
    vis='—'; [ "$(cell_at "$line" "$vis_idx")" = VISUAL ] && vis=VISUAL
    out="$out$num	$vis	$(cell_at "$line" "$sta_idx")
"
  done < "$tasks"
  printf '%s' "$out"
  return 0
}

# --- entry point ----------------------------------------------------------------------------------
# `--ledger` and `--transcricao` are MODES/flags, not positional tokens: both are scanned anywhere in
# the argv, because the natural way to type `--ledger` after running the check on a folder is
# `check-tasks.sh <dir> --ledger`, and in first position only that spelling silently ran the CHECK on
# `<dir>` and then treated `--ledger` as a second folder — a flag read as data. `--transcricao` (the
# launcher passes it right before transcribing a design) follows the same idiom for the same reason.
ledger_mode=0
estado_mode=0
change_dirs=()   # the change folders: the argv's, or (none given, check mode) the glob below
for a in "$@"; do
  case "$a" in
    --ledger) ledger_mode=1 ;;
    --estado) estado_mode=1 ;;
    --transcricao) transcricao_mode=1 ;;
    *) change_dirs+=("$a") ;;
  esac
done
if [ "$estado_mode" -eq 1 ]; then
  if [ "$ledger_mode" -eq 1 ] || [ "${#change_dirs[@]}" -ne 1 ]; then
    echo "ERRO - uso: check-tasks.sh --estado <dir> — exatamente UMA pasta de mudança, sem --ledger." >&2
    exit 2
  fi
  ledger_state "${change_dirs[0]}"
  exit $?
fi
if [ "$ledger_mode" -eq 1 ]; then
  if [ "${#change_dirs[@]}" -ne 1 ]; then
    echo "ERRO - uso: check-tasks.sh --ledger <dir> — exatamente UMA pasta de mudança (recebi ${#change_dirs[@]})." >&2
    exit 2
  fi
  gen_ledger "${change_dirs[0]}"
  exit $?
fi

# `${#change_dirs[@]}` is safe on an empty array under `set -u` (measured on bash 4.3 and 4.4); the
# array itself is only expanded below, once it is known to be non-empty.
if [ "${#change_dirs[@]}" -eq 0 ]; then
  for c in specs/proposed/*/ specs/active/*/; do [ -d "$c" ] && change_dirs+=("$c"); done
fi
if [ "${#change_dirs[@]}" -eq 0 ]; then
  echo "AVISOS: $avisos"
  echo "SKIP - nenhuma mudança em specs/proposed/ nem specs/active/ — nada a aferir."
  exit 0
fi

for c in "${change_dirs[@]}"; do check_change "$c"; done

# R2: the alarm's summary, ALWAYS printed (even when 0), once per hook execution — not per folder.
echo "AVISOS: $avisos"

if [ "$fail" -eq 0 ]; then
  echo "PASS - ${#change_dirs[@]} mudança(s) aferida(s): a cobertura R*↔task autoriza o plano."
  exit 0
fi
echo "FAIL - pelo menos uma mudança não está autorizada; a saída acima nomeia o motivo." >&2
# Exit 3 = every failure of the run was "tasks.md ausente." (the launcher reads the code, not the text);
# any other failure alongside it keeps today's 1.
if [ "$other_fail" -eq 0 ]; then exit 3; fi
exit 1
