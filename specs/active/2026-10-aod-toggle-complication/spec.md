# Spec: Complication e gatilho para alternar o AOD no OnePlus Watch 3

Change-ID: 2026-10-aod-toggle-complication
Status: Approved
<!-- approved-by: Ricardo Nogueira on 2026-10-25 -->
<!-- approved-content: sha256:f1fbba4f90d3 -->
Epic: none
Author(s): ricardo with Claude
Date: 2026-10-24

## Problem & leverage

No OnePlus Watch 3 (Wear OS 5, Android 14, API 34) o AOD só se liga ou desliga no fundo de
Configurações → Tela; não há atalho no painel rápido. Esta change entrega dois atalhos de um toque para o
mesmo ato — alternar o AOD:

- uma **complication** que qualquer mostrador compatível exibe, mostrando o estado atual do AOD e
  alternando-o ao toque;
- um **gatilho**: um app que o usuário mapeia a um botão físico do relógio e que, ao ser aberto,
  alterna o AOD e mostra o novo estado numa tela com um interruptor, que permite desfazer ou alternar
  de novo.

Sem isso, cada troca custa vários toques em Configurações. É uma ferramenta pessoal, instalada por
sideload; não há público além do autor.

**Alavanca.** A versão mais simples (só o gatilho) já cobre a troca; a complication acrescenta a
*leitura* do estado no mostrador, que o gatilho sozinho não dá. As duas compartilham o mesmo ato de
alternar e o mesmo estado, por isso são uma entrega só.

**Contexto — descoberta feita em 2026-10-24, antes desta spec** (via `adb` no relógio do autor):

| Achado | Evidência |
|---|---|
| A chave do AOD é `Settings.Global` `ambient_enabled` (1 = ligado, 0 = desligado). | Ligar o AOD em Configurações mudou `global ambient_enabled` 0→1 e `secure doze_enabled` 0→1; nada mudou em `system`. Escrever só `ambient_enabled=0` desligou o AOD de fato (o interruptor em Configurações acompanhou; com o pulso abaixado a tela apagou). |
| `Settings.Secure` `doze_enabled` é derivada: segue `ambient_enabled`, não o contrário. | Escrever só `doze_enabled=1` não ligou o AOD e não mudou `ambient_enabled`. |
| A escrita exige o poder do shell (`WRITE_SECURE_SETTINGS`). | Feita via `adb shell settings put`; a concessão ao app (`pm grant`) é verificada nesta change. |
| O mostrador Gravity aceita imagem colorida (`SMALL_IMAGE`) nos seus espaços de complication. | `dumpsys` do mostrador ativo: os espaços 1, 2 e 3 listam `SMALL_IMAGE` entre os tipos aceitos. |

## Requirements (functional)

| ID | Requirement | Tenant scope (indústria / grupo / distribuidora / n.a.) | Acceptance criterion (how a reviewer verifies it) |
|----|-------------|---------------------------------------------------------|---------------------------------------------------|
| R1 | A complication é oferecida aos mostradores **apenas** como imagem colorida (`SMALL_IMAGE`): o texto "AOD" desenhado como imagem, com o **O em forma de relógio** (anel fino com 1,25× a altura das letras, centrado na linha delas, e dois ponteiros, de uma cor só — variação "N1" escolhida em 2026-10-25), **sem aro** em volta — **branco** quando o AOD está desligado, **âmbar** (#FFC107) quando ligado, **cinza** (#757575) quando indisponível. | n.a. | No Gravity, a complication aparece na lista do espaço de imagem; com o AOD desligado, ligado e sem a permissão, o revisor vê "AOD" em branco, âmbar e cinza, respectivamente. Os testes de unidade (R9) cobrem os três estados → cor. |
| R2 | O estado mostrado é o estado do AOD como o sistema o reporta: ligado ou desligado; se a chave do AOD não existir no aparelho, o estado é indisponível. | n.a. | Com o AOD ligado (e depois desligado) em Configurações, ao recarregar o mostrador a complication mostra âmbar (e depois branco). O caso "chave ausente" é coberto pelos testes de unidade. |
| R3 | Sem a permissão de escrita concedida ao app, a complication mostra indisponível **antes** de qualquer toque, mesmo podendo ler o estado. | n.a. | Instalado sem `pm grant`, a complication aparece cinza já ao ser colocada no mostrador. |
| R4 | Tocar na complication ligada ou desligada alterna o AOD de fato, e a complication passa a mostrar o novo estado. | n.a. | Após o toque, o interruptor do AOD em Configurações mostra o novo valor, o comportamento com o pulso abaixado acompanha (tela esmaecida × apagada), e a cor da complication muda. |
| R5 | Depois de alternar, o estado mostrado é o estado relido do sistema; se a escrita não surtiu efeito, mostra-se o estado real, sem estado de erro próprio. | n.a. | Teste de unidade: dada uma escrita que não muda o valor relido, o estado mostrado é o relido. |
| R6 | Tocar na complication indisponível reavalia permissão e chave e redesenha; não tenta alternar. | n.a. | Com a complication cinza, rodar `adb shell pm grant <pacote> android.permission.WRITE_SECURE_SETTINGS` e tocar nela: ela passa a branco/âmbar conforme o AOD, sem reinstalar e sem mudar o AOD. |
| R7 | O gatilho é um app que aparece na lista de apps do relógio e pode ser mapeado a um botão físico; ao ser aberto, alterna o AOD e mostra uma tela com a imagem "AOD" do novo estado (como em R1) e, abaixo, um interruptor rotulado "AOD" na posição do novo estado. A tela fica aberta até o usuário sair (botão ou deslizar); tocar no interruptor alterna o AOD de novo (como em R4/R5), e imagem e interruptor passam ao estado relido. A cada alternância, a complication, se estiver em algum mostrador, passa a mostrar o novo estado. | n.a. | O revisor mapeia o gatilho a um botão nas configurações do relógio; cada pressão alterna o AOD (Configurações acompanha) e mostra imagem e interruptor no novo estado; tocar no interruptor alterna de novo; ao sair, a complication no mostrador já mostra o estado final. |
| R8 | Aberto quando a alternância está indisponível, o gatilho não tenta alternar: mostra a imagem cinza, o texto "AOD unavailable" e o interruptor desabilitado (não responde ao toque); a tela fica aberta até o usuário sair. | n.a. | Sem `pm grant`, pressionar o botão mapeado mostra a imagem cinza, "AOD unavailable" e o interruptor desabilitado; tocar nele não faz nada e o AOD em Configurações não muda. |
| R9 | Testes de unidade cobrem o mapeamento de estado (ligado / desligado / indisponível, incluindo chave ausente, permissão ausente e escrita sem efeito) para a imagem e o texto exibidos. | n.a. | `./gradlew testDebugUnitTest` passa e o relatório lista um caso por estado e por causa de indisponível. |
| R10 | Uma lista de verificação manual existe no repositório e é executada no relógio real via depuração adb por Wi-Fi, em **pelo menos dois mostradores** (Gravity e um segundo que aceite `SMALL_IMAGE`), cobrindo R1–R8, R12, N1, N6 e N7. | n.a. | A lista e seus resultados (mostradores usados, data, cada item OK/falha) estão registrados no `evidence.md` da change. |
| R11 | Um README explica: build, pareamento e conexão adb por Wi-Fi, concessão da permissão e instalação. | n.a. | Seguindo só o README, o revisor compila, conecta, concede a permissão e instala o app no relógio (é o roteiro usado em R10). |
| R12 | No seletor de complications do mostrador, a entrada da complication se chama "AOD Toggle"; o nome do app continua "AOD" (lista de apps, cabeçalho do seletor, mapeamento do botão). | n.a. | No editor do mostrador, o seletor do espaço de imagem lista "AOD Toggle" sob o cabeçalho "AOD". |

## Non-functional requirements

| ID | Category | Target (number or explicit "no target") | How it will be measured |
|-----|---------------------|------------------------------|--------------------------|
| N1 | Latency             | ≤ 1 s do toque na complication (ou da pressão no botão, ou do toque no interruptor do gatilho) até o novo estado visível. | Item da lista manual (R10): cronômetro ou gravação de tela, nos dois mostradores. |
| N2 | Throughput / volume | No target (um usuário, uma troca por vez). | — |
| N3 | Tenant isolation    | n.a. — app pessoal, sem dados de tenant, sem rede. | Verificado por N4 (o APK não pede permissão de rede). |
| N4 | Security / authn-z  | O app pede **apenas** `WRITE_SECURE_SETTINGS` como permissão; nenhuma outra (em especial, nenhuma de rede). | Inspecionar as permissões do APK de release (`aapt dump permissions` ou `apkanalyzer`). |
| N5 | Observability       | Toda falha (indisponível por permissão, indisponível por chave, escrita sem efeito) gera uma linha no logcat sob uma única tag; o caminho feliz não registra nada. Nenhuma outra meta. | Item da lista manual: `adb logcat -s <tag>` durante os casos de falha e de sucesso. |
| N6 | Energia             | O único trabalho em segundo plano é a atualização periódica da complication, declarada a cada **5 min** e feita pelo sistema só enquanto a complication está num mostrador ativo; cada atualização só lê o estado e redesenha. Nenhum serviço, alarme ou job próprio do app. | Na lista manual: `dumpsys alarm` e `dumpsys jobscheduler` não listam o pacote; `dumpsys batterystats` em ~1 h com a complication no mostrador mostra no máximo ~12 acionamentos do serviço por hora e CPU desprezível; em ~1 h sem ela em mostrador nenhum, 0 acionamentos. |
| N7 | Atualidade          | Uma mudança do AOD feita fora do app (Configurações) aparece na complication em até ~5 min com a tela ligada (consequência de N6). Com a tela apagada o sistema pode espaçar as atualizações; sem meta nesse caso. | Item da lista manual: mudar o AOD em Configurações, manter a tela ligada e registrar em quanto tempo a complication acompanha. |
| N8 | —                   | Retirado na reabertura de 2026-10-25: a tela do gatilho não se fecha mais sozinha (R7). | — |

## Superfície heurística

N/A — a change não altera hook nem check do kit; nada aqui classifica texto livre por padrão.

## Out of scope

- Publicação na Play Store (o app é instalado por sideload).
- Tiles, mostradores e app companheiro no telefone.
- A agenda do AOD (janela de horário em `system` `start_time_aod` / `over_time_aod`): não é lida nem alterada.
- Tipos de complication de texto (`SHORT_TEXT`) e monocromáticos (`MONOCHROMATIC_IMAGE`).
- Qualquer tela de configuração do app; a única tela é a do gatilho (R7, R8).
- Relógios além do OnePlus Watch 3: podem funcionar, mas não são verificados.
- Verificação no Wear OS 6: a compatibilidade futura é contexto para o design (evitar APIs sabidamente
  removidas), não requisito verificável — não há aparelho com Wear OS 6.
- Escutar mudanças do AOD feitas fora do app em tempo real (observer, serviço permanente): só a atualização periódica de N6/N7.
- Alternativa quando a chave não puder ser escrita (ex.: abrir Configurações): se a chave deixar de
  funcionar, a spec é reaberta.

## Riscos

| Risco | Efeito | Mitigação |
|---|---|---|
| A concessão `pm grant … WRITE_SECURE_SETTINGS` ao app pode se comportar diferente do shell. | R4/R7 não funcionam. | Primeiro item da lista manual; se falhar, a spec é reaberta (decisão do autor). |
| Só o Gravity foi confirmado aceitando `SMALL_IMAGE`; o segundo mostrador de R10 ainda não foi achado (26 mostradores instalados; os tipos de um mostrador só aparecem com ele ativo). | R10 não fecha com dois mostradores. | Procurar durante a execução da lista; se nenhum outro aceitar, a spec é reaberta. |
| Um mostrador pode recortar ou redimensionar a imagem (ex.: em círculo). | "AOD" ilegível em algum espaço. | Verificado visualmente na lista manual, por mostrador. |
| O mapeamento de botão do OnePlus pode não listar qualquer app. | R7 não se verifica. | Item da lista manual; se o botão não aceitar o gatilho, a spec é reaberta. |
| A depuração adb por Wi-Fi cai quando a tela apaga (observado na descoberta). | Atrito na execução da lista. | O README (R11) orienta manter a tela de depuração sem fio aberta e reconectar pela porta nova. |
| O sistema pode espaçar a atualização periódica além de 5 min (ou a OnePlus pode alterar a regra). | N7 não se cumpre. | Medido na lista manual (N6/N7); se não cumprir, a spec é reaberta. |
| Ao adicionar a complication, a OnePlus avisa "High battery usage … reduce your watch's battery life by 1 to 1.5 days" (observado em 2026-10-25, também para o Maps). | Aviso assustador, mas genérico do sistema. | Não há como silenciar pelo app; a medida de N6 registra o consumo real. |
| Uma atualização do sistema pode renomear a chave ou mudar seu efeito. | Estado indisponível ou troca sem efeito. | R2/R5 garantem que o app não quebra; a spec é reaberta. |

## Seções do SoT afetadas

| Seção do SoT (heading literal) | Req IDs |
|---|---|
| Estado atual | R1–R8, R12 |
| Propósito | R1, R7 |
| Arquitetura | R1–R8, N6 |

## Epic invariants that apply

Nenhum — change sem épico.

## Open questions

Nenhuma.

## Reabertura do Gate 1 — 2026-10-25

Depois do uso no relógio, o autor reabriu a spec: N6/N7 (o mostrador não pede dados ao acender a
tela — medido: 0 acionamentos em 4 min com várias trocas de tela; passa a período de 5 min), R7/R8
(tela com interruptor que fica aberta, no lugar do retorno de ~1 s), N8 (retirado), R12 (novo: nome
"AOD Toggle" no seletor), N1 (inclui o interruptor) e R1 (o O vira relógio; o mesmo desenho, em âmbar, é o ícone do app).

Segunda reabertura no mesmo dia, depois da revisão visual: R1 ganha o aro circular em volta da arte, na cor do estado (decisão do autor; no ícone do app o aro é cinza fixo).

Terceira reabertura, depois de ver o aro no relógio: o aro deixava o "AOD" pequeno demais; R1 volta à arte N1 sem aro (decisão do autor). O ícone do app mantém o aro cinza.
