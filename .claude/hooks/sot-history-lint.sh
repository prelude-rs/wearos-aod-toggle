#!/usr/bin/env bash
# sot-history-lint.sh — WARNING-only lint: flags history wording in SOURCE-OF-TRUTH.md.
# Usage: sot-history-lint.sh <file>. Always exit 0 (R9). Output: "AVISO <file>:<line> [<class>] <text>"
# per occurrence + "AVISOS: <n>". Provenance forms (dispensed) are DEFINED in spec-layout → "Protocol
# tokens" (portable single source); this script implements them, it does not restate them.
# Classes and pattern lists: design.md appendix of 2026-09-sot-reescrito-no-fechamento (origin).
# Blind spot (by design, not a bug): heading lines terminate a paragraph and are not scanned — wording
# inside a heading's own text is never flagged.
# Common hook library, loaded FIRST (before `set`, before any argument): without it this lint exits 1
# naming it — the one non-zero exit it has (R2 of 2026-10-biblioteca-comum-dos-hooks). `[ -r ]` +
# `command .`: a plain failed `.` is fatal under POSIXLY_CORRECT and would exit before the message.
case "${BASH_SOURCE[0]}" in */*) HK_DIR="${BASH_SOURCE[0]%/*}" ;; *) HK_DIR=. ;; esac
# The EXIT trap around the load (fd 9, `|| exit`, HK_LIB_GONE, `trap - EXIT`; exit 1): see hooks-lib.sh → "Who loads it".
HK_LIB_GONE="sdd-kit: biblioteca dos hooks ausente ou ilegível: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não roda sem ela (instalação incompleta?)"
trap 'echo "$HK_LIB_GONE" >&9; exit 1' EXIT
{ [ -r "$HK_DIR/hooks-lib.sh" ] && command . "$HK_DIR/hooks-lib.sh" || exit; } 9>&2 2>/dev/null
trap - EXIT
set -uo pipefail
f="${1:?uso: sot-history-lint.sh <arquivo>}"
[ -f "$f" ] || { echo "AVISO: arquivo não encontrado: $f"; echo "AVISOS: 0"; exit 0; }
AWK="${AWK:-awk}"
"$AWK" -v FILE="$f" '
function blank(k,  s) { s = ""; while (k-- > 0) s = s " "; return s }
function warn(ln, cls, txt) { gsub(/^[ \t]+/, "", txt); printf "AVISO %s:%d [%s] %s\n", FILE, ln, cls, substr(txt,1,100); total++ }
function flush(   joined, masked, i, off, seg, low) {   # process the buffered paragraph: lines par[1..n], starting at line pstart
  if (n == 0) return
  joined = ""
  for (i = 1; i <= n; i++) joined = (i > 1 ? joined "\n" : joined) par[i]   # never `name (expr)`: busybox reads it as a call
  # provenance spans -> mask them out of a COPY used only for change-id detection
  masked = joined
  while (match(masked, /`[^`]*archive\/[^`]*`/))            masked = substr(masked,1,RSTART-1) blank(RLENGTH) substr(masked,RSTART+RLENGTH)
  while (match(masked, /ADR [0-9][0-9][0-9][0-9]/))         masked = substr(masked,1,RSTART-1) blank(RLENGTH) substr(masked,RSTART+RLENGTH)
  while (match(masked, /\([^()]*(archive\/|`20[0-9][0-9]-[0-9][0-9]-[a-z][a-z0-9-]*`|ADR [0-9][0-9][0-9][0-9])[^()]*\)/)) masked = substr(masked,1,RSTART-1) blank(RLENGTH) substr(masked,RSTART+RLENGTH)
  # change-id occurrences left in masked -> class change-id-solto, mapped back to the owning line
  off = 0
  for (i = 1; i <= n; i++) {
    seg = substr(masked, off + 1, length(par[i]))
    while (match(seg, /20[0-9][0-9]-[0-9][0-9]-[a-z][a-z0-9-]*/)) {
      if (RSTART < 8 || substr(seg, RSTART-8, 8) != "archive/") warn(pstart+i-1, "change-id-solto", par[i])
      seg = substr(seg, 1, RSTART-1) blank(RLENGTH) substr(seg, RSTART+RLENGTH)
    }
    off += length(par[i]) + 1
  }
  for (i = 1; i <= n; i++) {
    low = tolower(par[i])
    if (low ~ TRANS) warn(pstart+i-1, "transição", par[i])
    if (par[i] ~ NARR) warn(pstart+i-1, "narrativa", par[i])
  }
  n = 0
}
BEGIN {
  TRANS = "(passou a|passaram a|passa(m)? a (ser|exibir|replicar|expor|usar)|deixou de|deixaram de|deixa(m)? de ser|anteriormente|até então|não mais|já não|virou|viraram|voltou a|foi (removid|substitu|adicionad|trocad|renomead|internalizad|revertid)[a-z]*|antes (vinha|era|ficava|só|deliberadamente)|no longer|previously|used to|was replaced|formerly|has been (removed|replaced))"
  NARR  = "([Cc]hange +`?(20[0-9][0-9]-[0-9][0-9]-|C[0-9])|PR *#[0-9]+|\\(#[0-9]+\\)|seq *[0-9]+|Atualização [0-9]+/[a-z][a-z][a-z])"
  n = 0; total = 0
}
/^[ \t]*$/ || /^##?#?#?#?#? / { flush(); next }
/^\|/ { flush(); n = 1; par[1] = $0; pstart = NR; flush(); next }
{ if (n == 0) pstart = NR; par[++n] = $0 }
END { flush(); printf "AVISOS: %d\n", total }
' "$f"
exit 0
