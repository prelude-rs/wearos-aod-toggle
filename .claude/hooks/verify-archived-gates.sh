#!/usr/bin/env bash
# verify-archived-gates.sh — CI check (run on PRs to dev/main, and as a deploy gate).
# For every change folder under specs/archive/ TOUCHED in this PR, require that the gates ran and
# passed: consistency-report.md (first `^Verdict:` line = PASS) AND evidence.md (first = COMPLETE).
# This makes "the adversarial gates produced a passing verdict" a LAW, not a skill — enforced
# independently of any flow engine. It verifies the artifact FACT (a passing report exists), NOT that
# the review was adversarial/fresh/correct (that residual is the engine's + fresh-subagent's job).
#
# Usage: verify-archived-gates.sh [BASE_REF]   (BASE_REF default: origin/main, or $BASE_REF)
# Exit 0 = all touched archived changes carry passing gate artifacts. Non-zero = at least one doesn't.
# Common hook library, loaded FIRST (before `set`, before any argument): without it this check exits 1
# naming it (R2 of 2026-10-biblioteca-comum-dos-hooks). `[ -r ]` + `command .`: a plain failed `.` is
# fatal under POSIXLY_CORRECT and would exit before the message. Found next to THIS file (BASH_SOURCE).
case "${BASH_SOURCE[0]}" in */*) HK_DIR="${BASH_SOURCE[0]%/*}" ;; *) HK_DIR=. ;; esac
# The EXIT trap around the load (fd 9, `|| exit`, HK_LIB_GONE, `trap - EXIT`; exit 1): see hooks-lib.sh → "Who loads it".
HK_LIB_GONE="sdd-kit: biblioteca dos hooks ausente ou ilegível: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não roda sem ela (instalação incompleta?)"
trap 'echo "$HK_LIB_GONE" >&9; exit 1' EXIT
{ [ -r "$HK_DIR/hooks-lib.sh" ] && command . "$HK_DIR/hooks-lib.sh" || exit; } 9>&2 2>/dev/null
trap - EXIT
{ declare -F hk_gate_base hk_delegate verdict_of mode_of sot_decl_of sot_sections hk_sot_heading_lines hk_git_env_clean >/dev/null && [ -n "${HK_AWK_SHC-}" ]; } || { echo "sdd-kit: biblioteca dos hooks incompleta: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não roda sem ela (instalação incompleta?)" >&2; exit 1; }
hk_git_env_clean   # the repository read is the cwd's, also by the delegated checks: see hooks-lib.sh → hk_git_env_clean
set -uo pipefail

hk_gate_base "$@"   # BASE and HK_BASE_EXPLICIT — the base's precedence is defined once, in hooks-lib.sh

# verdict_of <file> — the verdict reader (R6) is defined once, in hooks-lib.sh, loaded above.
# mode_of <file> — the `Mode:` reader is defined once, in hooks-lib.sh (R1 of 2026-10-hooks-sem-restos), and
# shared by the verdict loop and the SoT block; the gate hides grep's line at both calls (`2>/dev/null`), as it
# always did.

# sot_decl_of <file>, sot_sections <git-ref> and hk_sot_heading_lines — the SoT readers and the heading
# lookup are defined once, in hooks-lib.sh, loaded above (R4 of 2026-10-check-tasks-defeitos:
# check-tasks.sh reads the declaration with them too).

# sot_touched <BASE> <HEAD> — maps the HEAD-side lines touched by the diff of
# specs/SOURCE-OF-TRUTH.md between BASE and HEAD to their enclosing sections (via `sot_sections
# HEAD`), and prints the unique section TEXTs (`sort -u`). Never maps by the BASE side — a spec
# should never be asked to name a section that no longer exists in HEAD.
# Hunk header parsing (`@@ -a,b +c,d @@`): only the `+c,d` (HEAD) side matters. `d` defaults to 1
# when git omits it (a single HEAD line prints `+c` alone, no comma). `d=0` is a pure deletion: it
# ALWAYS counts, at the single line `c` — "the line before which the excerpt stood" (measured: a
# deletion at the end of a section emits `+a,0` with `a` = that section's own last HEAD line; a
# whole-section removal emits `+a,0` with `a` = the last line of the section BEFORE it, so the
# removal is charged to the preceding section — this is deliberate, not a bug, per the design's
# edge-case table) — a deletion has no HEAD content to inspect, so blankness never applies to it.
# `c=0` (deletion positioned before the file's first line) maps to line 1 — by the preamble rule,
# always the first section; the mapping to 1 happens BEFORE the `d=0` check, so a hunk that is both
# `c=0` and `d=0` still touches line 1, not line 0.
# `d ≥ 1` (an added/changed HEAD line) is only a CANDIDATE touch: per the design's amended "Seção
# tocada" rule, a HEAD line whose content is empty or whitespace-only never counts as a touch (e.g.
# a blank line a hunk inserts to keep a section separator) — measured case: appending a new section
# after a heading with no trailing blank line makes git insert one new blank HEAD line that would
# otherwise be misread as touching the PRECEDING section. HEAD's content is read once via `git show`
# and checked against the candidate line numbers in a single awk pass.
# With `NOSECTIONS`, every (post-filter) touched line prints `OUTSIDE\t<n>` instead (the only way
# OUTSIDE happens). With `SOT-DELETED` (the path existed in BASE but not in HEAD), that token is
# printed alone and nothing else is computed. If the SoT never appears in the diff (path untouched),
# prints nothing and returns 0.
sot_touched() {
  local base="$1" head="$2"
  local diff_out
  diff_out="$(git diff -U0 "${base}...${head}" -- specs/SOURCE-OF-TRUTH.md 2>/dev/null)"
  [ -n "$diff_out" ] || return 0

  local sec_out
  sec_out="$(sot_sections "$head")"
  if [ "$sec_out" = "SOT-DELETED" ]; then
    echo SOT-DELETED
    return 0
  fi

  local -a always_lines=() candidate_lines=()
  local hunk spec c d i
  while IFS= read -r hunk; do
    case "$hunk" in
      '@@ '*)
        spec="${hunk#@@ }"; spec="${spec%% @@*}"   # "-a,b +c,d"
        spec="${spec#*+}"                          # "c,d" or "c"
        case "$spec" in
          *,*) c="${spec%%,*}"; d="${spec#*,}" ;;
          *)   c="$spec"; d=1 ;;
        esac
        [ "$c" = 0 ] && c=1
        if [ "$d" = 0 ]; then
          always_lines+=("$c")
        else
          i=0
          while [ "$i" -lt "$d" ]; do
            candidate_lines+=("$((c + i))")
            i=$((i + 1))
          done
        fi
        ;;
    esac
  done <<< "$diff_out"

  if [ "${#always_lines[@]}" -eq 0 ] && [ "${#candidate_lines[@]}" -eq 0 ]; then return 0; fi

  # Filter candidate_lines (d ≥ 1 hunks): keep only the ones whose HEAD content is non-blank. A
  # single awk pass over HEAD's content does the check; deletions never go through this filter.
  local -a kept_candidates=()
  if [ "${#candidate_lines[@]}" -gt 0 ]; then
    local nums kept
    nums="$(printf '%s\n' "${candidate_lines[@]}")"
    kept="$(git show "${head}:specs/SOURCE-OF-TRUTH.md" 2>/dev/null | awk -v nums="$nums" '
      BEGIN {
        m = split(nums, want_list, "\n")
        for (i = 1; i <= m; i++) { if (want_list[i] != "") want[want_list[i]] = 1 }
      }
      {
        lineno++
        if (lineno in want) {
          line = $0
          gsub(/^[ \t]+|[ \t]+$/, "", line)
          if (line != "") print lineno
        }
      }
    ')"
    while IFS= read -r n; do
      [ -n "$n" ] && kept_candidates+=("$n")
    done <<< "$kept"
  fi

  local -a lines=("${always_lines[@]}" "${kept_candidates[@]}")
  [ "${#lines[@]}" -gt 0 ] || return 0

  local n
  if [ "$sec_out" = "NOSECTIONS" ]; then
    for n in "${lines[@]}"; do printf 'OUTSIDE\t%s\n' "$n"; done | LC_ALL=C sort -u
    return 0
  fi

  local -a results=()
  local start end level text found
  for n in "${lines[@]}"; do
    found=""
    while IFS=$'\t' read -r start end level text; do
      if [ "$n" -ge "$start" ] && [ "$n" -le "$end" ]; then
        found="$text"
        break
      fi
    done <<< "$sec_out"
    [ -n "$found" ] && results+=("$found")
  done

  [ "${#results[@]}" -eq 0 ] && return 0
  printf '%s\n' "${results[@]}" | LC_ALL=C sort -u
}

# Testability seam: SDD_GATE_SOURCE_ONLY=1 lets tests `source` this file to call its functions
# (verdict_of, sot_decl_of, sot_sections, sot_touched) without running the gate's main body below.
# Normal invocation (`bash verify-archived-gates.sh …`) never sets this var, so behavior there is
# unchanged.
if [ "${SDD_GATE_SOURCE_ONLY:-0}" != "1" ]; then

# Path-scoped diff (NOT --diff-filter=A): archiving is `git mv active→archive`, which git records as a
# RENAME — a status filter would miss it. Path-scoping to specs/archive/ over the PR-scoped BASE...HEAD
# range catches any archive folder touched in this change, while pre-kit historical folders (unchanged
# in the PR) stay untouched.
# shellcheck disable=SC2153 # BASE is written by hk_gate_base (hooks-lib.sh), not misspelled
dirs="$(git diff --name-only "${BASE}...HEAD" -- specs/archive/ 2>/dev/null \
        | grep -oE 'specs/archive/[^/]+/' | sort -u || true)"

fail=0
for d in $dirs; do
  cm="${d}change.md"

  # ── ramo VIA RÁPIDA (Mode: fast) — aditivo ──
  # A pasta arquivada carrega um change.md com 1º campo `^Mode:` = fast: dispensa
  # consistency-report.md/evidence.md e exige, no próprio change.md, 1º `^Verdict:` = COMPLETE E
  # `^Justification:` não-vazia. Sem `Mode: fast` (ou sem change.md) → cai no laço formal, inalterado.
  mode=""
  if [ -f "$cm" ]; then
    mode="$(mode_of "$cm" 2>/dev/null)"
  fi

  if [ "$mode" = "fast" ]; then
    just="$(grep -m1 -iE '^Justification:' "$cm" 2>/dev/null | sed -E 's/^[^:]*:[[:space:]]*//' || true)"
    if [ "$(verdict_of "$cm")" != "COMPLETE" ] || [ -z "$just" ]; then
      echo "FAIL ${d}: change.md (Mode: fast) exige 1º Verdict: COMPLETE e Justification: não-vazia" >&2
      fail=1
    fi
    continue
  fi

  cr="${d}consistency-report.md"; ev="${d}evidence.md"
  # First `^Verdict:` line only (the header field) → immune to the token being quoted in body examples.
  if ! { [ -f "$cr" ] && [ "$(verdict_of "$cr")" = "PASS" ]; }; then
    echo "FAIL ${d}: consistency-report.md ausente ou seu primeiro Verdict não é PASS" >&2; fail=1
  fi
  # -w: COMPLETE as an exact token — must NOT match INCOMPLETE (which contains "COMPLETE").
  if ! { [ -f "$ev" ] && [ "$(verdict_of "$ev")" = "COMPLETE" ]; }; then
    echo "FAIL ${d}: evidence.md ausente ou seu primeiro Verdict não é COMPLETE" >&2; fail=1
  fi
done

# ── SoT block: aferição bidirecional das seções declaradas × tocadas ───────────────────────────
# For every judged folder, reads the "## Seções do SoT afetadas" declaration (spec.md, or change.md
# when Mode: fast — same detection as the verdict loop above) and checks it against
# specs/SOURCE-OF-TRUTH.md on BOTH sides: every declared heading must exist (and be unambiguous) in
# HEAD, every declared heading must have been touched by BASE...HEAD's diff, and every touched
# heading must have been declared by SOME judged folder.
#
# `judged_dirs` narrows `dirs` to folders NEW in this PR: a folder whose path already existed at
# BASE (`git ls-tree -d "$BASE" -- "$d"` prints something) is being TOUCHED again (typo fix,
# backlink), not archived by this PR — it was already judged by whatever PR archived it, so it stays
# OUT of the SoT block (R6). It stays IN the verdict loop above unchanged: a pre-existing folder
# whose consistency-report/evidence Verdict is broken must still FAIL (R6 second half).
new_dirs=""
for d in $dirs; do
  # `git ls-tree -d` needs the path WITHOUT a trailing slash — `$d` always carries one (the
  # `specs/archive/[^/]+/` regex above), and with it ls-tree silently prints nothing even when the
  # folder exists at BASE (measured). Strip it only for this check; `$d` itself stays untouched.
  if [ -z "$(git ls-tree -d "$BASE" -- "${d%/}" 2>/dev/null)" ]; then
    new_dirs="${new_dirs}${d}"$'\n'
  fi
done
new_dirs="$(printf '%s' "$new_dirs" | grep -v '^$' || true)"

judged_dirs="$new_dirs"

# Empty `judged_dirs` covers TWO cases, both dispensed the same way (R5): `dirs` itself empty (no
# archive folder touched at all — e.g. a PR that only edits the SoT) and `dirs` non-empty but every
# touched folder pre-existing (only pre-existing folders touched — e.g. a typo fix, no new archive).
# Either way there is no NEW archived change to hold a SoT declaration against, so the whole
# comparison is dispensed — explicitly (N5: nothing silent), never by falling through mutely.
if [ -z "$judged_dirs" ]; then
  echo "SoT: nenhuma change nova arquivada nesta PR — aferição de SoT dispensada"
else
  sot_fail=0   # Flag to prevent success line if any SoT check fails
  declared_union=""   # sort -u'd set of declared heading TEXTs (for the touched∖declared direction)
  declared_pairs=""   # one "<pasta>\t<heading>" line per declared row (for pasta-attributed checks)

  for d in $judged_dirs; do
    cm="${d}change.md"
    mode=""
    if [ -f "$cm" ]; then
      mode="$(mode_of "$cm" 2>/dev/null)"
    fi
    if [ "$mode" = "fast" ]; then
      declf="$cm"
    else
      declf="${d}spec.md"
    fi

    decl_out="$(sot_decl_of "$declf")"
    case "$decl_out" in
      MISSING)
        echo "FAIL SoT ${d}: declaração de seções do SoT ausente (seção \"Seções do SoT afetadas\" vazia ou inexistente)" >&2
        fail=1; sot_fail=1
        ;;
      EMPTY)
        echo "FAIL SoT ${d}: SOT-NO-DELTA sem motivo" >&2
        fail=1; sot_fail=1
        ;;
      CONFLICT)
        echo "FAIL SoT ${d}: declaração contraditória (tabela E SOT-NO-DELTA)" >&2
        fail=1; sot_fail=1
        ;;
      *)
        while IFS=$'\t' read -r tag text; do
          if [ "$tag" = "HEADING" ]; then
            declared_union="${declared_union}${text}"$'\n'
            declared_pairs="${declared_pairs}${d}"$'\t'"${text}"$'\n'
          fi
        done <<< "$decl_out"
        ;;
    esac
  done

  declared_union="$(printf '%s' "$declared_union" | LC_ALL=C sort -u)"

  # Dedupe declared_pairs per folder: sort -u removes duplicate pasta/heading pairs.
  if [ -n "$declared_pairs" ]; then
    declared_pairs="$(printf '%s' "$declared_pairs" | LC_ALL=C sort -u)"
  fi

  # Touched side FIRST: check if SoT was deleted (short-circuit on SOT-DELETED).
  # SOT-DELETED / OUTSIDE come straight out of sot_touched; anything else it prints is
  # a touched section TEXT (already sort -u'd there... but not merged across folders, so re-sort).
  touched_out="$(sot_touched "$BASE" HEAD)"
  touched_union=""
  if [ "$touched_out" = "SOT-DELETED" ]; then
    # Short-circuit: SoT was deleted. Print only the apagado FAIL, skip existence loop.
    echo "FAIL SoT: SOURCE-OF-TRUTH.md apagado nesta PR — apagar o SoT não é toque declarável" >&2
    fail=1; sot_fail=1
  else
    # SoT not deleted; process touched output for OUTSIDE and sections.
    if [ -n "$touched_out" ]; then
      while IFS= read -r line; do
        case "$line" in
          OUTSIDE$'\t'*)
            n="${line#OUTSIDE$'\t'}"
            echo "FAIL SoT: linha ${n} do SoT fora de qualquer seção (arquivo sem heading de nível 1 a 3)" >&2
            fail=1; sot_fail=1
            ;;
          '') ;;
          *)
            touched_union="${touched_union}${line}"$'\n'
            ;;
        esac
      done <<< "$touched_out"
      touched_union="$(printf '%s' "$touched_union" | LC_ALL=C sort -u)"
    fi

    # Existence/ambiguity: resolve every declared (pasta, heading) row against sot_sections HEAD.
    if [ -n "$declared_pairs" ]; then
      sections_head="$(sot_sections HEAD)"
      while IFS=$'\t' read -r pasta h; do
        [ -n "$h" ] || continue
        # The lookup is hk_sot_heading_lines (hooks-lib.sh): HK_SOT_COUNT 0 = inexistente, 2+ = ambíguo.
        hk_sot_heading_lines "$sections_head" "$h"; linelist="$HK_SOT_LINES"
        if [ "$HK_SOT_COUNT" -eq 0 ]; then
          echo "FAIL SoT ${pasta}: heading inexistente — \"$h\"" >&2
          fail=1; sot_fail=1
        else
          if [ "$HK_SOT_COUNT" -ge 2 ]; then
            echo "FAIL SoT ${pasta}: heading ambíguo — \"$h\" (linhas ${linelist})" >&2
            fail=1; sot_fail=1
          fi
        fi
      done <<< "$declared_pairs"
    fi

    # Bidirectional comparison (declaradas ∖ tocadas; tocadas ∖ declaradas).
    # TEST SEAM ONLY: SDD_SOT_SKIP=1 disables just this comparison, so a fixture can prove the check
    # bites (declared-not-touched still fails everywhere else, but not here). Never set in real usage.
    if [ "${SDD_SOT_SKIP:-0}" != "1" ]; then
      if [ -n "$declared_pairs" ]; then
        while IFS=$'\t' read -r pasta h; do
          [ -n "$h" ] || continue
          if ! grep -qxF "$h" <<< "$touched_union"; then
            echo "FAIL SoT ${pasta}: seção declarada e não tocada — \"$h\"" >&2
            fail=1; sot_fail=1
          fi
        done <<< "$declared_pairs"
      fi
      if [ -n "$touched_union" ]; then
        while IFS= read -r h; do
          [ -n "$h" ] || continue
          if ! grep -qxF "$h" <<< "$declared_union"; then
            echo "FAIL SoT: seção tocada e não declarada — \"$h\"" >&2
            fail=1; sot_fail=1
          fi
        done <<< "$touched_union"
      fi
      # Only print success if no SoT check failed in this block.
      if [ "$sot_fail" -eq 0 ]; then
        n="$(printf '%s\n' "$declared_union" | grep -c '.' || true)"
        echo "SoT: declaradas ↔ tocadas conferem (${n} seção/seções)"
      fi
    fi

    # Lint de histórico do SoT: ao fim do bloco de SoT, repassa a saída do lint.
    # Invoca APENAS quando há mudanças NOVAS arquivadas (new_dirs não-vazio), NÃO no caminho dispensa.
    # Se o script de lint estiver ausente, imprime aviso em vez de falhar silenciosamente.
    if [ -f "$HK_DIR/sot-history-lint.sh" ]; then
      bash "$HK_DIR/sot-history-lint.sh" specs/SOURCE-OF-TRUTH.md || true
    else
      echo "SoT: lint de histórico ausente (sot-history-lint.sh) — aviso não emitido"
    fi
  fi
fi

# ── delegation to the three portable checks next to this script (hk_delegate, hooks-lib.sh) ──
# They run on EVERY path, archiving or not: they are checked on every PR, not only on those that archive.
# A missing check next to this script is a broken install (they arrive in the same upgrade), so it fails
# instead of passing by omission (I3). Their output passes straight through (N5).
#   - release changelog (change 2026-09-changelog-de-release, R4) and epic numbering (change
#     2026-09-numeracao-de-epicos, R6), mode `check`: --base only when the base was given EXPLICITLY
#     (positional argument or BASE_REF) — otherwise a local run would fall into the `main` rules through
#     the origin/main default; their failure adds to `fail`.
#   - closing debt (change 2026-09-change-parada-em-active, R6), mode `aviso`: a WARNING, never a
#     failure — no base (ages come from the folders' own history), its code never adds to `fail`.
archive_fail="$fail"   # the final summary blames archived changes only when they are what failed
hk_delegate "changelog de release" check-release-changelog.sh check || fail=1
hk_delegate "numeração de épicos" check-epic-numbering.sh check || fail=1
hk_delegate "dívida de fechamento" check-closing-debt.sh aviso || fail=1

[ "$archive_fail" -eq 0 ] || echo "verify-archived-gates: uma ou mais mudanças arquivadas não têm os artefatos de gate aprovados." >&2
exit "$fail"

fi # SDD_GATE_SOURCE_ONLY
