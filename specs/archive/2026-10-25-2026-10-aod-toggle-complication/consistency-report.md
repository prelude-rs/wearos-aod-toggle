# Consistency Report — 2026-10-aod-toggle-complication

Verdict: PASS
**Justificativa de tamanho:** rodada 9 sobre o delta desde `d725605`: 0 BLOCKING e 9 WARNING (6 abertos de rodadas anteriores, 3 novos), cada um com sítio e conserto.

## Rodadas
| # | Verdict | BLOCKING | WARNING | Reaberturas | Base |
|---|---------|----------|---------|-------------|------|
| 1 | FAIL    | 2        | 5       | 0           | —    |
| 2 | PASS    | 0        | 5       | 0           | 337545f |
| 3 | FAIL    | 1        | 5       | 0           | 0e7bf17 |
| 4 | PASS    | 0        | 4       | 0           | 21200cd |
| 5 | FAIL    | 1        | 6       | 0           | 798d042 |
| 6 | PASS    | 0        | 5       | 0           | 93dbb89 |
| 7 | PASS    | 0        | 6       | 0           | aa20a70 |
| 8 | PASS    | 0        | 6       | 0           | 959c3bf |
| 9 | PASS    | 0        | 9       | 0           | d725605 |

- Parada após a rodada 5: Ricardo Nogueira, 2026-10-25 — continuar com teto (consertar B1 e avisos no design) — teto +1
- Parada após a rodada 6: Ricardo Nogueira, 2026-10-25 — reabrir o Gate 1 para o aro na complication (R1) — teto +1
- Parada após a rodada 7: Ricardo Nogueira, 2026-10-25 — reabrir o Gate 1 para retirar o aro da complication (R1) — teto +1
- Parada após a rodada 8: Ricardo Nogueira, 2026-10-25 — mudar pacote, nome do projeto e assinatura para prelude-rs dentro desta change — teto +1

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W1 | WARNING | design.md:41 (agora keystore da organização prelude-rs), design.md:211 (ainda "Keystore própria") | Aberto desde a rodada 4; o delta reescreveu a linha Release (keystore pessoal → keystore da prelude-rs) e a keystore continua sem R* que a motive; design.md:211 segue falando em "própria" e "preferência do autor". | Reconhecer na Gate 1.5 como escopo do autor e, em design.md:211, trocar "própria" por "da organização prelude-rs". |
| W2 | WARNING | design.md:106-110, design.md:206, design.md:337 (Task 11, ícone de lançador) | Aberto desde a rodada 5 e fora do delta: o ícone (fundo transparente, aro `#3A3A3A`, arte N1 em escala 0,62) continua sem R* que o motive; a spec só o menciona de passagem em R1 e na história ("o ícone do app mantém o aro cinza"). A Task 11 cita só R1, que trata da imagem da complication, e a revisão visual julga o ícone sem critério de aceite. | Reconhecer o ícone como escopo do autor na Gate 1.5. Se ele for requisito, a spec ganha um R* com critério de aceite numa nova reabertura do Gate 1. |

## Check 3 — Contradictions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W3 | WARNING | design.md:113 (raio do traço 16,95) × design.md:115 ("Valores medidos na prévia escolhida.") | Aberto desde a rodada 6 e fora do delta (o delta só retirou o aro, citado logo abaixo): o raio foi trocado de 17,2 (o valor medido na prévia N1) por 16,95 para fechar 1,25×, mas a frase seguinte ainda afirma que todos os valores foram medidos na prévia, o que deixou de valer para o raio. | Em design.md:115, dizer que o raio foi ajustado de 17,2 (medido) para 16,95 para cumprir 1,25× de R1, e que a revisão visual da Task 16 confere a arte sem aro. |
| W4 | WARNING | design.md:239 (Global Constraints: "Tela do gatilho: não se fecha sozinha.") × design.md:94 e design.md:311 (`noHistory` finaliza a tela quando o relógio apaga a tela ou volta sozinho ao mostrador) | Fora do delta: o design faz a tela fechar sem ação do usuário e a restrição global continua dizendo que ela não se fecha sozinha. Quem implementa ou revisa a Task 13 pela restrição pode tratar o fechamento por `noHistory` como defeito e trocar o mecanismo. | Em design.md:239, escrever "não se fecha por tempo; apagar a tela ou a volta automática ao mostrador a finaliza (`noHistory`), o que conta como o usuário sair (R7)". |
| W7 | WARNING | design.md:233 ("o projeto `wearos-complication-aod-toggle`", `rootProject.name`) × `settings.gradle.kts` (`rootProject.name = "aod-toggle"`) | Delta: a linha diz que o `rootProject.name` era `wearos-complication-aod-toggle` até 2026-10-25, mas o código tem `aod-toggle`; esse nome era o do diretório e do título do `CLAUDE.md`, não do Gradle. Quem confere a Task 17 contra a linha estranha a diferença. | Em design.md:233, separar: nome do repositório/diretório antes `wearos-complication-aod-toggle`, `rootProject.name` antes `aod-toggle`, agora ambos `wearos-aod-toggle`. |
| W8 | WARNING | design.md:382-387 (Task 17 `**Files:**`) × `specs/SOURCE-OF-TRUTH.md:1` (`# SOURCE-OF-TRUTH — wearos-complication-aod-toggle`) | Delta: a Task 17 renomeia o título do `CLAUDE.md` mas não cita o SoT, que carrega o nome antigo; a regra 5(b) reescreve o SoT no arquivamento e nada manda o novo nome entrar lá. | Na Task 17 (ou na nota de arquivamento), listar o título do SoT entre os sítios a renomear; `.claude/adopt/decisions.md:8` fica como histórico. |

## Check 4 — Epic invariants
n.a. — change sem épico (spec.md:7 `Epic: none`).

## Check 5 — Unstated assumptions
sem achados

## Check 6 — Verifiability
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W5 | WARNING | design.md:360 (Task 14, meio de manter a tela ligada na medida de N7) | Fora do delta: `adb shell svc power stayon true` e "Permanecer ativo" só mantêm a tela ligada com o relógio na energia. A lista roda por adb sobre Wi-Fi e a Task 14 não manda pôr o relógio no carregador durante N7; fora dele, a tela apaga e a medida cai no caso "tela apagada, sem meta" de N7. | No item N7 da Task 14, mandar fazer a medida com o relógio no carregador (com `stayon` ligado) e confirmar que o mostrador com a complication continua visível durante a carga; se não, nomear outro meio (tempo limite de tela no máximo, restaurado no fim). |
| W6 | WARNING | design.md:362-371 (Task 15, aro na complication) × spec.md R1 ("sem aro") × design.md:373-380 (Task 16) | O delta tornou R1 contraditório com a Task 15: ela segue em `## Decomposição` mandando desenhar o aro (escala 0,62, raio 47), e a Task 16 a desfaz. Quem executa o plano de cima para baixo constrói o que R1 proíbe e depois o remove; um revisor lendo só a Task 15 vê a violação de R1. A Task 16 cobre o F1 do aro (fecha o W6 da rodada 7) e a reversão tem conteúdo conhecido (`f68fa1b`). | Anotar na Task 15, junto ao comentário de reabertura, que está substituída pela Task 16 (feita e desfeita, só histórico), ou trocar o item por "substituída pela Task 16"; e, na Task 16, citar `f68fa1b` como o conteúdo de antes da Task 15. |

| W9 | WARNING | design.md:386-387 (Task 17, keystore `~/prelude-rs-release.jks`, `apksigner … O=prelude-rs`) × `app/build.gradle.kts:7-8` e `README.md:23-33,87` (`aodtoggle.keystore.*`, `~/aodtoggle-release.jks`, alias `aodtoggle`) | Delta: o critério de release assinado exige `O=prelude-rs`, mas a Task 17 não diz se o prefixo de propriedade `aodtoggle.keystore.*` muda, que o `~/.gradle/gradle.properties` do autor (fora do repo) precisa apontar para a keystore e o alias novos, nem o `-dname` do `keytool` do README que produz `O=prelude-rs`; com o README antigo o critério não se reproduz. | Na Task 17: fixar o prefixo (manter ou renomear em `build.gradle.kts`, README e design.md:269), atualizar o exemplo `keytool` do README com `-dname "O=prelude-rs"` e alias `prelude`, e mandar ajustar o `gradle.properties` do autor antes do passo de assinatura. |

## Check 6b — Fronteira do aceite
sem achados

## Check 6c — Dimensionamento
sem achados

## Check 7 — Dev-run premise (UI)
sem achados

## Check 8 — Seams sob teste
sem achados

## Minimal edit set (on FAIL)
### Edições no design
### Reabertura do Gate 1
Reaberturas do Gate 1 propostas: 0
