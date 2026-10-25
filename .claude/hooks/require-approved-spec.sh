#!/usr/bin/env bash
# require-approved-spec.sh — PreToolUse hook for Edit/Write/MultiEdit on source files.
# Blocks code edits unless an active change folder exists with Approved spec+design and a tasks.md.
# NOTE — this line was already exact before 2026-09-tasks-sem-gate-2 and did not change: the hook has
# ALWAYS required tasks.md to be PRESENT, never `Approved` (compare with the two `^Status:.*Approved`
# greps below). The human plan-review gate these messages used to name was doctrine, not mechanism —
# 17 assertions across 11 files guarding a gate no hook ever closed. That is the change's central
# premise, and the proof is that its diff here touches only messages and comments.
# Wire-up: see .claude/hooks/README.md
#
# Input: hook JSON on stdin (Claude Code PreToolUse contract).
# Exit 0 = allow. Exit 2 = block, stderr is shown to the model.
#
# NOTE (2026-09-spec-so-what): `-e` dropped on purpose — a sourced file must never abort the caller
# (see the SDD_GATE_SOURCE_ONLY seam below). The main body below keeps its former behavior anyway:
# every path that used to rely on `-e` already exits explicitly (`exit 0`/`exit 2` in the tier `case`,
# the `[ -d ... ] || { ...; exit 2; }` guards, the final `if` blocks) — nothing here depended on `-e`
# to abort mid-statement.
# NOTE: `-u`/`pipefail` are NOT seam-guarded like the main body is — a `source` leaves both set in the
# CALLER's shell (bash has no scoped `set`). scripts/approve-impl.sh already sets `-euo pipefail`
# itself, so this is a no-op there; a future sourcer that relies on unset variables or an unchecked
# pipe exit status would need to know this.
# NOTE: `${BASH_SOURCE[0]}` makes this file bash-only — sourcing it under `sh`/`dash` would fail on
# that expansion; the shebang and every wiring path already invoke it via `bash`, so this is a
# documented constraint, not a bug.
# Common hook library (.claude/hooks/hooks-lib.sh), loaded FIRST — before `set` and before any read of
# stdin or of the tiers, so that without it EVERY Edit/Write/MultiEdit (even of a `.md`, even under
# specs/) is blocked with exit 2 naming it: this guard never decides without it (R2/N4 of
# 2026-10-biblioteca-comum-dos-hooks). Found next to THIS file via ${BASH_SOURCE[0]}, not `$0` — the
# launcher and the suites source this file. `2>/dev/null` hides bash's raw line; ours is the only one.
# `[ -r ]` + `command .`, not a bare `.`: under POSIXLY_CORRECT a failed `.` is fatal (exit 1, silent —
# and only 2 blocks), so the guard would fail OPEN; `command` strips that special-builtin exit.
# The EXIT trap around the load (fd 9, `|| exit`, HK_LIB_GONE, `trap - EXIT`; exit 2): see hooks-lib.sh → "Who loads it".
# A library that loads but lacks a function this guard calls fails closed the same way (the second line,
# `declare -F`, a builtin): without hk_marker_value the recorded digest would read empty — "marker out of
# the closed form", an AVISO and a pass — and an edited, digest-divergent artifact would let a code edit
# through. hk_lib_loaded is the library's last definition: a load that stopped early is caught too.
case "${BASH_SOURCE[0]}" in */*) HK_DIR="${BASH_SOURCE[0]%/*}" ;; *) HK_DIR=. ;; esac
HK_LIB_GONE="BLOQUEADO pelo sdd-kit: biblioteca dos hooks ausente ou ilegível: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não decide sem ela, e nenhuma chamada passa até ela voltar — o humano a restaura digitando com o prefixo !, ex.: ! git checkout -- .claude/hooks/hooks-lib.sh, ou reinstalando os hooks do kit"
trap 'echo "$HK_LIB_GONE" >&9; exit 2' EXIT
{ [ -r "$HK_DIR/hooks-lib.sh" ] && command . "$HK_DIR/hooks-lib.sh" || exit; } 9>&2 2>/dev/null
trap - EXIT
declare -F hk_marker_value verdict_of mode_of hk_git_env_clean hk_lib_loaded >/dev/null || { echo "BLOQUEADO pelo sdd-kit: biblioteca dos hooks incompleta: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não decide sem ela, e nenhuma chamada passa até ela voltar — o humano a restaura digitando com o prefixo !, ex.: ! git checkout -- .claude/hooks/hooks-lib.sh, ou reinstalando os hooks do kit" >&2; exit 2; }
# The repository read (the approval marker's history) is the cwd's: see hooks-lib.sh → hk_git_env_clean. Before
# the SDD_GATE_SOURCE_ONLY cut below, so the launcher that sources this gate is cleaned too.
hk_git_env_clean
set -uo pipefail

# verdict_of <file> — the verdict reader (R6) is defined once, in hooks-lib.sh, loaded above.

# content_digest — the intact-digest rule LIVES here (portable, copy-verbatim), sourced by
# scripts/approve-impl.sh; recorded_digest/approved_when are wrappers over hk_marker_value in hooks-lib.sh.
# See design.md → "Digest íntegro" and "Onde a regra mora (portabilidade)".
# content_digest <file> — sha256 of the artifact's BYTES MINUS the three lines that approval itself
# writes (Status:, approved-by, approved-content); first 12 hex chars. Excluding them is what makes
# the digest well-defined BEFORE and AFTER the flip: computing it at both moments gives the same
# value, and that's what lets the refusal compare without ambiguity. Including any of them would
# make it self-referential and it would never stabilize. Digest of BYTES, no sort and no locale →
# stable across platforms.
# `|| true`: an artifact made up ONLY of excluded lines would make grep exit 1 and pipefail abort.
# The body is read as BYTES (`LC_ALL=C grep -a`): under a UTF-8 locale GNU grep treats a file with an
# invalid UTF-8 byte as binary and drops the line carrying it, so an edit on that line left the digest
# unchanged, and the same file hashed differently under C and under UTF-8 (2026-10-digest-localidade).
content_digest() {
  { LC_ALL=C grep -a -vE '^(Status:|<!-- approved-by:|<!-- approved-content:)' "$1" || true; } \
    | sha256sum | cut -c1-12
}
# recorded_digest <file> — the recorded digest, or empty if absent. Requires the CLOSED form: a
# truncated marker counts as absent (⇒ re-approve), never as verified. The marker reader (R5) is
# defined once, in hooks-lib.sh (hk_marker_value, the same the launcher reads the approval date with);
# this name stays because the suites and the SoT call it.
recorded_digest() { hk_marker_value "$1" approved-content; }

# marker_in_history <file> → 0 (verdadeiro) se o HISTÓRICO do caminho mostra que o arquivo já
# carregou um marcador `approved-content`. É o que separa REMOÇÃO de aprovação à mão: ambas chegam
# aqui como "arquivo sem marcador", e só o histórico as distingue (achado do validation-gate,
# 2026-09-19 — apagar a linha do marcador limpava um artefato editado, em silêncio).
# `-S<string>`: commits que MUDAM o número de ocorrências da string no caminho — inclui tanto o
# commit que gravou o marcador quanto o que o apagou; `-1` basta porque a pergunta é de existência.
# LC_ALL=C: a saída (`%h`) é consumida por comparação de vazio, e locale não pode intrometer.
# TOLERÂNCIA DELIBERADA: sem `git`, fora de um repositório, ou com QUALQUER erro do git, a resposta é
# "não há histórico" (return 1) e vale a regra anterior — aprovação à mão libera. Um erro de
# ferramenta nunca vira bloqueio por acidente; esse fallback tem caso NOMEADO em tests/test-hooks.sh
# (fora de git, e com PATH sem git), para não ser passagem por omissão. O resíduo declarado no design
# é a remoção commitada num repositório sem histórico (clone raso): sem histórico, não há distinção.
marker_in_history() {
  local f="$1" dir root prefix
  command -v git >/dev/null 2>&1 || return 1
  dir="$(dirname "$f")"
  git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || return 1
  [ -n "$root" ] || return 1
  # `--show-prefix` dá o caminho de $dir RELATIVO à raiz já normalizado pelo próprio git — evita
  # montar o caminho à mão e errar por symlink (/tmp) ou por `..` no caminho da fixture.
  prefix="$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)" || return 1
  [ -n "$(LC_ALL=C git -C "$root" log -1 -S'<!-- approved-content:' --format=%h -- "${prefix}$(basename "$f")" 2>/dev/null)" ]
}

missing_for() { # $1=dir -> prints the condition that's missing; silence = cleared
  local d="$1" cm="$1/change.md" mode art f rec
  # ── VIA RÁPIDA branch (Mode: fast): cleared by the signed marker, not by the four tokens ──
  if [ -e "$cm" ]; then
    mode="$(mode_of "$cm")"   # hooks-lib.sh; grep's line on a directory/unreadable change.md is not hidden here
    if [ "$mode" = "fast" ]; then
      grep -q '<!-- authorized-by:' "$cm" && return 0
      echo "change.md com Mode: fast sem o marcador authorized-by"; return 0
    fi
  fi
  # ── FORMAL branch: the four tokens, unchanged ──
  [ -f "$d/spec.md" ]               || { echo "spec.md ausente"; return 0; }
  [ -f "$d/design.md" ]             || { echo "design.md ausente"; return 0; }
  [ -f "$d/tasks.md" ]              || { echo "tasks.md ausente"; return 0; }
  [ -f "$d/consistency-report.md" ] || { echo "consistency-report.md ausente (Gate 1.5)"; return 0; }
  grep -qiE '^Status:[[:space:]]*Approved' "$d/spec.md"   || { echo "spec.md não está Approved"; return 0; }
  grep -qiE '^Status:[[:space:]]*Approved' "$d/design.md" || { echo "design.md não está Approved (Gate 1.5)"; return 0; }
  # ── Digest íntegro (R6): for spec.md and design.md, IF an approved-content marker is present, it
  # must match the recomputed digest — editing the artifact after approval must not silently
  # invalidate the approval. An absent marker (hand-made approval) is not checked — sanctioned by
  # doctrine (spec-layout → Status field) — UNLESS the path's history shows the marker was once
  # there: that absence is a REMOVAL, and removal is divergence (marker_in_history above).
  # A marker present outside the CLOSED form
  # (truncated/edited) does not block — it counts as absent, but warns by name, because silence
  # there would hide that the check stopped applying.
  for art in spec.md design.md; do
    f="$d/$art"
    if ! grep -q '<!-- approved-content:' "$f"; then
      # Marcador ausente: aprovação à mão (libera) OU REMOÇÃO (bloqueia). O histórico decide.
      if marker_in_history "$f"; then                                                     # R6-removal
        echo "$art perdeu o marcador de conteúdo aprovado (o histórico mostra que já o carregou) — remoção é tratada como divergência. Para re-transcrever, o humano digita a mesma linha que a guarda de aprovação imprime (o lançador com o subcomando do artefato e o change-id); doutrina: spec-layout → Status field"  # R6-removal
        return 0                                                                          # R6-removal
      fi                                                                                  # R6-removal
      continue
    fi
    rec="$(recorded_digest "$f")"
    if [ -z "$rec" ]; then
      # Two purpose-built channels: stderr (as always) AND the hook's REAL stdout via fd 3 (opened
      # by `exec 3>&1` further below, BEFORE this loop runs) — never fd 1 directly, because this
      # `missing_for` runs inside `why="$(missing_for ...)"`; an `echo` to fd 1 here would be
      # captured as a blocking reason (it isn't: this branch is `continue`, not `return`). Claude
      # Code only shows stderr on the blocking path (exit 2) — on the allow path (exit 0, this
      # case) only real stdout shows up in transcript mode, hence the need for the second channel.
      msg="AVISO sdd-kit: '$(basename "$d")': marcador de digest de $art sem digest legível (fora da forma esperada) — tratado como ausente; re-transcreva a aprovação para restaurar a verificação"
      echo "$msg" >&2
      # Sourced caller (SDD_GATE_SOURCE_ONLY) never opens fd 3, so the duplicate write is silently
      # skipped there instead of failing with "Bad file descriptor".
      { echo "$msg" >&3; } 2>/dev/null || true
      continue
    fi
    if [ "$rec" != "$(content_digest "$f")" ]; then
      echo "$art foi editado depois da aprovação (digest gravado ≠ recomputado). Para re-transcrever, o humano digita a mesma linha que a guarda de aprovação imprime (o lançador com o subcomando do artefato e o change-id); doutrina: spec-layout → Status field"
      return 0
    fi
  done
  # First `^Verdict:` line only → immune to the token cited in a fenced block further down in the
  # report.
  # -w: exact token (PASS, not a substring).
  [ "$(verdict_of "$d/consistency-report.md")" = "PASS" ] \
    || { echo "consistency-report.md sem Verdict: PASS na primeira linha"; return 0; }
}

# path_is_outside <path> → 0 when the path lies OUTSIDE the project, 1 when inside (R1 of
# 2026-10-guardas-sem-falso-positivo; design.md → "O julgamento do caminho (R1)"). "The project" is the
# hook's cwd — the same anchor the relative `specs/active` below uses. DEPENDENCY (line N of epic 003):
# if the wiring ever runs this hook from another cwd (a subdirectory), re-anchor BOTH together, or every
# project file outside that subdirectory would be judged outside and let through.
# Fail closed: "outside" only when all three checks say so; the first that says inside returns 1, and
# the costly ones run after the cheap ones. Steps 1 and 2 only conclude "inside" (text); "outside" only
# comes out of step 3 (inode). The common path — an edit inside the project — stops at step 1, fork-free.
# A newline counts as inside: the `read` of step 1 stops at the first line, and `/tmp/a⏎/../../<root>/x`
# would read as `/tmp/a`. No legitimate path has one.
# 1. Text, logical cwd (no fork): relative → "$PWD/$path"; `""`/`.` dropped, `..` pops, the rest appends.
# 2. Text, physical cwd (one fork, `pwd -P`).
# 3. Physical form, per candidate — the raw path (relative prefixed with $PWD/, NOT normalized) and, when
#    it differs, the normalized one (the Write tool resolves `..` by TEXT, so `$n` is where it lands; the
#    raw path, resolved by the system, covers a tool that resolves it that way). A candidate that is
#    itself a symlink is inside, wherever it points. Otherwise climb (no fork; `${d%/*}` of `/x` is empty
#    and `:-/` stops the climb at `/`) to the nearest existing directory, then in ONE subshell `cd -P`
#    into it — the system resolves links and `..` as the write would — and climb with `cd -P ..` to `/`,
#    asking at every level `[ . -ef "$root" ]`: same device AND inode, never text (a case-insensitive
#    filesystem or a bind mount spells the same directory differently; a sibling `<root>-old/` is not
#    a prefix match either). A failing `cd -P` or a subshell that dies counts as inside: a tool error
#    never opens the guard. Declared residue: a hard link from outside to a project file (design.md →
#    "Failure modes & rollout").
path_is_outside() {
  local p="$1" n="" part root d c
  local -a parts cands
  case "$p" in *$'\n'*) return 1 ;; esac
  [[ $p == /* ]] || p="$PWD/$p"
  IFS=/ read -r -a parts <<< "$p" || return 1  # a here-string ends in a newline, so `read` returns 0; a failure (no temp dir below bash 5.1) is a tool error, and a tool error never opens the guard
  for part in ${parts[@]+"${parts[@]}"}; do
    case "$part" in
      ""|.) ;;
      ..) n="${n%/*}" ;;
      *) n="$n/$part" ;;
    esac
  done
  n="${n:-/}"
  [[ "$n/" == "${PWD%/}/"* ]] && return 1                     # step 1 — `/` as cwd contains everything
  root="$(pwd -P)" || return 1
  [[ "$n/" == "${root%/}/"* ]] && return 1                    # step 2
  root="$PWD"                                                 # step 3 compares by inode: either form serves
  cands=("$p"); [ "$n" = "$p" ] || cands+=("$n")
  for c in "${cands[@]}"; do
    [ -L "$c" ] && return 1
    d="${c%/*}"; d="${d:-/}"
    while [ ! -d "$d" ]; do d="${d%/*}"; d="${d:-/}"; done
    ( cd -P -- "$d" 2>/dev/null || exit 1
      while :; do
        [ . -ef "$root" ] && exit 1
        [ . -ef .. ] && exit 0                                # reached `/`
        cd -P .. 2>/dev/null || exit 1
      done ) || return 1
  done
  return 0
}

# Testability seam: SDD_GATE_SOURCE_ONLY=1 lets tests (and scripts/approve-impl.sh) `source` this
# file to call its functions (verdict_of, content_digest, recorded_digest, missing_for) without
# running the gate's main body below — stdin is never read, no tier is classified, nothing exits the
# sourcing shell. Same guard name/form as verify-archived-gates.sh. Normal invocation (`bash
# require-approved-spec.sh`) never sets this var, so behavior there is unchanged. Placement matters:
# every statement with a side effect (stdin read, FILE_PATH, the tier `case` with its `exit`s,
# the ACTIVE_DIR check, the folder loop, the final `exit`s) lives INSIDE this guard, so sourcing it never
# exits the caller (tests/test-hooks.sh, block "N5/N6 — guarda de source (SDD_GATE_SOURCE_ONLY)", assertions
# "P1-digest guarda: …"); without the guard the first `exit` reached would exit the caller immediately.
# The `|| [ "${BASH_SOURCE[0]}" = "$0" ]` half (a finding from Task 3's review): without it,
# `SDD_GATE_SOURCE_ONLY=1` sitting in the ENVIRONMENT (not just in a test's `source` line) would
# disable the executed hook outright — exit 0 over a tree that should block. This half makes the seam
# effective ONLY when the file is genuinely sourced: when run directly (`bash require-approved-spec.sh`,
# the normal PreToolUse invocation), BASH_SOURCE[0] equals $0, so the condition is true and the main
# body still runs regardless of what the env var says. Only a real `source` (BASH_SOURCE[0] != $0)
# combined with the var lets this `if` go false. Same guard name/form as verify-archived-gates.sh; that
# file's own literal form is its own precedent (it's a CI script, not policed the same way) and is left
# as-is here — see design.md → "Decisions log".
if [ "${SDD_GATE_SOURCE_ONLY:-0}" != "1" ] || [ "${BASH_SOURCE[0]}" = "$0" ]; then

INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')"
# R1: an edit OUTSIDE the project (the cwd) is never this guard's business, in any tier — hence before
# the tier `case`. path_is_outside fails closed (see above); it depends on the cwd being the project
# root, like `specs/active` below (line N of epic 003).
if [ -n "$FILE_PATH" ] && path_is_outside "$FILE_PATH"; then exit 0; fi
# fd 3: a real stdout channel that survives `why="$(missing_for ...)"` command substitution (which
# only captures fd 1). Opened here, before missing_for is ever called, so it's always available to it.
exec 3>&1

# Classify the edit; first match wins. Tier-1 = THIS kit's own behavioral source, matched with
# form-agnostic globs (no leading */) so they police whether file_path is relative or absolute.
# Adopters of this kit retarget Tier-3 (app code) to their stack; Tier-1 stays the kit's own source.
case "$FILE_PATH" in
  *.claude/hooks/*.sh|*.claude/skills/*.md) ;;                 # Tier-1 POLICE: kit source (hooks + skills)
  */specs/*|*.claude/*|*/target/*|*.md|"") exit 0 ;;           # Tier-2 exempt: SDD artifacts, config/json, READMEs, docs
  *.kt|*.kts|*.java|*/AndroidManifest.xml) ;;          # Tier-3 POLICE: adopted-project app code — edit to taste
  *) exit 0 ;;                                                 # Tier-4 exempt: everything else
esac

ACTIVE_DIR="specs/active"
[ -d "$ACTIVE_DIR" ] || { echo "BLOQUEADO pelo sdd-kit: não há diretório specs/active. Rode primeiro o fluxo da skill spec-brainstorming (veja a skill spec-layout)." >&2; exit 2; }

# The gate is PER CHANGE, not per repo: as long as ANY folder in specs/active/ is not cleared,
# no code edit passes. That condition and its scope have a single source in skill spec-layout,
# rule 1. (Before, both loops exited on first success — so one approved folder forgotten in
# active/ worked as a master key for the whole repo.)
found=0; bad_dir=""; bad_why=""
for change in "$ACTIVE_DIR"/*/; do
  [ -d "$change" ] || continue
  found=1
  why="$(missing_for "${change%/}")"
  if [ -n "$why" ]; then bad_dir="${change%/}"; bad_why="$why"; break; fi
done

if [ "$found" -eq 0 ]; then
  echo "BLOQUEADO pelo sdd-kit: não há mudança em specs/active/ (em implementação). Uma change ainda em discussão mora em specs/proposed/ e só entra em specs/active/ no Gate 1.5 — rode o fluxo da skill spec-brainstorming." >&2
  exit 2
fi
if [ -n "$bad_dir" ]; then
  echo "BLOQUEADO pelo sdd-kit: a mudança ativa '$(basename "$bad_dir")' não está liberada — $bad_why." >&2
  echo "O gate é POR CHANGE: enquanto qualquer pasta em specs/active/ estiver sem liberação, nenhuma edição de código passa." >&2
  echo "Libere-a (Gate 1.5) ou arquive-a. Ver spec-layout rule 1." >&2
  echo "Editar spec.md/design.md não dispara este gate; a próxima edição de código é que bloqueia." >&2
  echo "Este gate só vê specs/active/: uma change ainda em specs/proposed/ (em discussão) não conta aqui." >&2
  exit 2
fi
exit 0

fi # SDD_GATE_SOURCE_ONLY
