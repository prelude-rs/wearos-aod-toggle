#!/usr/bin/env bash
# check-report.sh — the MECHANICAL aferição of consistency-report.md in its NEW FORM (change
# 2026-09-report-do-gate-so-achados, R3/R4/R5): only the current round, a `## Rodadas` table, one
# heading per check whose body is `sem achados`, `n.a. — <motivo>` or a table of findings.
#
# WHY IT LIVES IN .claude/hooks/ AND NOT IN tests/: `tests/check-spec-layout.sh` is never-copy, so an
# aferição there never reaches an adopting repo. This file is `class: portable` in
# .claude/adopt/manifest.yaml, same precedent as check-tasks.sh and verify-archived-gates.sh. In the
# kit, the layout check's `[dir…]` mode calls it; in the adopter, the design transcription runs it.
#
# READ BY FORM (R3). A report is the NEW form only when its comment-stripped body has a line that IS
# exactly `## Rodadas` — whole-line equality, never a prefix: the bko archive carries
# `## Rodadas anteriores (histórico resumido)` in an old-form report, and that must stay old form.
# An OLD-form report gets NO new aferição and is SAID to be old form (N5) — never a failure.
#
# THE FOUR AFERIÇÕES of the new form, each with its N6 anchor (`# E-form`, `# E-verdict`, `# E-class`,
# `# E-size` at the end of the one line that switches it on — line marks that name the rule; the control,
# each anchor deleted in a copy, was made once and is recorded in the evidence.md of the change that
# created them, and no suite repeats it), plus `# E-fence`: the one line
# that blanks fenced blocks (``` or ~~~, indented too — `blank_fences`, byte for byte check-tasks.sh's)
# out of the body BEFORE form detection and the size justification are read:
#   - form detection (E-form) — `## Rodadas` only inside a fence is old form;
#   - verdict × findings (E-verdict): the verdict is DERIVED — PASS iff no BLOCKING finding. A finding
#     is a table row under a `## Check …` heading whose SECOND cell is exactly BLOCKING or WARNING (the
#     `## Rodadas` table never counts: its cells are numbers). A value other than PASS/FAIL fails.
#   - class by exact value (E-class): under a `## Check …` heading, every table row that is neither a
#     header (a row IMMEDIATELY followed by a separator) nor a separator, outside fences, must carry
#     exactly BLOCKING or WARNING in its second cell — `**BLOCKING**`, `blocking`, `BLOCKER` fail by
#     name instead of passing as "not a finding".
#   - size alarm (E-size): above 100 lines OUTSIDE HTML comments (the template's instruction comment
#     does not count against the author) the `**Justificativa de tamanho:**` line must carry text; a
#     label only inside a fence reads `ausente`.
#
# THE ROUNDS AND THE STOP (change 2026-10-gate-com-criterio-de-parada, R1/R2; the form is design.md,
# "Data modeling", owned by the consistency-gate skill, section "Output"). Run after the four above, on
# a new-form report only, over the `## Rodadas` section (to the next level-2 heading), comments and
# fences already out:
#   - SCOPE BY THE HEADER. The rules switch on when the first table of the section has a 6th header
#     cell exactly `Base`. A table without it FAILS (R2 — cabeçalho), which closes the escape of keeping
#     the old header — EXCEPT in a report archived before this change: a folder whose path has the
#     segment `specs/archive/` and whose name begins with a date AAAA-MM-DD up to REPORT_CUTOFF
#     (2026-10-14). Such a report is read exactly as before (N2), with no new line. Archived after the
#     cutoff, or with no date in the name, it is held like proposed/ and active/.
#   - ROUND LINES (R1/R2 — linha de rodada). The table is the header, the separator and the consecutive
#     table lines after it; the first other line ends it. Data row k must carry `#` exactly k and the
#     verdict exactly PASS or FAIL; a table with no data row fails; a table line that comes back in the
#     section after the end of the table fails as `fora da tabela` — no round escapes the reading.
#   - DECISION LINES (R1 — linha de decisão). Every section line that begins with
#     `- Parada após a rodada ` must match `- Parada após a rodada <N>: <quem>, <AAAA-MM-DD> — <opção> —
#     teto +<K>` (N, K positive integers; quem, opção not empty), or it fails by line.
#   - BASE RULE (R2 — base): from round 2 on, the Base cell is a commit, 7 to 40 lowercase hex (the
#     form, never whether it resolves: a shallow clone or a report outside git must still be readable).
#   - STOP RULE (R1 — parada): let f3 be the round of the 3rd FAIL (FAIL counted in total, not in a
#     row). Each round r > f3 is governed by the LAST decision before it — the greatest N with
#     f3 <= N < r — and passes only if that decision exists and r <= N + K. A new decision replaces the
#     ceiling of the previous one, never adds to it; a decision with N < f3 authorizes nothing.
# Each rule lives in its own function (check_round_header, check_round_lines, check_decision_lines,
# check_base, check_stop), switched on by one line of check_dir.
# The five anchors of these rules (`# E-header`, `# E-row`, `# E-decision`, `# E-base`, `# E-stop`) mark
# the rule lines like the four above, but they are NOT neutralized by the suite: their non-vacuity proof
# (each anchor deleted in a copy, the case it should catch passing again) was made once and is recorded
# in the change's evidence.md, not in tests/test-check-report.sh.
#
# READ-ONLY (N4): this script never writes anything; it reads one file per folder.
#
# Usage: check-report.sh [dir...]   (default: every folder in specs/proposed/ and specs/active/)
# Exit 0 = every folder passes (old form and SKIP included). Exit 1 = at least one fails.
#
# Portability: bash + mawk-safe awk (no gensub, no {n,m}, no \b), LC_ALL=C.
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
{ declare -F verdict_of strip_html_comments hk_git_env_clean >/dev/null && [ -n "${HK_AWK_SHC-}" ]; } || { echo "sdd-kit: biblioteca dos hooks incompleta: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não roda sem ela (instalação incompleta?)" >&2; exit 1; }
hk_git_env_clean   # reads no git today; a new git call here stays on the cwd's repository: see hooks-lib.sh → hk_git_env_clean
set -uo pipefail
export LC_ALL=C

fail=0
avisos=0

say()  { echo "  $1"; }
bad()  { echo "FAIL - $1" >&2; fail=1; }
print_aviso_line() { echo "$1"; }

# verdict_of <file> — the verdict reader (R6) is defined once, in hooks-lib.sh, loaded above.

# strip_html_comments <file> and the awk text HK_AWK_SHC (hk_shc(line), state hk_inc) — the HTML-comment
# machine is defined once, in hooks-lib.sh (R1 of 2026-10-hooks-sem-restos), loaded above; size_of below puts
# the text in front of its own program.

# size_of <file> — lines OUTSIDE HTML comments. A line counts unless every character of it lies inside
# a comment: a line that is only `<!-- … -->`, or that sits wholly inside a multi-line comment, does not
# count; a blank line outside a comment does; a line with text before/after a comment does.
size_of() {
  awk "$HK_AWK_SHC"'{
      startc=hk_inc
      out=hk_shc($0)
      if (out != "" || ($0 == "" && !startc)) n++
    }
    END { print n+0 }' "$1"
}

# blank_fences <body> — the body with every fenced block (``` or ~~~, the fence line itself included)
# blanked to an empty line; one output line per input line. Same state machine as check-tasks.sh: a
# table inside a fence is an example of the form, never a finding.
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

# TABLE_AWK — the table grammar of this check, spelled once for rows_of and rounds_of (local: no other hook
# repeats it). A table row is a line whose first non-blank character is `|`; a separator row is only `|`, `-`,
# `:` and blanks with at least one `-`. tcell(l, k, ws, restore) is cell k (1-based) of line l: `\|` kept as
# \001 while splitting, the cell trimmed, every `ws` turned into a space, and \001 turned back into `|` only
# when `restore` is 1 — what differs between the two readers is passed, not copied.
# shellcheck disable=SC2016
TABLE_AWK='
function is_row(l) { return l ~ /^[[:space:]]*\|/ }
function is_sep(l) { return l ~ /^[[:space:]]*\|[-:|[:space:]]*$/ && l ~ /-/ }
function tcell(l, k, ws, restore,    row, n, c, v) {
  row = l; gsub(/\\\|/, "\001", row)
  n = split(row, c, "|")
  v = (n >= k + 1 ? c[k + 1] : "")
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(ws, " ", v)
  if (restore) gsub(/\001/, "|", v)
  return v
}
'

# rows_of <comment-stripped body> — `<line>\t<id>\t<class>` for every READ table row under a `## Check …`
# heading, fences blanked first. A table row is a line whose first non-blank character is `|` (an
# indented row is a table row too); any other level-2 heading closes the section (`###` does not).
# NOT read: separator rows (only `|`, `-`, `:` and blanks, at least one `-`) and a HEADER — a table row
# IMMEDIATELY followed by a separator row. Every other row is read: a blank line inside a table, or a
# table with no header, never hides a row. id = first cell, class = second cell, both trimmed; escaped
# pipes (`\|`) do not split cells. Line numbers are the file's (both filters keep one line per line).
rows_of() {
  blank_fences "$1" | awk "$TABLE_AWK"'
    { L[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        l = L[i]
        if (l ~ /^##[[:space:]]/) { on = (l ~ /^##[[:space:]]+Check([[:space:]]|$)/); continue }
        if (!on || !is_row(l) || is_sep(l)) continue
        if (i < NR && is_sep(L[i + 1])) continue
        print i "\t" tcell(l, 1, "\t", 0) "\t" tcell(l, 2, "\t", 0)
      }
    }
  '
}

# blocking_of <comment-stripped body> — the ids of the BLOCKING findings, one per line: read rows whose
# class is EXACTLY `BLOCKING` — a mention in prose or in another column is not a finding.
blocking_of() {
  rows_of "$1" | awk -F '\t' '$3 == "BLOCKING" { print $2 }'
}

# badclass_of <comment-stripped body> — `<line>\t<class>` for every read row whose class is not exactly
# BLOCKING or WARNING.
badclass_of() {
  rows_of "$1" | awk -F '\t' '$3 != "BLOCKING" && $3 != "WARNING" { print $1 "\t" $3 }'
}

# justif_of <comment-stripped body> -> ausente | vazia | presente. First line that BEGINS with the
# label wins; value = rest of the line, trimmed. `vazia` = empty or ENTIRELY a placeholder (`<…>`,
# `[SPECIFY]`, `TODO`, `N/A`, the last three case-blind) — the same classification as check-tasks.sh.
justif_of() {
  printf '%s\n' "$1" | awk '
    index($0, "**Justificativa de tamanho:**") == 1 {
      v = substr($0, length("**Justificativa de tamanho:**") + 1)
      sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v)
      lv = tolower(v)
      if (v == "" || v ~ /^<[^>]*>$/ || lv == "[specify]" || lv == "todo" || lv == "n/a") st = "vazia"
      else st = "presente"
      exit
    }
    END { print (st == "" ? "ausente" : st) }
  '
}

# check_verdict <name> <report> <body> — R4 + the invalid-value FAIL (N5: nothing passes in silence).
check_verdict() {
  local name="$1" rep="$2" body="$3" v ids n
  v="$(verdict_of "$rep")"
  ids="$(blocking_of "$body")"
  n="$(printf '%s\n' "$ids" | grep -c . || true)"
  case "$v" in
    PASS)
      [ "$n" -gt 0 ] && bad "$name: Verdict: PASS com $n achado(s) BLOCKING ($(printf '%s\n' "$ids" | grep . | paste -sd, - | sed 's/,/, /g')) — o veredito é derivado: PASS só sem BLOCKING"
      ;;
    FAIL)
      [ "$n" -eq 0 ] && bad "$name: Verdict: FAIL sem nenhum achado BLOCKING — o veredito é derivado: FAIL só com BLOCKING"
      ;;
    *)
      bad "$name: Verdict: '$v' não é PASS nem FAIL"
      ;;
  esac
  return 0
}

# check_class <name> <body> — the class is read by exact value: a row that looks like a finding but
# whose class is anything else fails by name (never "not a finding" in silence).
check_class() {
  local name="$1" body="$2" ln val
  while IFS="$(printf '\t')" read -r ln val; do
    [ -n "$ln" ] || continue
    bad "$name: achado com classe '$val' fora de BLOCKING/WARNING (linha $ln) — a classe é lida por valor exato"
  done <<EOF_CLASS
$(badclass_of "$body")
EOF_CLASS
  return 0
}

# check_size <name> <report> <body> — R5: above 100 lines the justification must carry text.
check_size() {
  local name="$1" rep="$2" body="$3" lines
  lines="$(size_of "$rep")"
  [ "$lines" -gt 100 ] || return 0
  case "$(justif_of "$body")" in
    presente)
      avisos=$((avisos + 1))
      print_aviso_line "AVISO $name [tamanho] $lines linhas — justificado"
      ;;
    vazia)
      bad "$name: report com $lines linhas (alarme acima de 100) sem justificativa de tamanho — vazia (placeholder ou sem texto); escreva '**Justificativa de tamanho:** <motivo>'"
      ;;
    *)
      bad "$name: report com $lines linhas (alarme acima de 100) sem justificativa de tamanho — ausente; escreva '**Justificativa de tamanho:** <motivo>'"
      ;;
  esac
  return 0
}

# The cutoff of the archive dispensation (design.md of 2026-10-gate-com-criterio-de-parada,
# "Interfaces"): a report archived on or before this date may keep the `## Rodadas` table without `Base`.
REPORT_CUTOFF=2026-10-14
ROUND_HEADER_HINT="use o cabeçalho do template: '| # | Verdict | BLOCKING | WARNING | Reaberturas | Base |' (specs/templates/consistency-report.md)"
DECISION_FORM="- Parada após a rodada <N>: <quem>, <AAAA-MM-DD> — <opção> — teto +<K>"

# rounds_of <comment-stripped, fence-blanked body> — the `## Rodadas` section, read line by line (the
# file's line numbers), as tagged records separated by US (\037, never a tab: `read` collapses runs of
# a whitespace IFS, and an empty cell would shift every field after it):
#   H <line> <1|0>                  the table header, and whether its 6th cell is exactly `Base`
#                                   (`H 0 0` when the section has no table at all)
#   R <line> <k> <#> <verdict> <base>   the k-th data row of the table (cells trimmed)
#   O <line>                        a table line in the section AFTER the end of the table
#   D <line> <1|0> <N> <K>          a line that begins with `- Parada após a rodada `, and whether it
#                                   matches the whole form (N and K only when it does)
# Nothing is printed for a report with no whole-line `## Rodadas` (the caller never asks).
US="$(printf '\037')"
rounds_of() {
  awk -v us="$US" "$TABLE_AWK"'
    function cell(l, k) { return tcell(l, k, us, 1) }
    function decision(l,    p, rest, i, n, r2, who, r3, opt, kk) {
      p = "- Parada após a rodada "
      if (index(l, p) != 1) return
      rest = substr(l, length(p) + 1); sub(/[[:space:]]+$/, "", rest)
      if (rest ~ /^[1-9][0-9]*: /) {
        i = index(rest, ": "); n = substr(rest, 1, i - 1); r2 = substr(rest, i + 2)
        if (match(r2, /, [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] — /)) {
          who = substr(r2, 1, RSTART - 1); r3 = substr(r2, RSTART + RLENGTH)
          if (match(r3, / — teto [+][1-9][0-9]*$/)) {
            opt = substr(r3, 1, RSTART - 1); kk = substr(r3, RSTART); sub(/^.*[+]/, "", kk)
            if (who ~ /[^[:space:]]/ && opt ~ /[^[:space:]]/) { print "D" us NR us "1" us n us kk; return }
          }
        }
      }
      print "D" us NR us "0" us us
    }
    # st: 0 before the section, 1 in it before the table, 2 in the table, 3 after the table, 4 past it.
    st == 0 { if ($0 == "## Rodadas") st = 1; next }
    st == 4 { next }
    /^##[[:space:]]/ { st = 4; next }
    st == 1 && is_row($0) {
      hb = (cell($0, 6) == "Base") ? 1 : 0
      print "H" us NR us hb; seen = 1; st = 2; next
    }
    st == 2 && is_row($0) {
      if (is_sep($0)) next
      k++
      c1 = cell($0, 1); c2 = cell($0, 2); c6 = cell($0, 6)
      print "R" us NR us k us c1 us c2 us c6
      next
    }
    st == 2 { st = 3 }
    st == 3 && is_row($0) { print "O" us NR; next }
    { decision($0) }
    END { if (st != 0 && !seen) print "H" us "0" us "0" }
  ' <<< "$1"
}

# archived_before_cutoff <dir> — 0 when <dir> is a report folder archived on or before REPORT_CUTOFF:
# its PHYSICAL path (resolved with `pwd -P`, so `..` and symlinks cannot point the dispensation at a
# folder outside the archive) has the segment `specs/archive/` and its name begins with a date
# AAAA-MM-DD that is not after the cutoff. ISO dates compare as strings (LC_ALL=C). A folder that does
# not resolve gets no dispensation (fails closed).
archived_before_cutoff() {
  local d="$1" p date
  p="$(cd "$d" 2>/dev/null && pwd -P)" || return 1
  [ -n "$p" ] || return 1
  case "$p/" in */specs/archive/*) ;; *) return 1 ;; esac
  date="${p##*/}"; date="${date:0:10}"
  case "$date" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) return 1 ;; esac
  [[ "$date" > "$REPORT_CUTOFF" ]] && return 1
  return 0
}

# check_round_header <dir> <name> <rounds> — R2 — cabeçalho: a `## Rodadas` section with no table, or whose
# table lacks the `Base` column, fails, outside the archive dispensation (archived up to the cutoff: read as
# before, silently — N2, the same output as before this change).
check_round_header() {
  local d="$1" name="$2" rounds="$3" what
  archived_before_cutoff "$d" && return 0
  if [ "$(awk -F "$US" '$1 == "H" { print $2; exit }' <<< "$rounds")" = 0 ]; then
    what="seção ## Rodadas sem tabela"
  else
    what="tabela ## Rodadas sem a coluna Base"
  fi
  bad "$name: $what (R2 — cabeçalho) — $ROUND_HEADER_HINT"
  return 0
}

# check_round_lines <name> <rounds> — R1/R2 — linha de rodada: at least one data row; row k carries `#`
# exactly k and the verdict exactly PASS or FAIL; no table line after the end of the table.
check_round_lines() {
  local name="$1" rounds="$2" tag ln k num v base hl nrows
  hl="$(awk -F "$US" '$1 == "H" { print $2; exit }' <<< "$rounds")"
  nrows="$(awk -F "$US" '$1 == "R" { n++ } END { print n + 0 }' <<< "$rounds")"
  [ "$nrows" -gt 0 ] \
    || bad "$name: tabela ## Rodadas sem nenhuma linha de rodada (linha $hl) (R1/R2 — linha de rodada) — a tabela tem uma linha por rodada do gate"
  while IFS="$US" read -r tag ln k num v base; do
    case "$tag" in
      R)
        [ "$num" = "$k" ] || bad "$name: linha de rodada malformada (linha $ln): o # é '$num', esperado $k (R1/R2 — linha de rodada)"
        case "$v" in
          PASS|FAIL) ;;
          *) bad "$name: linha de rodada malformada (linha $ln): o veredito é '$v', não PASS nem FAIL (R1/R2 — linha de rodada)" ;;
        esac
        ;;
      O)
        bad "$name: linha de rodada fora da tabela (linha $ln) (R1/R2 — linha de rodada fora da tabela) — escreva a rodada na tabela, logo abaixo da última linha"
        ;;
    esac
  done <<< "$rounds"
  return 0
}

# check_decision_lines <name> <rounds> — R1 — linha de decisão: a line with the prefix and out of the
# form fails by line (never passes by omission).
check_decision_lines() {
  local name="$1" rounds="$2" tag ln okf rest
  while IFS="$US" read -r tag ln okf rest; do
    [ "$tag" = D ] && [ "$okf" != 1 ] \
      && bad "$name: linha de decisão fora da forma (linha $ln) (R1 — linha de decisão) — a forma é '$DECISION_FORM'"
  done <<< "$rounds"
  return 0
}

# check_base <name> <rounds> — R2 — base: from round 2 on, the Base cell is 7 to 40 lowercase hex.
check_base() {
  local name="$1" rounds="$2" k base list
  list="$(awk -F "$US" -v us="$US" '$1 == "R" && $3 + 0 >= 2 {
      b = $6; l = length(b)
      if (b ~ /^[0-9a-f]+$/ && l >= 7 && l <= 40) next
      print $3 us b
    }' <<< "$rounds")"
  while IFS="$US" read -r k base; do
    [ -n "$k" ] || continue
    bad "$name: rodada $k sem base (commit julgado pela rodada anterior) na coluna Base (R2 — base) — valor '$base'; a base é um commit, 7 a 40 caracteres hexadecimais"
  done <<< "$list"
  return 0
}

# check_stop <name> <rounds> — R1 — parada: every round after the round of the 3rd FAIL needs the
# governing decision (the last one before it, N >= f3) with r <= N + K.
check_stop() {
  local name="$1" rounds="$2" r list
  list="$(awk -F "$US" '
      $1 == "R" { n = $3 + 0; if ($5 == "FAIL") { fails++; if (fails == 3) f3 = n } }
      $1 == "D" && $3 == "1" { nd++; dn[nd] = $4 + 0; dk[nd] = $5 + 0 }
      END {
        if (!f3) exit
        for (r = f3 + 1; r <= n; r++) {
          g = 0
          for (i = 1; i <= nd; i++) if (dn[i] >= f3 && dn[i] < r && (g == 0 || dn[i] >= dn[g])) g = i
          if (g == 0 || r > dn[g] + dk[g]) print r
        }
      }' <<< "$rounds")"
  while read -r r; do
    [ -n "$r" ] || continue
    bad "$name: rodada $r depois da 3ª rodada FAIL sem decisão de parada que a autorize (R1 — parada) — leve ao humano e registre a decisão dele sob a tabela: '$DECISION_FORM'"
  done <<< "$list"
  return 0
}

check_dir() {
  local d="${1%/}" rep body name newform=0 rounds
  rep="$d/consistency-report.md"
  name="$(basename -- "$d")"
  # No report (via rápida has none, by design): SKIP WITH A STATED REASON, never silence.
  if [ ! -f "$rep" ]; then echo "SKIP - $name: sem consistency-report.md"; return 0; fi
  body="$(strip_html_comments "$rep")"
  # Fences blanked ONCE, before every reader: `## Rodadas` or `**Justificativa de tamanho:**` quoted in
  # a fence is an example of the form, never the form — same reading as rows_of and check-tasks.sh.
  body="$(blank_fences "$body")"                                                      # E-fence
  grep -qx '## Rodadas' <<< "$body" && newform=1                                      # E-form
  if [ "$newform" -eq 0 ]; then
    say "$name: report na forma antiga — aferições da forma nova não se aplicam"
    return 0
  fi
  check_verdict "$name" "$rep" "$body"                                                # E-verdict
  check_class "$name" "$body"                                                         # E-class
  check_size "$name" "$rep" "$body"                                                   # E-size
  # The rounds (2026-10-gate-com-criterio-de-parada): the four rules switch on with the `Base` column;
  # without it, only the header rule (and the archive dispensation inside it) speaks.
  rounds="$(rounds_of "$body")"
  if [ "$(awk -F "$US" '$1 == "H" { print $3; exit }' <<< "$rounds")" != 1 ]; then
    check_round_header "$d" "$name" "$rounds"                                         # E-header
    return 0
  fi
  check_round_lines "$name" "$rounds"                                                 # E-row
  check_decision_lines "$name" "$rounds"                                              # E-decision
  check_base "$name" "$rounds"                                                        # E-base
  check_stop "$name" "$rounds"                                                        # E-stop
  return 0
}

# The default covers BOTH folders (2026-09-change-parada-em-active, R4): a change still under
# discussion lives in specs/proposed/ until Gate 1.5, and an incoherent report there fails as it
# would in specs/active/ — this check does not tell the folders apart, it reads what it finds.
dirs=("$@")
if [ "${#dirs[@]}" -eq 0 ]; then
  for c in specs/proposed/*/ specs/active/*/; do [ -d "$c" ] && dirs+=("$c"); done
fi
if [ "${#dirs[@]}" -eq 0 ]; then
  echo "AVISOS: $avisos"
  echo "SKIP - nenhuma mudança em specs/proposed/ nem specs/active/ — nada a aferir."
  exit 0
fi

for c in "${dirs[@]}"; do check_dir "$c"; done

echo "AVISOS: $avisos"
if [ "$fail" -eq 0 ]; then
  echo "PASS - ${#dirs[@]} pasta(s) aferida(s): report(s) coerente(s) com a forma que declaram."
  exit 0
fi
echo "FAIL - pelo menos um report reprovou; a saída acima nomeia o motivo." >&2
exit 1
