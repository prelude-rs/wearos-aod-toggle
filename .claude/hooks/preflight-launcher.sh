#!/usr/bin/env bash
# preflight-launcher.sh — o lançador `sdd-approve` está instalado no PATH desta máquina, e é o
# do kit? Diagnóstico POR MÁQUINA, não por repo.
#
# NÃO SE CHAMA `check-`, E ISSO É DESENHO. No kit, `check-` significa "roda na CI": dos 6 arquivos
# `check-*`, **5 rodam lá**. Este NÃO deve rodar na CI, porque afere um executável do PATH de uma
# pessoa — e na CI ele reprovaria 100% das execuções, onde nenhum lançador existe nem deveria
# existir. O precedente é `tests/preflight-approve-install.sh`, cujo cabeçalho registra a mesma
# escolha pelo mesmo motivo.
#
# `SKIP` NUNCA É DESFECHO AQUI. É a lição do caso (g) do pré-voo: `SKIP` retorna 0 e se disfarça de
# verde. Ou o lançador está instalado e correto (exit 0, nomeando caminho e versão), ou não está
# (exit 1, nomeando a linha que resolve).
#
# ESTE ARQUIVO FICA FORA DO `ci.yml` POR DISCIPLINA, NÃO POR MECANISMO — declarado, não escondido.
# Nada impede um `ci.yml` futuro de o adicionar, e nesse dia ele reprovaria tudo. A contenção é
# este cabeçalho, que é documental; um mecanismo real está fora de escopo desta change.
#
# Uso: bash .claude/hooks/preflight-launcher.sh
# Exit 0 = instalado e é o do kit. Exit 1 = ausente, ou é outro executável com o mesmo nome.
# Common hook library, loaded FIRST (before `set`): without it this diagnostic exits 1 naming it (R2 of
# 2026-10-biblioteca-comum-dos-hooks). `[ -r ]` + `command .`: a plain failed `.` is fatal under
# POSIXLY_CORRECT and would exit before the message. Found next to THIS file (BASH_SOURCE).
case "${BASH_SOURCE[0]}" in */*) HK_DIR="${BASH_SOURCE[0]%/*}" ;; *) HK_DIR=. ;; esac
# The EXIT trap around the load (fd 9, `|| exit`, HK_LIB_GONE, `trap - EXIT` before this script's own trap; exit 1): see hooks-lib.sh → "Who loads it".
HK_LIB_GONE="sdd-kit: biblioteca dos hooks ausente ou ilegível: $HK_DIR/hooks-lib.sh — ${BASH_SOURCE[0]##*/} não roda sem ela (instalação incompleta?)"
trap 'echo "$HK_LIB_GONE" >&9; exit 1' EXIT
{ [ -r "$HK_DIR/hooks-lib.sh" ] && command . "$HK_DIR/hooks-lib.sh" || exit; } 9>&2 2>/dev/null
trap - EXIT
set -uo pipefail

NAME='sdd-approve'
MARK='# sdd-approve — lançador da transcrição de aprovação'   # assinatura do lançador do kit
PLUGIN_KEY='sdd-kit@forsellers'
MANIFEST="${SDD_PLUGIN_MANIFEST:-$HOME/.claude/plugins/installed_plugins.json}"
DEST="${SDD_LAUNCHER_DEST:-$HOME/.local/bin}"

say(){ printf '  %s\n' "$1"; }
# A linha impressa é, ela própria, SEGURA CONTRA COLISÃO — e isso não é zelo, é R5.
# O pré-voo detecta colisão, mas quem INSTALA é o humano colando esta linha, possivelmente noutro
# momento. Uma linha que sobrescreve tornaria a detecção decorativa: o `[ -e ... ] ||` faz a recusa
# viajar junto com o comando, em vez de depender de alguém ter rodado o diagnóstico antes.
#
# A linha usa `[0].installPath`, e ISSO É UM COMPROMISSO DECLARADO, não descuido: quando o lançador
# ainda não existe não há a quem perguntar, e replicar aqui o filtro de liveness + a recusa de
# escolher recriaria a segunda fonte que esta change acabou de eliminar. O compromisso é contido
# ANUNCIANDO a ambiguidade: se o manifest declara mais de uma instalação, o pré-voo diz isso antes de
# imprimir a linha, e a escolha volta a ser do humano — que é a doutrina do lançador.
install_line(){
  local n
  n="$(jq -r --arg k "$PLUGIN_KEY" '(.plugins[$k] // []) | length' "$MANIFEST" 2>/dev/null || echo '?')"
  if [ "$n" != "1" ]; then
    say "ATENÇÃO: o manifest declara $n instalação(ões) de '$PLUGIN_KEY'. A linha abaixo usa a"
    say "PRIMEIRA, e isso pode não ser a que o Claude Code carregou — confira antes de colar."
  fi
  printf '%s\n' "    [ -e $DEST/$NAME ] && echo 'já existe $DEST/$NAME — verifique antes de sobrescrever' \\"
  printf '%s\n' "      || install -m755 \"\$(jq -r '.plugins[\"$PLUGIN_KEY\"][0].installPath' \"$MANIFEST\")/bin/$NAME\" $DEST/$NAME"
}

echo "pré-voo do lançador $NAME (por máquina, NÃO roda na CI)"

found="$(command -v "$NAME" 2>/dev/null || true)"

if [ -z "$found" ]; then
  echo "FAIL - '$NAME' não está no PATH desta máquina."
  say "A transcrição de aprovação depende dele: o slash-command mediu 1 sucesso em 8, e o"
  say "caminho que funciona é o \`!\` que VOCÊ digita. Para instalar, cole:"
  echo
  install_line
  echo
  say "Se '$DEST' não estiver no seu PATH, acrescente-o ao seu shell rc."
  exit 1
fi

# Achou ALGO com esse nome. É o do kit, ou é executável alheio?
if ! grep -qF -- "$MARK" "$found" 2>/dev/null; then
  echo "FAIL - existe um '$NAME' no PATH, mas NÃO é o lançador do kit."
  say "encontrado em: $found"
  say "O kit NÃO sobrescreve executável alheio. Renomeie o seu, ou instale o do kit com outro"
  say "nome e ajuste a doutrina do seu repo — a decisão é sua, e nada aqui a toma por você."
  exit 1
fi

say "instalado em: $found"

# QUAL instalação ele vai usar? O pré-voo NÃO re-deriva isso: PERGUNTA AO PRÓPRIO LANÇADOR, com
# `--resolve`. Re-derivar foi a primeira versão desta função e estava errada — pegava a entrada `[0]`
# do manifest, sem filtro de liveness e sem a recusa de escolher entre duas ativas, e por isso
# divergia do lançador exatamente no caso que R1/N6 existem para tratar. Um diagnóstico que prevê
# outra coisa do que a ferramenta faz é pior que nenhum: dá confiança falsa.
#
# NUNCA sai 0 sem nomear caminho e versão. A versão anterior imprimia `AVISO:` e saía 0 quando `jq`
# ou o manifest faltavam — o mesmo desfecho-silencioso-que-parece-verde do caso (g), e contra a letra
# do critério de R5 ("passa nomeando o caminho E a versão resolvida").
#
# stdout e stderr ficam SEPARADOS aqui de propósito: o lançador reporta caminho e versão no stderr
# a cada execução (é a exigência de N5), e juntar os dois fluxos faria esse relato contaminar o
# `installPath<TAB>version` que este bloco precisa parsear — foi exatamente o que aconteceu na
# primeira tentativa, e o caso (b) do teste pegou.
resolve_err="$(mktemp)"; trap 'rm -f "$resolve_err"' EXIT
if ! resolved="$("$found" --resolve 2>"$resolve_err")"; then
  echo "FAIL - '$NAME' está instalado, mas não consegue resolver a instalação do plugin."
  sed 's/^/    /' "$resolve_err"
  say "Se a mensagem acima não menciona o motivo, a cópia instalada pode ser ANTERIOR a esta versão"
  say "do lançador (ela não entende --resolve). Reinstale com a linha abaixo:"
  echo
  install_line
  exit 1
fi

IFS=$'\t' read -r resolved_path resolved_ver <<< "$resolved"
if [ -z "$resolved_path" ] || [ -z "$resolved_ver" ]; then
  echo "FAIL - '$NAME' respondeu a --resolve com algo que não é caminho+versão: '$resolved'"
  say "A cópia instalada provavelmente é anterior a esta versão do lançador. Reinstale:"
  echo
  install_line
  exit 1
fi
say "resolve o plugin $resolved_ver em $resolved_path"

# A CÓPIA INSTALADA ESTÁ EM DIA COM A DO PLUGIN? Esta comparação é a contenção que o design declara
# para o risco aceito de "cópia" sobre "symlink" (tabela de failure modes): a cópia no PATH não
# envelhece sozinha, e se o protocolo de resolução mudar num release futuro ela resolve errado em
# silêncio. Por digest, não por inspeção — "parece igual" não é medição.
plugin_copy="$resolved_path/bin/$NAME"
if [ ! -f "$plugin_copy" ]; then
  echo "FAIL - a instalação ativa ($resolved_ver em $resolved_path) não traz bin/$NAME."
  say "O payload do plugin está incompleto, ou esta versão é anterior ao lançador."
  exit 1
fi
if [ "$(sha256sum "$found" | cut -d' ' -f1)" != "$(sha256sum "$plugin_copy" | cut -d' ' -f1)" ]; then
  echo "FAIL - a cópia no seu PATH DIFERE da que o plugin $resolved_ver traz."
  say "no PATH:  $found"
  say "no plugin: $plugin_copy"
  say "Ela ainda resolve, mas pode estar resolvendo por um protocolo antigo. Reinstale:"
  echo
  install_line
  exit 1
fi

echo "PASS - '$NAME' instalado, é o do kit, e está em dia com o plugin $resolved_ver."
exit 0
