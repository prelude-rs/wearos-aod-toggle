#!/usr/bin/env bash
# hooks-lib.sh — biblioteca comum dos hooks do sdd-kit; NÃO é um hook — nunca é ligado no
# `settings.json` nem roda sozinho; é carregado primeiro por todo hook e pelo lançador.
#
# What lives here: the rules that change 2026-10-biblioteca-comum-dos-hooks (epic 006) names as
# single-definition rules — the scaffolding of the two sibling portable checks and the archive gate's
# delegation (R3), the release-changelog reader and the seq (R4), the hook lookup in both layouts and
# the approval-marker reader (R5), the verdict reader (R6). They move in task by task; the file is
# born with no function, so that the load (below) and its failure could land first. Later changes add
# their own: the SoT readers `sot_decl_of` and `sot_sections` (R4 of 2026-10-check-tasks-defeitos),
# moved here from verify-archived-gates.sh so that check-tasks.sh reads the declaration the same way, the
# `Mode:` reader `mode_of` (R1 of 2026-10-hooks-sem-restos), spelled in copy by four hooks before, and the
# HTML-comment machine `HK_AWK_SHC` + `strip_html_comments` (the same R1), spelled in copy by three.
#
# Who loads it, and from where (design.md → "A carga e a falha de R2"):
#   - every hook that lives next to it: from the directory of its own ${BASH_SOURCE[0]} (not `$0`:
#     two hooks are also sourced by the launcher and the suites);
#   - check-commit-msg.sh, which runs installed in .git/hooks/: from .claude/hooks/ at the repo root;
#   - the launcher (sdd-approve, sdd-release): from the kit layout or the plugin layout.
# The load is the first statement after each file's header, before any `set` or side effect. Without
# this file every loader fails closed naming it: the checks exit 1, the edit guard exits 2 — it
# then blocks every Edit/Write/MultiEdit call of the agent, and only the human restores
# the file, typing with the `!` prefix, which no hook sees — and the launcher refuses with 2 before
# writing anything. A file that loads but lacks a function its loader calls fails the same way: right
# after the load, each loader that calls into this file checks, with `declare -F` (a builtin, no fork),
# every function it calls — and the guard checks hk_lib_loaded, the LAST definition below, so a
# load that stopped early (a stray `return`) never lets it decide; the name it then prints says
# the library is "incompleta".
# The EXIT trap around the load (R4 of 2026-10-guardas-sem-falso-positivo) — explained HERE, once. Every
# loader (every file that loads this library; the R2 tables of tests/test-hooks.sh and the launcher
# suites list them) writes the code in line, because this file cannot load itself, and points here with
# one comment line:
#   - What it catches: a load that ends in an `exit` of this file — any code, 0 included, anywhere in its
#     body — fails like the absence: the loader's own code (2 in the guard and in the two launcher
#     scripts, 1 in the checks and in check-commit-msg.sh) and the absence's message, once, also under
#     POSIXLY_CORRECT. Before, an `exit 0` let the loader pass silently (a guard opened, a check passed
#     without having run, every commit went through unchecked, the launcher exited 0 without refusing)
#     and an `exit 3` exited 3.
#   - How: the loader arms `trap '…; exit <code>' EXIT` right before the load group, and the group ends
#     in `|| exit`, so an absent or unreadable file, or a `.` that fails, leaves through the same trap —
#     one message, the absence's text, and the loader's code.
#   - The message sits in a variable (HK_LIB_GONE) expanded at its assignment, in the loader, before the
#     load: it names the loader itself (inside this file ${BASH_SOURCE[0]} is already hooks-lib.sh) and,
#     in the launcher scripts, the two layout directories; the trap only echoes it.
#   - fd 9: the group's `2>/dev/null` (it hides bash's raw line; ours is the only one) is still in force
#     when the `exit` runs, so the trap writes to fd 9 — the real stderr, saved by `9>&2` for the group
#     only.
#   - Disarm: `trap - EXIT` right after the load. It clears ANY EXIT trap of the shell doing the load, so
#     a loader arms its own EXIT trap only after the load (preflight-launcher.sh and release-impl.sh do),
#     and whoever sources a loader (the launcher sources require-approved-spec.sh; the suites source it
#     and verify-archived-gates.sh, always in subshells) does it in a subshell or before arming its own
#     trap — as all of them do today.
#   - check-commit-msg.sh, the two-attempt variant: the trap is armed before the FIRST attempt (relative
#     to the cwd), which has no `|| exit` — its absence leads to the second (from `git rev-parse
#     --show-toplevel`), which has it. The absence names the SECOND attempt's path, so the trap recomputes
#     HK_DIR the way the second attempt does (one fork, only on the failure path) and prints that same
#     text, written in the trap itself — an `exit` in either attempt names
#     <toplevel>/.claude/hooks/hooks-lib.sh. Each group saves fd 9 with its own `9>&2`; `trap - EXIT`
#     disarms after the whole block.
#   - Not caught (residual): a library that arms its own EXIT trap and then exits, or that runs `exec` or
#     `kill $$`.
#
# Properties of the whole file (every task that adds to it keeps them):
#   - On load: only function definitions and constants (the awk program texts HK_AWK_CHANGELOG of R4 and
#     HK_AWK_SHC, the name list HK_GIT_REPO_VARS). No command runs:
#     no `set`, no `exit`, no read from stdin, no write, no output. No `readonly`: loading twice (the
#     launcher loads it, then sources the gate, which loads it again) must be idempotent.
#   - Run directly, it defines nothing anyone keeps and exits 0.
#   - Functions never `exit` (they return a code), never write a file, never change a shell option.
#   - Names: a function moved here keeps the name it has today (verdict_of, sot_decl_of, sot_sections, mode_of,
#     strip_html_comments); new functions take the `hk_` prefix, new globals the `HK_` prefix (in awk text
#     too: hk_shc, hk_inc). The two helpers of sot_decl_of
#     keep the names its design gives them (`_sot_fields`, `_sot_trim_st`) and write only its locals.
#   - None of the three awk/pipe forms that specs/SOURCE-OF-TRUTH.md (section Hooks) bars, anywhere
#     in the file: no function-call-then-space concatenation in awk (write the conditional in
#     parentheses, then the string), no counted repetition (brace intervals) in a regex, and no
#     producer piped into an early-exit consumer (grep -q, head) whose status decides a branch under
#     pipefail (capture first, then test a here-string or a parameter expansion).
#   - Comments in English, messages in pt-BR (spec-layout, "Language & rendering").

# --- R3: the scaffolding of the two sibling portable checks (check-release-changelog.sh and
# check-epic-numbering.sh). Each check keeps its usage message, its failure messages, its record
# handler and its own reaction to the sentinel; what both carried in copy lives here, once.

# hk_base_root_flags [args…] — R3: THE reader of the sibling checks' arguments.
# Accepts `--base <ref>` (the next argument, whatever it is, taken as the value) and `--base=<ref>` (a
# non-empty value either way; the last one wins), at most one positional (the root), and every other `-*`
# argument, in any position, collected as given into the array HK_FLAGS — the library knows no flag but
# --base, so each check accepts its own from HK_FLAGS and refuses the rest with its own usage. Writes BASE
# ("" without --base), HAS_BASE (0|1), R (default `.`; a relative root gets the `./` prefix — an awk operand
# shaped `name=value` is an assignment, not a file) and HK_FLAGS (an array, empty without flags). Returns 0;
# 2 on a usage error (--base without a value or with an empty one, a second positional, a root that is not
# a directory) — the caller does `hk_base_root_flags "$@" || usage` and then reads HK_FLAGS, so the usage
# message stays each check's own. Prints nothing. An empty positional counts as no root (`.`) and a later
# positional is still taken. The name is new because the contract is: a check and a library of different
# versions (the earlier hk_base_root_args <extra-flags> refused unknown flags itself) miss each other's
# function in the `declare -F` and fail "incompleta", instead of reading the flags under the wrong contract.
# shellcheck disable=SC2034 # BASE, HAS_BASE, R and HK_FLAGS are written for the caller to read
hk_base_root_flags() {
  BASE=""; HAS_BASE=0; R=""; HK_FLAGS=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --base)   { [ "$#" -ge 2 ] && [ -n "$2" ]; } || return 2; BASE="$2"; HAS_BASE=1; shift 2 ;;
      --base=*) BASE="${1#--base=}"; [ -n "$BASE" ] || return 2; HAS_BASE=1; shift ;;
      -*)       HK_FLAGS+=("$1"); shift ;;
      *)        [ -z "$R" ] || return 2; R="$1"; shift ;;
    esac
  done
  R="${R:-.}"
  [ -d "$R" ] || return 2
  case "$R" in /*) ;; *) R="./$R" ;; esac
  return 0
}

# hk_base_resolves <root> <ref> — R3: 0 iff <ref> resolves to a commit in the repo at <root>
# (`rev-parse --verify --quiet <ref>^{commit}`); git's output is discarded. The failure message stays in
# each check, with its own prefix.
hk_base_resolves() {
  git -C "$1" rev-parse --verify --quiet "$2^{commit}" >/dev/null 2>&1
}

# hk_pr_to_main <ref> — R3: THE rule "PR to main": 0 iff the last `/`-segment of <ref> is `main`
# (`origin/main` and `main` are; `mainline` and `main/x` are not). check-epic-numbering.sh composes it
# with its own `has_dev` on its `# G-main` line — the promotion dispensation is that check's alone.
hk_pr_to_main() {
  [ "${1##*/}" = main ]
}

# hk_awk_records <handler> <command> [args…] — R3: the record loop of the sibling checks. Runs
# <command> [args…] (each check's run_awk) and reads its stdout line by line in the CURRENT shell
# (process substitution, never a pipe: the handler sets `bad` and the check's own variables). A line
# `<type><TAB><rest>` with a one-character <type>: `S` sets HK_STATS=<rest> (the last one wins); any
# other type calls `<handler> <type> <rest>` (the rest may hold TABs — only the first one splits). A
# line of any other shape is ignored, as the copies did. Returns 0 if an `S` record was seen and 1 if
# not — the sentinel "no S = awk did not finish", to which each check reacts in its own way. HK_STATS
# starts empty at every call. Locals carry the hk_ prefix: the handler runs inside this function and
# would otherwise see them (bash scoping is dynamic).
hk_awk_records() {
  local hk_h="$1" hk_rec hk_t hk_rc=1 hk_tab=$'\t'
  shift
  HK_STATS=""
  while IFS= read -r hk_rec; do
    case "$hk_rec" in
      ?"$hk_tab"*)
        hk_t="${hk_rec%%"$hk_tab"*}"
        if [ "$hk_t" = S ]; then HK_STATS="${hk_rec#*"$hk_tab"}"; hk_rc=0
        else "$hk_h" "$hk_t" "${hk_rec#*"$hk_tab"}"; fi ;;
    esac
  done < <("$@")
  return "$hk_rc"
}

# hk_pass_line <label> <failed> — R3: the PASS/exit tail of the sibling checks. <failed> is the check's
# failure flag, passed BY VALUE (each check passes its own `bad`; this library reads no variable of the
# caller by name). Reads HK_STATS. With <failed>=0 prints `<label>: PASS (<HK_STATS>)` on stdout and
# returns 0; otherwise returns 1 and prints nothing. The caller ends with
# `hk_pass_line "<label>" "$bad"; exit $?` — this library never exits.
# Fails CLOSED: a missing, empty or non-numeric <failed> is not 0, so it returns 1 with no PASS line (a
# PASS on a missing flag would be a bypass).
hk_pass_line() {
  [ "${2-}" -eq 0 ] 2>/dev/null || return 1
  printf '%s: PASS (%s)\n' "$1" "${HK_STATS-}"
  return 0
}

# --- R3: the archive gate (verify-archived-gates.sh) — its base and its delegation to the three
# portable checks next to it.

# hk_gate_base [arg1] — R3: THE precedence of the gate's base, called as `hk_gate_base "$@"` at the top
# of verify-archived-gates.sh. Writes BASE (arg1 if non-empty; else $BASE_REF if non-empty; else
# origin/main) and HK_BASE_EXPLICIT (1 if arg1 or BASE_REF is non-empty, else 0 — an empty argument is
# no base, as `${1:-…}` read it). Reads BASE_REF. Returns 0.
# shellcheck disable=SC2034 # BASE and HK_BASE_EXPLICIT are written for the gate (and hk_delegate) to read
hk_gate_base() {
  if [ -n "${1-}" ]; then BASE="$1"; HK_BASE_EXPLICIT=1
  elif [ -n "${BASE_REF-}" ]; then BASE="$BASE_REF"; HK_BASE_EXPLICIT=1
  else BASE=origin/main; HK_BASE_EXPLICIT=0
  fi
  return 0
}

# hk_delegate <label> <script> <check|aviso> — R3: the gate's delegation to a portable check that lives
# next to it. Reads HK_DIR, BASE and HK_BASE_EXPLICIT. <script> missing from $HK_DIR: prints
# `FAIL - <label>: check ausente (<script>)` on stderr and returns 1, in both modes (a broken install is
# not a pass by omission). Mode `check`: runs `bash <script> --base "$BASE"` when HK_BASE_EXPLICIT=1,
# else `bash <script>` (without an explicit base a local run must not fall into the `main` rules through
# the origin/main default), and returns the script's code. Mode `aviso`: runs `bash <script>` (no base),
# discards its code and returns 0 — the closing-debt check is a warning by contract and refuses
# --base. Any other mode is a caller bug: a FAIL line and 1 (closed, never a silent pass). The
# script's output passes straight through (inherited stdout/stderr): nothing is filtered.
hk_delegate() {
  local hk_s="${HK_DIR-.}/$2"
  if [ ! -f "$hk_s" ]; then
    echo "FAIL - $1: check ausente ($2)" >&2
    return 1
  fi
  case "$3" in
    check) if [ "${HK_BASE_EXPLICIT-0}" = 1 ]; then bash "$hk_s" --base "$BASE"; else bash "$hk_s"; fi ;;
    aviso) bash "$hk_s" || true; return 0 ;;
    *)     echo "FAIL - $1: modo de delegação desconhecido ($3)" >&2; return 1 ;;
  esac
}

# --- R4: THE reader of the release changelog (the root CHANGELOG.md, keep-a-changelog) and of a
# ledger seq line (specs/CHANGELOG.md). One definition, used by check-release-changelog.sh (the law
# that fails a PR — every definition below is the one that check already used), by sdd-release
# (scripts/release-impl.sh, through hk_cl_section), by tests/check-spec-layout.sh, by
# .claude/adopt/adopt.py (the seed's birth marker, through hk_ledger_seqs) and by
# check-epic-numbering.sh — which reads no changelog: it puts the program in front of its own only for
# hk_seq_num (the NNN of an epic file name). So a function (or global) added here must not collide with
# that check's awk names either: fail, trim, base, in_form, num, slug, key, collide, is_new, why,
# epic_path, legacy_line, mark_new.

# HK_AWK_CHANGELOG — awk program text made only of function definitions, concatenated IN FRONT of each
# consumer's own program (`awk "$HK_AWK_CHANGELOG$PROG" …`): predicates on one line, so the decisions
# (and the check's `# F-*` anchors) stay in the consumer. The ten functions:
#   hk_seq_num(s)        a string of digits → its number, leading zeros dropped first (a lone `0` stays
#                        0): busybox awk reads "012" + 0 as octal, 10, where gawk and mawk read 12 — the
#                        answer must not depend on the awk. Every seq this kit reads goes through it: the
#                        two readers below and the check's release declaration and birth marker — and
#                        so does every epic NNN check-epic-numbering.sh compares (its only use of this
#                        program)
#   hk_ledger_seq(l)     ledger line `^| *N *|` (spaces only) → N (a number); else −1
#   hk_cl_is_boundary(l) `^## ` — every such line closes the current section
#   hk_cl_is_section(l)  a version section heading: `^## \[.+\]` (`## [x` without `]` is only a boundary)
#   hk_cl_name(l)        the name: what follows `## [` up to the first `]` (`## []]` is a section named "")
#   hk_cl_is_item(l)     `^- ` (inside a section — the caller knows whether it is in one)
#   hk_cl_item_seq(l)    the N of `(seq N)` or `(seq N, #P)` at the END of the line (trailing blanks
#                        tolerated) → N (a number); else −1
#   hk_cl_has_text(l)    section content: neither blank nor a category heading (`^###[[:space:]]`) —
#                        a section with no such line is "empty" for sdd-release
#   hk_cl_open(k, l)     opens the text of the section keyed k with its heading line l
#   hk_cl_add(k, l)      adds one body line to the text keyed k
# THE TEXT OF A SECTION (the common definition — exactly what the check's F-imut compares): the heading
# line, then each body line up to the next boundary, each after a "\n"; blank lines (`^[[:space:]]*$`)
# at the start and in the middle are kept, blank lines at the end never enter (they wait in
# HK_CL_PEND[k] and only enter in front of a later line with text). A version with two `## [v]`
# headings: the LAST one wins — the second hk_cl_open reopens the text. The two global arrays the
# fragment uses are HK_CL_TEXT and HK_CL_PEND; the key is the caller's (the check uses `p SUBSEP name`).
# None of the three barred forms: no call-space-paren concatenation, no brace interval, no pipe.
# shellcheck disable=SC2016 # awk program text: nothing in it is meant to expand
HK_AWK_CHANGELOG='
function hk_seq_num(s) {
  sub(/^0+/, "", s); if (s == "") s = "0"
  return s + 0
}
function hk_ledger_seq(l,   s) {
  if (l !~ /^\| *[0-9]+ *\|/) return -1
  s = l; sub(/^\| */, "", s); sub(/ *\|.*$/, "", s)
  return hk_seq_num(s)
}
function hk_cl_is_boundary(l) { return (l ~ /^## /) }
function hk_cl_is_section(l) { return (l ~ /^## \[.+\]/) }
function hk_cl_name(l,   n) { n = l; sub(/^## \[/, "", n); sub(/\].*$/, "", n); return n }
function hk_cl_is_item(l) { return (l ~ /^- /) }
function hk_cl_item_seq(l,   v) {
  if (!match(l, /\(seq [0-9]+(, #[0-9]+)?\)[[:space:]]*$/)) return -1
  v = substr(l, RSTART + 5); sub(/[^0-9].*$/, "", v)
  return hk_seq_num(v)
}
function hk_cl_has_text(l) { return (l !~ /^[[:space:]]*$/ && l !~ /^###[[:space:]]/) }
function hk_cl_open(k, l) { HK_CL_TEXT[k] = l; HK_CL_PEND[k] = "" }
function hk_cl_add(k, l) {
  if (l ~ /^[[:space:]]*$/) HK_CL_PEND[k] = HK_CL_PEND[k] "\n" l
  else { HK_CL_TEXT[k] = HK_CL_TEXT[k] HK_CL_PEND[k] "\n" l; HK_CL_PEND[k] = "" }
}
'

# hk_cl_section <file> <version> — R4: the section `[<version>]` of <file> by the common definition
# (above): one awk pass with HK_AWK_CHANGELOG that opens/adds every section of the file keyed by its
# name (lines under a section named "" are not added — the check's `c != ""`) and, at the end, hands
# over the one asked for (its last occurrence). The version goes through ENVIRON (HK_CL_VER, never
# `awk -v`, whose escape processing corrupts text) and is compared by string equality; an empty
# version is never found. Writes HK_SECTION_FOUND (0|1), HK_SECTION_TEXT (the common text, heading
# included — nothing trimmed) and HK_SECTION_HASTEXT (0|1: some line of the text after the heading
# satisfies hk_cl_has_text). Returns 0; 1 when awk fails or its answer is malformed (then FOUND=0,
# TEXT="" and HASTEXT=0). The first line of awk's output (the two flags) is split from the text by
# parameter expansion — no head/tail, no pipe. What a consumer SHOWS is derived at its call site (the
# release notes drop the heading and the leading blank lines).
# shellcheck disable=SC2034 # HK_SECTION_* are written for the caller to read
hk_cl_section() {
  local hk_out hk_meta hk_nl=$'\n'
  HK_SECTION_FOUND=0; HK_SECTION_TEXT=""; HK_SECTION_HASTEXT=0
  hk_out="$(HK_CL_VER="$2" awk "$HK_AWK_CHANGELOG"'
    hk_cl_is_boundary($0) { cur = ""; if (hk_cl_is_section($0)) { cur = hk_cl_name($0); hk_cl_open(cur, $0) }; next }
    cur != "" { hk_cl_add(cur, $0) }
    END {
      v = ENVIRON["HK_CL_VER"]
      if (v == "" || !(v in HK_CL_TEXT)) { print "0 0"; exit }
      n = split(HK_CL_TEXT[v], hk_l, "\n"); has = 0
      for (i = 2; i <= n; i++) if (hk_cl_has_text(hk_l[i])) has = 1
      printf "1 %d\n%s\n", has, HK_CL_TEXT[v]
    }' "$1")" || return 1
  hk_meta="${hk_out%%"$hk_nl"*}"
  case "$hk_meta" in
    "0 0") return 0 ;;
    "1 0"|"1 1") ;;
    *) return 1 ;;
  esac
  case "$hk_out" in *"$hk_nl"*) ;; *) return 1 ;; esac
  HK_SECTION_FOUND=1
  HK_SECTION_HASTEXT="${hk_meta#1 }"
  HK_SECTION_TEXT="${hk_out#*"$hk_nl"}"
  return 0
}

# hk_ledger_seqs <file> — R4: the seq of every ledger line of <file> (specs/CHANGELOG.md), by
# hk_ledger_seq (`| N |` with spaces only), one per line on stdout, in file order; lines that are not
# ledger seq lines print nothing. `print`, not printf "%d": busybox awk's %d wraps above 2^31-1.
# Returns awk's code (non-zero when <file> cannot be read).
# Its consumer is .claude/adopt/adopt.py, which runs it from the kit (`bash -c '. "$1" &&
# hk_ledger_seqs "$2"' _ <lib> <ledger>`) and takes the maximum itself.
hk_ledger_seqs() {
  awk "$HK_AWK_CHANGELOG"'{ hk_s = hk_ledger_seq($0); if (hk_s >= 0) print hk_s }' "$1"
}

# hk_find_hook <name> — R5: THE lookup of a hook in the two layouts. Reads HK_LAYOUTS, the array the
# launcher's bootstrap sets (kit checkout first, installed plugin second). Prints the path of <name>
# in the first directory of the list that has it and returns 0; in none, prints on stderr the message
# that names both directories and returns 1 — the caller exits 2. Each hook is looked up in both
# layouts (not only where this library was found): a mixed install behaves as before. The `+` forms
# keep `set -u` callers from aborting on an unset array: the miss is then the named message.
hk_find_hook() {
  local d
  for d in ${HK_LAYOUTS[@]+"${HK_LAYOUTS[@]}"}; do
    [ -f "$d/$1" ] && { printf '%s\n' "$d/$1"; return 0; }
  done
  echo "sdd-kit: $1 não encontrado em ${HK_LAYOUTS[0]-}/ nem em ${HK_LAYOUTS[1]-}/ — instalação incompleta?" >&2
  return 1
}

# hk_marker_value <file> <approved-content|approved-by> — R5: THE reader of the approval marker, under
# require-approved-spec.sh's recorded_digest (the recorded digest) and the launcher's approved_when
# (the date of the previous approval), each a one-line wrapper over it. Prints the value of the FIRST
# marker of that kind in the CLOSED form, anchored at both ends — a truncated marker counts as absent
# (=> re-approve), never as verified: for approved-content, the hex after `sha256:`; for approved-by,
# the date after the LAST ` on ` (the `.*` is greedy). Prints nothing when there is no such marker.
# Returns awk's status (0 on a readable file); 2 for an unknown kind, with nothing read.
# The two addresses are the ones the two copies carried, byte for byte, written STATIC in the awk
# program; the kind only picks the branch, through ENVIRON — never a regex built at run time: the
# UTF-8 locale case (I1) and the mawk/busybox portability of 2026-10-hooks-defeitos-e-pin were
# measured on these bytes. awk reads the file directly and `exit`s on the first match: no pipe, so no
# SIGPIPE under a caller's `set -euo pipefail` with thousands of markers (the abort that change fixed
# when the read was `sed … | head -1`). `sub()` isolates the value instead of a capture group.
hk_marker_value() {
  case "$2" in
    approved-content|approved-by) ;;
    *) return 2 ;;
  esac
  HK_MARKER_KIND="$2" awk '
    ENVIRON["HK_MARKER_KIND"] == "approved-content" && /^<!-- approved-content: sha256:[0-9a-f]* -->$/ {
      val = $0
      sub(/^<!-- approved-content: sha256:/, "", val)
      sub(/ -->$/, "", val)
      print val
      exit
    }
    ENVIRON["HK_MARKER_KIND"] == "approved-by" && /^<!-- approved-by: .* on [0-9][0-9-]* -->$/ {
      val = $0
      sub(/^<!-- approved-by: .* on /, "", val)
      sub(/ -->$/, "", val)
      print val
      exit
    }
  ' "$1"
}

# verdict_of <file> — R6: THE reader of an artifact's verdict, used by require-approved-spec.sh,
# verify-archived-gates.sh, check-report.sh and check-closing-debt.sh (each held a byte-identical copy
# before; the body below is that copy, unchanged). Prints the VALUE of the 1st `^Verdict:` field
# (case-blind): HTML comment stripped, field name stripped, first word, upper-cased — so
# `Verdict: pass` reads PASS and `Verdict: PASS — com ressalvas` reads PASS. Reading the LINE instead
# of the VALUE was a bypass: the line the templates emit carries a comment with BOTH tokens
# (`Verdict: INCOMPLETE   <!-- COMPLETE | INCOMPLETE ... -->`), so `grep -w COMPLETE` would match
# inside the comment and the guard could NEVER reject. The `-w` was correct and was irrelevant —
# positive control: `Verdict: INCOMPLETE` alone does not match `COMPLETE`. See
# 2026-07-verdict-lido-do-valor.
# sed ORDER MATTERS: the comment is stripped BEFORE the field name. Reversed, the `^Verdict:` that
# exists INSIDE change.md's template comment would be bitten by the second substitution.
# Comparing the value (instead of matching a word in the line) also kills `PASSOU`/`COMPLETADO`,
# which a positional anchor (`^Verdict:[[:space:]]*PASS`) would let through. Free-form prose AFTER
# the token is legitimate, same as the epic-closing destination. Same reader as
# tests/check-epic-closing.sh:45-47 and :70.
# Returns the token ALREADY NORMALIZED to uppercase: the case-insensitivity that `-qiwE` gave is
# part of the contract (N4), and normalizing here avoids repeating `| tr` at every call site.
# A missing/unreadable file or no `^Verdict:` line prints nothing and returns 0 (`|| true`).
verdict_of() {
  { grep -m1 -iE '^Verdict:' "$1" 2>/dev/null || true; } \
    | sed -E 's/<!--.*//; s/^[Vv]erdict:[[:space:]]*//' \
    | awk '{print toupper($1)}'
}

# --- R1 of 2026-10-hooks-sem-restos: readings that several hooks spelled in copy, defined once here. They come
# BEFORE the SoT readers, so that a loader that finds sot_decl_of (`declare -F`) knows they were read too.

# mode_of <file> — THE reader of a change.md's `Mode:`, used by require-approved-spec.sh, verify-archived-gates.sh,
# check-closing-debt.sh and check-tasks.sh (each spelled this line before; the name is the one two of them gave
# it). Prints the VALUE of the 1st `^Mode:` field — its 2nd whitespace-separated word, e.g. `fast` — or nothing;
# status 0 (`|| true`: no `Mode:` line is legitimate, a legacy or hand-edited change.md).
# The reading is the line's, byte for byte, and two of its edges are kept on purpose (design → "Data modeling"):
#   - a CRLF change.md: under gawk and mawk the 2nd field is `fast\r`, which is not `fast` — the folder is read by
#     the formal flow; busybox awk (1.31.0) splits at the `\r` and reads `fast`. Each awk keeps its own reading;
#   - no `2>/dev/null` HERE: on a change.md that is a directory or unreadable, grep's own line goes to the
#     caller's stderr. The guard lets it through (it always did); the archive gate, the closing-debt warning and
#     the plan check write `2>/dev/null` at their call, as they always hid it.
mode_of() { grep -m1 '^Mode:' "$1" | awk '{print $2}' || true; }

# HK_AWK_SHC — awk program text of definitions only, put in front of the caller's program (the HK_AWK_CHANGELOG
# idiom). hk_shc(line) returns the part of <line> outside HTML comments — spans that OPEN mid-line and spans that
# RUN ACROSS lines: a state machine, not `grep -v '^<!--'` — and keeps the state `hk_inc` (inside a comment)
# across the calls of one awk run. One machine for check-tasks.sh, check-report.sh and sot_decl_of, which each
# spelled it in copy before; the ORDER stays with each caller: strip_html_comments passes every line of the file
# (comment first), sot_decl_of only the lines of its section (section first — a `## ` line inside a multi-line
# comment still ends the section; design → "Data modeling"). None of the three barred forms.
# shellcheck disable=SC2016 # awk program text: nothing in it is meant to expand
HK_AWK_SHC='
function hk_shc(line,    i, out) {
  out = ""
  while (1) {
    if (hk_inc) { i=index(line,"-->"); if (i==0) { line=""; break } ; hk_inc=0; line=substr(line,i+3) }
    else        { i=index(line,"<!--"); if (i==0) { out=out line; break } ; out=out substr(line,1,i-1); hk_inc=1; line=substr(line,i+4) }
  }
  return out
}
'

# strip_html_comments <file> — the body of <file> with every `<!-- ... -->` span removed (hk_shc over every line).
# One output line per input line, so LINE NUMBERS ARE PRESERVED — the plan check's (g) points the human at a real
# line of the real file. Called by check-tasks.sh and check-report.sh (the name is the one both gave it).
strip_html_comments() {
  awk "$HK_AWK_SHC"'{ print hk_shc($0) }' "$1"
}

# --- R4 of 2026-10-check-tasks-defeitos: the SoT readers. The archive gate (verify-archived-gates.sh)
# judges a new archived change's declaration with them, and check-tasks.sh judges the declaration of a
# folder in specs/proposed/ or specs/active/ with the SAME reading — one definition, here. Their names
# are the ones they had in the gate (the suites call them through the gate's SDD_GATE_SOURCE_ONLY mode,
# which loads this file first). The two helpers come BEFORE sot_decl_of: a loader that finds
# sot_decl_of (`declare -F`) knows they were read too.

# _sot_fields <line> — SOT_F = the fields of <line> split at `|`, exactly like awk -F'|' (field i of awk
# is SOT_F[i-1]; NF is ${#SOT_F[@]}), with no fork. SOT_F is sot_decl_of's local (bash dynamic scoping):
# no global is created.
_sot_fields() {
  local rest="$1"; SOT_F=()
  while :; do
    case "$rest" in *'|'*) SOT_F+=("${rest%%|*}"); rest="${rest#*|}" ;; *) SOT_F+=("$rest"); break ;; esac
  done
}
# _sot_trim_st <text> — SOT_T = <text> without leading/trailing spaces and tabs (awk's [ \t], not
# [:space:]), with no fork. SOT_T is sot_decl_of's local, like SOT_F.
_sot_trim_st() {
  SOT_T="$1"; SOT_T="${SOT_T#"${SOT_T%%[!$' \t']*}"}"; SOT_T="${SOT_T%"${SOT_T##*[!$' \t']}"}"
}

# sot_decl_of <file> — reads the "## Seções do SoT afetadas" declaration (spec.md/change.md). The
# section is found BY HEADING NAME (never by position); its body runs until the next `## ` heading.
# HTML comments are stripped BEFORE any matching — the template emits SOT-NO-DELTA (and a sample
# heading) inside an instruction comment, and that must never count (same lesson as verdict_of).
# The table's heading column is found BY HEADER NAME ("Seção do SoT…"), never a fixed index.
# Prints to stdout, one line per item: "HEADING\t<text>" per data row (verbatim, trimmed), or
# "NODELTA\t<motivo>", or MISSING / EMPTY / CONFLICT (table rows AND token together — CONFLICT is
# the ONLY line printed then, no HEADING leaks alongside it). Never exits the shell; never writes
# files.
# No process per line of the section (N5 of 2026-10-check-tasks-defeitos): the section and the comment
# stripper are ONE awk (they were two, the second `_sot_strip_comments`), and the per-line `awk -F'|'`
# and separator `grep` are the bash helpers above. The locale-dependent steps — the [:space:] trim of
# each line and of the motive, the `tr` test, the token `grep`/`sed` — stay as they were, so the output
# is byte-identical to the gate's former reader in every locale and awk measured with glibc (design.md
# → "Superfície heurística: código medido").
sot_decl_of() {
  local f="$1" sec line col="" motive="" has_token=0 rows=0 v i SOT_T=""
  local -a headings=() SOT_F=()

  [ -f "$f" ] || { echo MISSING; return 0; }

  # One awk: the section (by name, up to the next `## `) with its HTML comments stripped (single- and
  # multi-line) by the library's machine (HK_AWK_SHC), line by line, before any token/table matching. SECTION
  # FIRST, comment after: the three section lines run on the raw line, so a `## ` line inside a multi-line
  # comment ends the section there (design → "Data modeling"). Portable awk (mawk/busybox-safe).
  sec="$(awk "$HK_AWK_SHC"'
    /^## Seções do SoT afetadas/ { on = 1; next }
    on && /^## / { on = 0 }
    !on { next }
    { print hk_shc($0) }
  ' "$f")"

  [ -n "$(printf '%s' "$sec" | tr -d '[:space:]')" ] || { echo MISSING; return 0; }

  if grep -qE '^SOT-NO-DELTA:' <<< "$sec"; then
    has_token=1
    motive="$(printf '%s\n' "$sec" | grep -m1 -E '^SOT-NO-DELTA:' | sed -E 's/^SOT-NO-DELTA:[[:space:]]*//')"
  fi

  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    case "$line" in
      '|'*)
        _sot_fields "$line"
        if [ -z "$col" ]; then
          for (( i = 2; i < ${#SOT_F[@]}; i++ )); do
            _sot_trim_st "${SOT_F[i-1]}"
            case "$SOT_T" in "Seção do SoT"*) col="$i"; break ;; esac
          done
          continue
        fi
        [[ "$line" =~ ^[-\|:\ ]+$ ]] && continue   # separator row
        _sot_trim_st "${SOT_F[col-1]-}"; v="$SOT_T"
        [ -n "$v" ] && { headings+=("$v"); rows=$((rows + 1)); }
        ;;
    esac
  done <<< "$sec"

  if [ "$has_token" -eq 1 ] && [ "$rows" -gt 0 ]; then echo CONFLICT; return 0; fi
  if [ "$has_token" -eq 1 ]; then
    if [ -n "$motive" ]; then printf 'NODELTA\t%s\n' "$motive"; else echo EMPTY; fi
    return 0
  fi
  if [ "$rows" -gt 0 ]; then
    for v in "${headings[@]}"; do printf 'HEADING\t%s\n' "$v"; done
    return 0
  fi
  echo MISSING
}

# sot_sections <git-ref> — reads specs/SOURCE-OF-TRUTH.md at <git-ref> of the repository of the current
# directory, and prints one line per level-1–3 section: START\tEND\tLEVEL\tTEXT (TEXT = heading text
# without the `#`s, trimmed).
# Level 4+ headings (`####` and beyond) never start a new section — they belong to the enclosing
# section (the kit's own SoT has seven H4 under "### Adoption"). The FIRST section's START is
# forced to 1: lines before the first heading belong to it (the `app` SoT has its H1 at line 3,
# preceded by two warning lines). A section runs to the line before the next level-1–3 heading, or
# to EOF. No level-1–3 heading anywhere → prints exactly `NOSECTIONS` (never silent — I3/N5).
# specs/SOURCE-OF-TRUTH.md missing at <git-ref> entirely (deleted) → prints exactly `SOT-DELETED`,
# a distinct token from `NOSECTIONS` (which means the file exists but has no heading).
# Heading match is a literal-prefix test (`^# `, `^## `, `^### `), not an ERE interval — mawk
# portability: no ERE intervals (same constraint as sot-history-lint.sh): a 4th `#` makes the 3-char prefix miss
# its required trailing space, so `#### sub` naturally fails all three tests without extra logic.
sot_sections() {
  local ref="$1"
  if ! git cat-file -e "${ref}:specs/SOURCE-OF-TRUTH.md" 2>/dev/null; then
    echo SOT-DELETED
    return 0
  fi
  git show "${ref}:specs/SOURCE-OF-TRUTH.md" 2>/dev/null | awk '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    {
      lineno++
      level = 0
      if ($0 ~ /^# /)        { level = 1; text = substr($0, 3) }
      else if ($0 ~ /^## /)  { level = 2; text = substr($0, 4) }
      else if ($0 ~ /^### /) { level = 3; text = substr($0, 5) }
      if (level > 0) {
        n++
        hline[n] = lineno
        hlevel[n] = level
        htext[n] = trim(text)
      }
      last = lineno
    }
    END {
      if (n == 0) { print "NOSECTIONS"; exit }
      for (i = 1; i <= n; i++) {
        start = (i == 1) ? 1 : hline[i]
        end = (i < n) ? hline[i + 1] - 1 : last
        print start "\t" end "\t" hlevel[i] "\t" htext[i]
      }
    }
  '
}

# hk_sot_heading_lines <sections> <heading> — THE lookup of a declared heading in the output of
# sot_sections (<sections>, read by the caller once). Writes HK_SOT_LINES: the START line of every section
# whose TEXT is exactly <heading> (string equality, as the archive gate has always compared), joined by
# ", ", in file order; empty when no section matches. Also writes HK_SOT_COUNT: how many sections have
# that heading. Prints nothing — a variable, not stdout, so the
# caller pays no subshell per heading (N5 of 2026-10-check-tasks-defeitos: with `$(…)` the check measured
# about 2 ms per declared heading). The caller reads the answer by HK_SOT_COUNT: 0 = the heading does
# not exist; 1 = it exists once; 2 or more = it is repeated (ambiguous), and HK_SOT_LINES is the list
# to show in the message. An empty line of <sections> is skipped; the NOSECTIONS and
# SOT-DELETED tokens carry no TEXT, so they never match a non-empty heading (both callers handle them
# before, and never ask for an empty one). Returns 0.
# Used by verify-archived-gates.sh (FAIL) and check-tasks.sh (AVISO) — the verdicts stay in each hook.
# shellcheck disable=SC2034 # HK_SOT_LINES and HK_SOT_COUNT are written for the caller to read
hk_sot_heading_lines() {
  local st _en _lv tx
  HK_SOT_LINES=""
  HK_SOT_COUNT=0
  while IFS=$'\t' read -r st _en _lv tx; do
    [ -n "$st" ] || continue
    if [ "$tx" = "$2" ]; then HK_SOT_LINES="${HK_SOT_LINES:+$HK_SOT_LINES, }$st"; HK_SOT_COUNT=$((HK_SOT_COUNT + 1)); fi
  done <<< "$1"
  return 0
}

# --- R1 of 2026-10-hooks-imunes-ao-ambiente: the repository a hook reads is the one of its cwd.

# HK_GIT_REPO_VARS — the git environment variables that make git read ANOTHER repository, index or object
# store than the one of the cwd (measured in that change's design, "Data modeling"; `git -C` does not
# protect: the variable wins). GIT_CEILING_DIRECTORIES and GIT_DISCOVERY_ACROSS_FILESYSTEM stay out: they
# only limit the search above the cwd. adopt.py keeps a mirror of this list, locked to it by a test.
HK_GIT_REPO_VARS="GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_NAMESPACE"

# hk_git_env_clean — removes HK_GIT_REPO_VARS from the environment of the calling shell (and so of every
# git and every child it runs after the call). `unset -v`, a builtin: no process, which is what lets the two
# guards call it under their time ceilings; `-v` so that a function with one of these names is never removed
# instead. Prints nothing, returns 0. The library only defines it — the LOADER calls it, right after its
# `declare -F` check, which lists it (a half-upgrade, new hook with an old library, fails "incompleta"). Every
# loader that checks this file with `declare -F` calls it — the hooks next to it and the two launcher scripts —
# also those that read no git today, so a new git call there never brings the defect back. Not called by:
# check-commit-msg.sh (git itself runs that hook and, in a linked worktree, hands it
# GIT_DIR=<main>/.git/worktrees/<name> — cleaning there is not neutral), sot-history-lint.sh and
# preflight-launcher.sh (they read no git and call nothing here, so they have no `declare -F` check).
# shellcheck disable=SC2086 # the list is split into names on purpose
hk_git_env_clean() { unset -v $HK_GIT_REPO_VARS; return 0; }

# hk_lib_loaded — R2: the sentinel of a complete load; returns 0 and does nothing else. KEEP IT THE LAST
# DEFINITION OF THIS FILE: a loader that finds it (`declare -F hk_lib_loaded`) knows every definition
# above was read. The guard checks it right after the load — a library that loads but defines nothing
# must never let it decide.
hk_lib_loaded() { return 0; }
