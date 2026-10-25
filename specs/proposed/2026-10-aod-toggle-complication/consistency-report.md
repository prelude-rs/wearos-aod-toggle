# Consistency Report — 2026-10-aod-toggle-complication

Verdict: FAIL
**Justificativa de tamanho:** rodada 1 completa, 2 BLOCKING e 5 WARNING com sítio e conserto cada.

## Rodadas
| # | Verdict | BLOCKING | WARNING | Reaberturas | Base |
|---|---------|----------|---------|-------------|------|
| 1 | FAIL    | 2        | 5       | 0           | —    |

## Check 1 — Coverage spec → design
sem achados

## Check 2 — Coverage design → spec (adversarial; flag scope creep)
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| W1 | WARNING | design.md:37, design.md:169, design.md:209 (assinatura de release com keystore própria) | Nenhum R*/N* pede APK de release assinado: N4 mede permissões com `aapt`, que lê APK sem assinatura, e o Dev-run usa `installDebug`. A justificativa é só "pedido do autor"; é peça (propriedades `aodtoggle.keystore.*`, README, constraint de repositório) sem requisito que a motive. | Remover a assinatura própria do design (release sem assinatura basta para N4; instalação pelo debug), ou o humano reconhece o elemento como escopo aceito na Gate 1.5. |

## Check 3 — Contradictions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| B1 | BLOCKING | design.md:139 ("nenhuma dependência que traga permissão"), design.md:33, design.md:187 | Fato de plataforma: `androidx.core` a partir da 1.9.0 injeta no manifesto mesclado `<uses-permission android:name="${applicationId}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"/>` (e o `<permission>` de mesmo nome). `core-ktx` é dependência escolhida e chega também transitivamente pela lib de complications. `aapt dump permissions` vai listar uma segunda permissão, o que viola N4 ("apenas `WRITE_SECURE_SETTINGS`; nenhuma outra"). O mecanismo que o design dá para N4 é falso. | No manifesto do app, remover os dois nós com `tools:node="remove"` (`uses-permission` e `permission` `cc.floresta.aodtoggle.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`). Trocar design.md:139 por esse mecanismo e pôr em design.md:208 o passo "remover permissões injetadas por dependências". |
| W2 | WARNING | design.md:35 ("Android lint (padrão…)") × design.md:208 e design.md:210 | Fato de plataforma: o Android lint tem a checagem `ProtectedPermissions`, com severidade Error, que dispara em `<uses-permission android:name="android.permission.WRITE_SECURE_SETTINGS"/>`. Com o lint padrão e `abortOnError` ligado, `lintDebug` falha, e a Task 1 não chega ao verde que ela mesma exige. | Em design.md:81 e design.md:208, declarar `tools:ignore="ProtectedPermissions"` na `uses-permission` e justificar: a concessão vem de `pm grant`. |
| W3 | WARNING | design.md:81-86 (Manifesto) | Com `targetSdk 34`, todo componente com intent-filter precisa declarar `android:exported`; sem isso o manifest merger falha. O serviço precisa ser `exported="true"` para o sistema fazer o bind, e a activity `MAIN`/`LAUNCHER` também. O design lista o manifesto peça a peça e omite o atributo. Quem escolher `false` no serviço fica sem a complication na lista (R1). | Em design.md:81-86, acrescentar `android:exported="true"` em `AodComplicationService` (protegido por `BIND_COMPLICATION_PROVIDER`) e em `TriggerActivity`, e `android:exported="false"` explícito em `ToggleReceiver`. |
| W4 | WARNING | design.md:255-258 (Task 9, última) × spec.md:89 (mitigação "Primeiro item da lista manual; se falhar, a spec é reaberta") | O risco que pode reabrir a spec (a concessão ao app não funcionar como no shell) só é testado no relógio depois de as Tasks 1–8 estarem prontas. A Task 9 não põe esse item em primeiro lugar e nenhuma task executa a lista. Uma reabertura descoberta ali joga fora todo o trabalho feito antes. | Acrescentar à Task 3 um passo no relógio: instalar o build debug, `pm grant`, ler e escrever `ambient_enabled` pelo app e conferir `checkSelfPermission`. Na Task 9, ordenar esse item como o primeiro da lista, como manda spec.md:89. |

## Check 4 — Epic invariants
n.a. — change sem épico (spec.md:7 `Epic: none`; spec.md:106).

## Check 5 — Unstated assumptions
| # | Classe | Sítio | Por que morde aqui | Conserto |
|---|--------|-------|---------------------|----------|
| B2 | BLOCKING | design.md:54 (`read(): Int?`), design.md:221 (`read()` nulo só em `SettingNotFoundException`) | O design supõe que um app de terceiro com `targetSdk 34` consegue ler `Settings.Global` `ambient_enabled`; a descoberta (spec.md:33-35) só provou a leitura pelo shell. Fato de plataforma: desde o Android 12, o SettingsProvider lança `SecurityException` quando um app não sistema que mira S+ lê uma chave declarada `@hide` sem `@Readable`. Não está estabelecido se a chave Wear `ambient_enabled` cai nessa regra no OW3. Se cair, a exceção não capturada derruba o serviço, o receiver e o gatilho, e nem o estado indisponível de R2/R3 aparece. Nem a spec nem as Assumptions do design ("Nenhuma") registram essa premissa. | Em design.md:221: `read()` captura `SecurityException`, devolve `null` (→ `Unavailable(KEY_MISSING)`) e registra uma linha distinta sob `AodToggle`. Acrescentar a linha à tabela de falhas (design.md:147-153) e às Assumptions (design.md:174). Cobrir a leitura pelo app no passo de dispositivo da Task 3 (W4). Se a leitura falhar no relógio, aplica-se o risco de spec.md:94 (spec reaberta). |
| W5 | WARNING | design.md:136 (N1 "por construção") | Pelo design, N1 sai por construção, mas a latência entre `requestUpdateAll()` e o redesenho é decidida pelo sistema Wear e pelo mostrador (que pede os dados de novo quando quer), não pelo app. É uma premissa do design que nenhum risco da spec cobre. | Registrar em design.md:174 (Assumptions) que o mostrador atende `requestUpdateAll()` em menos de 1 s, verificado no primeiro item de N1 da lista. Levar ao humano na Gate 1.5 a pergunta sobre o que fazer se não atender (hoje não há mitigação em spec.md Riscos). |

## Check 6 — Verifiability
sem achados

## Check 6b — Fronteira do aceite
sem achados

## Check 6c — Dimensionamento
n.a. — 9 blocos em `## Decomposição` (≤16); a justificativa de dimensionamento lê `N/A`.

## Check 7 — Dev-run premise (UI)
sem achados

## Check 8 — Seams sob teste
sem achados

## Minimal edit set (on FAIL)
### Edições no design
- design.md:139 → mecanismo de N4: remover com `tools:node="remove"` a `uses-permission` e a `permission` `${applicationId}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` injetadas por `androidx.core` (B1).
- design.md:208 → passo do manifesto: remover as permissões injetadas por dependências e marcar a `uses-permission` com `tools:ignore="ProtectedPermissions"` (B1, W2).
- design.md:221 → `read()` captura `SecurityException`, devolve `null` e registra uma linha distinta (B2).
- design.md:147-153 → nova linha de falha: "leitura da chave negada (`SecurityException`)", com o estado indisponível e o log (B2).
- design.md:174 → Assumptions: a leitura de `ambient_enabled` pelo app com `targetSdk 34` (B2) e a latência de `requestUpdateAll()` ≤ 1 s (W5).
- design.md:81-86 → `android:exported="true"` no serviço e na activity, `exported="false"` explícito no receiver (W3).
- design.md:218-222 (Task 3) → passo no relógio: `installDebug`, `pm grant`, leitura e escrita da chave pelo app, `checkSelfPermission` (W4, B2).
- design.md:258 (Task 9) → o item "concessão `pm grant` ao app" é o primeiro da lista (W4).
- design.md:37, design.md:169, design.md:209 → retirar a keystore própria, ou o humano a reconhece como escopo aceito (W1).
### Reabertura do Gate 1
Reaberturas do Gate 1 propostas: 0
