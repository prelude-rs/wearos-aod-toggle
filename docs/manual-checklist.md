# Lista de verificação manual no relógio

Verifica R10 de `2026-10-aod-toggle-complication`: roda no OnePlus Watch 3 real, por adb sobre Wi-Fi, em **dois mostradores** (Gravity e um segundo que aceite `SMALL_IMAGE`). Os resultados são copiados para o `evidence.md` da change.

R9 (testes de unidade) e R11 (README) são verificados em outro lugar (`./gradlew testDebugUnitTest` e o próprio README); R10 é esta lista.

## Cabeçalho

- Roda sobre o **release** `cc.floresta.aodtoggle` (rótulo "AOD"), assinado com o keystore do autor. Sem keystore o release sai `unsigned` e o relógio recusa a instalação: registre isso como **bloqueio**, não como OK.
- Build, pareamento/conexão adb por Wi-Fi, instalação e concessão: siga as seções do README ("One-time: release keystore", "Build", "Connect adb over Wi-Fi", "Install and grant the permission"). Não são repetidas aqui.
- Mantenha a tela "Depuração sem fio" aberta; ao cair a conexão, `adb connect <ip>:<porta nova>`.

Registro (preencha):

| Campo | Valor |
|---|---|
| Data | ____ |
| Android do relógio (`adb shell getprop ro.build.version.release`) | ____ |
| Build (`adb shell getprop ro.build.display.id`) | ____ |
| Mostrador 1 | Gravity |
| Mostrador 2 (aceita `SMALL_IMAGE`) | ____ |
| APK release assinado? (`app-release.apk`, não `-unsigned`) | ____ |

Legenda de resultado: OK / falha / bloqueio.

## Item 0 — Premissa 1 (primeiro; risco da spec)

O app, e não só o shell, precisa ler e escrever `Settings.Global ambient_enabled` com `WRITE_SECURE_SETTINGS` concedida por `pm grant`. Se qualquer passo abaixo falhar, **pare**: a spec é reaberta (decisão do autor).

| ID | Verifica | Passo | Esperado | Resultado | Observação |
|---|---|---|---|---|---|
| 0a | Premissa 1, Risco 1 (prova automatizada) | **Antes** de desinstalar o debug: `./gradlew installDebug`, `adb shell pm grant cc.floresta.aodtoggle.debug android.permission.WRITE_SECURE_SETTINGS`, `./gradlew connectedDebugAndroidTest` | Testes instrumentados passam (app lê e escreve a chave) | | |
| 0b | Premissa 1, R4 | Desinstale o debug: `adb uninstall cc.floresta.aodtoggle.debug`. Instale o release e conceda: `adb install -r app/build/outputs/apk/release/app-release.apk` e `adb shell pm grant cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS`. Confirme só um provedor/app "AOD": `adb shell pm list packages \| grep aodtoggle` | Só `package:cc.floresta.aodtoggle` | | |
| 0c | Premissa 1, R4 | `adb shell settings get global ambient_enabled` (anote N). Ponha a complication "AOD" em um mostrador (README, "Use it") e toque nela. Repita o `settings get`. | O valor passa de N para 1-N (0 ↔ 1) | | |

## Verificação do segundo mostrador

Com o mostrador ativo:

```sh
adb shell dumpsys wallpaper | grep mWallpaperComponent        # componente do mostrador ativo
adb shell dumpsys activity service <pacote/serviço do mostrador> | grep supportedTypes
```

O mostrador serve ao R10 se algum espaço listar `SMALL_IMAGE`. Só o Gravity está confirmado; os tipos de um mostrador só aparecem com ele ativo. Se nenhum outro mostrador aceitar, R10 não fecha e a spec é reaberta (Riscos).

## Tabela por mostrador

Repita a tabela para cada mostrador (copie o bloco). Mostrador: **Gravity** / **segundo: ____**. Estado inicial: complication "AOD" no espaço de imagem, permissão concedida.

| ID | Verifica | Passo | Esperado | Resultado | Observação |
|---|---|---|---|---|---|
| F1 | R1 | Abra a edição do mostrador e o seletor do espaço de imagem. Em cada espaço de imagem, veja o ícone com AOD ligado, desligado e (item F3) sem permissão. | "AOD" aparece na lista do espaço de imagem e **só** como imagem; branco (desligado), âmbar (ligado). A imagem não é recortada nem retingida e é legível (Review Focus; Riscos). | | |
| F2 | R2, N7 | Ligue o AOD em Configurações > Tela, volte ao mostrador e force novo pedido de dados (desligue/ligue a tela ou troque e volte o mostrador). Repita desligando. Anote em quanto tempo ou com que gesto a complication acompanha. | Âmbar com AOD ligado, branco com desligado. Sem meta de atualidade: pode ficar antigo até o mostrador pedir de novo (N7); registre quando acompanhou. | | |
| F3 | R3 | `adb shell pm revoke cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS`, recoloque a complication (ou recarregue o mostrador), **sem tocar**. | Cinza já ao aparecer, mesmo com o estado legível | | |
| F4 | R6 | Com a complication cinza, `adb shell pm grant cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS`; anote `adb shell settings get global ambient_enabled`; toque na complication cinza; releia a chave. | Passa a branco/âmbar conforme o AOD, sem reinstalar; a chave não muda | | |
| F5 | R4 | Com permissão, toque na complication desligada, depois ligada. Após cada toque: interruptor em Configurações > Tela, `adb shell settings get global ambient_enabled`, pulso abaixado (tela esmaecida × apagada) e cor da complication. | Valor, interruptor e comportamento do pulso acompanham o novo estado; cor muda (branco ↔ âmbar) | | |
| F6 | R5 | Observação: não há como forçar escrita sem efeito no relógio; coberto pelo teste de unidade (R9). Registre "n/a aqui" apontando o relatório do `testDebugUnitTest`. | Estado exibido = estado relido (teste de unidade) | | |
| F7 | R7 (complication) | Com a complication no mostrador, acione o gatilho (item T3) e volte ao mostrador. | A complication já mostra o novo estado | | |
| F8 | N1 | Meça do toque na complication até a nova cor visível, de ponta a ponta (cronômetro ou gravação de tela, p.ex. `adb shell screenrecord /sdcard/n1.mp4` e contagem de quadros). Faça 3 toques; registre cada tempo. | ≤ 1 s. Passar de 1 s é **falha de N1 neste mostrador**; só o autor pode dispensá-la no `validation-gate` (premissa 2), registrando mostrador, tempo, nome e data. | | Tempos: ____ / ____ / ____ |
| F9 | N1 (gatilho) | Meça da pressão do botão (T3) até o novo estado visível. 3 medidas. | ≤ 1 s (o mostrador não influencia; registre uma vez, no mostrador 1) | | |

## Itens independentes de mostrador

Cada item roda uma vez. Os caminhos de falha usam `adb shell pm revoke ...` e re-concessão (`pm grant`).

| ID | Verifica | Passo | Esperado | Resultado | Observação |
|---|---|---|---|---|---|
| T1 | N4 | `$ANDROID_HOME/build-tools/<versão>/aapt dump permissions app/build/outputs/apk/release/app-release.apk` (alternativa: `apkanalyzer manifest permissions <apk>`). `<versão>` é uma pasta em `$ANDROID_HOME/build-tools/` (ou `~/Android/Sdk/build-tools/` no Linux). | Lista só `android.permission.WRITE_SECURE_SETTINGS`; nenhuma outra, nenhuma de rede | | |
| T2 | N5 | Em um terminal: `adb logcat -c && adb logcat -s AodToggle`. **Caminho feliz:** com permissão, alterne 2 vezes. **Falhas:** (a) `pm revoke` e toque/gatilho (indisponível por permissão); (b) se possível, indisponível por chave ausente (coberto pelo unit test se não reproduzível); (c) escrita sem efeito (idem). Re-conceda depois. | Caminho feliz: nenhuma linha. Cada falha: uma linha na tag `AodToggle` | | |
| T3 | R7 | Em Configurações do relógio, mapeie o botão físico ao app "AOD" (README, "Use it"; o caminho do menu varia). Com permissão, pressione o botão 2 vezes. | O app "AOD" aparece na lista do app e do mapeamento do botão. Cada pressão alterna o AOD (Configurações acompanha), mostra a imagem e o texto corretos ("AOD on"/"AOD off") e volta ao mostrador. Se o botão não aceitar o gatilho, R7 não se verifica e a spec é reaberta. | | |
| T4 | R8 | `adb shell pm revoke cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS`, `adb shell settings get global ambient_enabled`, pressione o botão. Releia a chave. Re-conceda. | Imagem cinza com "AOD unavailable" por ~1 s e fecha; a chave não muda | | |
| T5 | N8 | Em T3 e T4, cronometre (ou grave a tela) quanto tempo o retorno fica visível antes de fechar. | ~1 s | | Tempo: ____ |
| T6 | N6 | Com o app em repouso (sem toque, gatilho fechado): `adb shell dumpsys alarm \| grep cc.floresta.aodtoggle` e `adb shell dumpsys jobscheduler \| grep cc.floresta.aodtoggle`; também `adb shell dumpsys activity services cc.floresta.aodtoggle`. | Os dois `grep` não retornam nada; nenhum serviço ativo do pacote | | |

## Restauração final

1. Re-conceda a permissão se estiver revogada: `adb shell pm grant cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS`.
2. Deixe o AOD no estado que o usuário quer (toque na complication ou `adb shell settings put global ambient_enabled <0|1>`).
3. Confirme que concordam:

```sh
adb shell settings get global ambient_enabled
adb shell settings get secure doze_enabled
```

## Cobertura da spec

| Spec | Itens |
|---|---|
| R1 | F1 |
| R2 | F2 |
| R3 | F3 |
| R4 | 0b, 0c, F5 |
| R5 | F6 (unit test, R9) |
| R6 | F4 |
| R7 | T3, F7 |
| R8 | T4 |
| N1 | F8, F9 |
| N4 | T1 |
| N5 | T2 |
| N6 | T6 |
| N7 | F2 |
| N8 | T5 |
| R9, R11 | verificados fora desta lista |
| R10 | esta lista |
