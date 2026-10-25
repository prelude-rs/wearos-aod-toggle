# Lista de verificação manual no relógio

Verifica R10 de `2026-10-aod-toggle-complication`: roda no OnePlus Watch 3 real, por adb sobre Wi-Fi, em **dois mostradores** (Gravity e um segundo que aceite `SMALL_IMAGE`). Os resultados são copiados para o `evidence.md` da change.

Cobre R1–R8, R12, N1, N6 e N7 (N8 foi retirado). R9 (testes de unidade) e R11 (README) são verificados em outro lugar (`./gradlew testDebugUnitTest` e o próprio README); R10 é esta lista.

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

O app, e não só o shell, precisa ler e escrever `Settings.Global ambient_enabled` com `WRITE_SECURE_SETTINGS` concedida por `pm grant`. **Só reabre a spec** (decisão do autor) uma leitura ou escrita **negada ao app** (`SecurityException`, ou falha de asserção em 0a) **com a concessão feita**. **Erro de arnês não reabre**: conexão adb caída, falha de instalação (APK `unsigned`, assinatura diferente) ou falha de `pm grant` (inclusive a falha rotulada "harness: pm grant failed" no teste). Nesses casos, reconecte/corrija e rode de novo; registre como bloqueio, não como falha da premissa.

| ID | Verifica | Passo | Esperado | Resultado | Observação |
|---|---|---|---|---|---|
| 0a | Premissa 1, Risco 1 (prova automatizada) | **Antes** de desinstalar o debug: `./gradlew installDebug`, `adb shell pm grant cc.floresta.aodtoggle.debug android.permission.WRITE_SECURE_SETTINGS`, `./gradlew connectedDebugAndroidTest` | Testes instrumentados passam (app lê e escreve a chave). Falha de asserção em leitura ou escrita **com a concessão feita**: reabre a spec. Erro de arnês (conexão, instalação, "harness: pm grant failed"): reconecte e rode de novo | | |
| 0b | Premissa 1, R4 | Desinstale o debug: `adb uninstall cc.floresta.aodtoggle.debug`. Instale o release e conceda: `adb install -r app/build/outputs/apk/release/app-release.apk` e `adb shell pm grant cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS`. Confirme só um provedor/app "AOD": `adb shell pm list packages \| grep aodtoggle` | Só `package:cc.floresta.aodtoggle`. Erro de instalação ou de `pm grant` é problema de arnês (corrija e repita), não da premissa | | |
| 0c | Premissa 1, R4 | `adb shell settings get global ambient_enabled` (anote N). Ponha a complication "AOD" em um mostrador (README, "Use it") e toque nela. Repita o `settings get`. | O valor passa de N para 1-N (0 ↔ 1). Só leitura ou escrita negada ao app (com a concessão feita) reabre a spec | | |

## Verificação do segundo mostrador

Com o mostrador ativo:

```sh
adb shell dumpsys wallpaper | grep mWallpaperComponent        # componente do mostrador ativo
adb shell dumpsys activity service <pacote/serviço do mostrador> | grep supportedTypes
```

O mostrador serve ao R10 se algum espaço listar `SMALL_IMAGE`. Só o Gravity está confirmado; os tipos de um mostrador só aparecem com ele ativo. Se nenhum outro mostrador aceitar, R10 não fecha e a spec é reaberta (Riscos).

## Tabela por mostrador

Repita a tabela para cada mostrador (copie o bloco). Mostrador: **Gravity** / **segundo: ____**. Estado inicial: complication "AOD Toggle" no espaço de imagem, permissão concedida.

| ID | Verifica | Passo | Esperado | Resultado | Observação |
|---|---|---|---|---|---|
| F1 | R1, R12 | Abra a edição do mostrador e o seletor do espaço de imagem. Veja o cabeçalho e a entrada da complication; em cada espaço de imagem, veja a arte com AOD ligado, desligado e (item F3) sem permissão. | O seletor lista **"AOD Toggle"** sob o cabeçalho "AOD" (R12), **só** como imagem. A arte é o texto "AOD" com o O em forma de relógio (anel e dois ponteiros, uma cor só): branco (desligado), âmbar (ligado). A imagem não é recortada nem retingida e é legível (Review Focus; Riscos). | | |
| F2 | R2, N7 | Com a **tela ligada**, mude o AOD em Configurações > Tela (ligado, depois desligado) e volte ao mostrador sem tocar na complication. Cronometre até a complication acompanhar a mudança. Pode ser feito na medida de N7 (item T8, no carregador, tela mantida ligada). | Âmbar com AOD ligado, branco com desligado, em ≤ ~5 min (N7); registre o tempo de cada mudança. | | Tempos: ____ / ____ |
| F3 | R3 | `adb shell pm revoke cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS`, recoloque a complication (ou recarregue o mostrador), **sem tocar**. | Cinza já ao aparecer, mesmo com o estado legível | | |
| F4 | R6 | Com a complication cinza, `adb shell pm grant cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS`; anote `adb shell settings get global ambient_enabled`; toque na complication cinza; releia a chave. | Passa a branco/âmbar conforme o AOD, sem reinstalar; a chave não muda | | |
| F5 | R4 | Com permissão, toque na complication desligada, depois ligada. Após cada toque: interruptor em Configurações > Tela, `adb shell settings get global ambient_enabled`, pulso abaixado (tela esmaecida × apagada) e cor da complication. | Valor, interruptor e comportamento do pulso acompanham o novo estado; cor muda (branco ↔ âmbar) | | |
| F6 | R5 | Observação: não há como forçar escrita sem efeito no relógio; coberto pelo teste de unidade (R9). Registre "n/a aqui" apontando o relatório do `testDebugUnitTest`. | Estado exibido = estado relido (teste de unidade) | | |
| F7 | R7 (complication) | Com a complication no mostrador, acione o gatilho (item T3) e volte ao mostrador. | A complication já mostra o novo estado | | |
| F8 | N1 | Meça do toque na complication até a nova cor visível, de ponta a ponta (cronômetro ou gravação de tela, p.ex. `adb shell screenrecord /sdcard/n1.mp4` e contagem de quadros). Faça 3 toques; registre cada tempo. | ≤ 1 s. Passar de 1 s é **falha de N1 neste mostrador**; só o autor pode dispensá-la no `validation-gate` (premissa 2), registrando mostrador, tempo, nome e data. | | Tempos: ____ / ____ / ____ |
| F9 | N1 (gatilho) | Meça da pressão do botão (T3) até o novo estado visível, e do toque no interruptor até a imagem e o interruptor no novo estado. 3 medidas de cada. | ≤ 1 s (o mostrador não influencia; registre uma vez, no mostrador 1) | | Botão: ____ / ____ / ____; interruptor: ____ / ____ / ____ |

## Itens independentes de mostrador

Cada item roda uma vez. Os caminhos de falha usam `adb shell pm revoke ...` e re-concessão (`pm grant`).

| ID | Verifica | Passo | Esperado | Resultado | Observação |
|---|---|---|---|---|---|
| T1 | N4 | `$ANDROID_HOME/build-tools/<versão>/aapt dump permissions app/build/outputs/apk/release/app-release.apk` (alternativa: `apkanalyzer manifest permissions <apk>`). `<versão>` é uma pasta em `$ANDROID_HOME/build-tools/` (ou `~/Android/Sdk/build-tools/` no Linux). | Lista só `android.permission.WRITE_SECURE_SETTINGS`; nenhuma outra, nenhuma de rede | | |
| T2 | N5 | Em um terminal: `adb logcat -c && adb logcat -s AodToggle`. **Caminho feliz:** com permissão, alterne 2 vezes. **Falhas:** (a) `pm revoke` e toque/gatilho (indisponível por permissão); (b) se possível, indisponível por chave ausente (coberto pelo unit test se não reproduzível); (c) escrita sem efeito (idem). Re-conceda depois. | Caminho feliz: nenhuma linha. Cada falha: ≥1 linha na tag `AodToggle` (adaptador e núcleo podem registrar cada um); nenhuma no caminho feliz | | |
| T3 | R7 | Em Configurações do relógio, mapeie o botão físico ao app "AOD" (README, "Use it"; o caminho do menu varia). Com permissão, pressione o botão 2 vezes; depois, com a tela do gatilho aberta, (a) toque no interruptor, (b) pressione o botão de novo, (c) apague a tela. | O app "AOD" aparece na lista do app e do mapeamento do botão. Cada pressão alterna o AOD (Configurações acompanha) e mostra a imagem "AOD" e o interruptor "AOD" no novo estado; a tela **fica aberta** até o usuário sair (botão ou deslizar). (a) Tocar no interruptor alterna o AOD de novo, e imagem e interruptor passam ao estado relido. (b) Pressionar o botão com a tela aberta alterna de novo. (c) Apagar a tela a fecha (decisão do autor; ruling da execução, `evidence.md` § Rulings); a próxima abertura alterna de novo. Se o botão não aceitar o gatilho, R7 não se verifica e a spec é reaberta. | | |
| T4 | R8 | `adb shell pm revoke cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS`, `adb shell settings get global ambient_enabled`, pressione o botão. Toque no interruptor. Releia a chave. Re-conceda. | Imagem **cinza**, texto "AOD unavailable" e interruptor **desabilitado**, que não responde ao toque; a tela fica aberta até o usuário sair; a chave não muda | | |
| T6 | N6 | Com o app em repouso (sem toque, gatilho fechado): `adb shell dumpsys alarm \| grep cc.floresta.aodtoggle` e `adb shell dumpsys jobscheduler \| grep cc.floresta.aodtoggle`; também `adb shell dumpsys activity services cc.floresta.aodtoggle`. | Os dois `grep` não retornam nada; nenhum alarme, job ou serviço em primeiro plano do pacote. Um bind transitório do sistema em `AodComplicationService` no `dumpsys activity services` não é trabalho em segundo plano do app e não é falha | | |
| T7 | N6 | Fora do carregador, com a complication no mostrador **ativo**: `adb shell dumpsys batterystats --reset`; deixe ~1 h (tela como de costume); reconecte o adb (a conexão cai com a tela apagada) e leia `adb shell dumpsys batterystats \| grep -A30 cc.floresta.aodtoggle` (acionamentos do serviço e CPU). Repita com a complication **removida de todo mostrador**: novo `--reset`, ~1 h, reconectar o adb antes da leitura. | Com a complication: ≤ ~12 acionamentos/h do serviço e CPU desprezível. Sem ela em mostrador nenhum: 0 acionamentos | | Com: ____ /h; sem: ____ |
| T8 | N7 | **No carregador**, mantenha a tela ligada: `adb shell svc power stayon true` (ou "Permanecer ativo" nas opções do desenvolvedor). Com a complication no mostrador, mude o AOD em Configurações e cronometre (é a medida de F2). Ao final, restaure (Restauração final). | A complication acompanha a mudança em ≤ ~5 min (N7) | | Tempo: ____ |

## Restauração final

1. Re-conceda a permissão se estiver revogada: `adb shell pm grant cc.floresta.aodtoggle android.permission.WRITE_SECURE_SETTINGS`.
2. Desfaça a tela mantida ligada da medida de N7: `adb shell svc power stayon false`.
3. Deixe o AOD no estado que o usuário quer (toque na complication ou `adb shell settings put global ambient_enabled <0|1>`).
4. Confirme que concordam:

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
| N1 | F8, F9 (inclui o toque no interruptor) |
| N4 | T1 |
| N5 | T2 |
| N6 | T6, T7 |
| N7 | F2, T8 |
| R12 | F1 |
| R9, R11 | verificados fora desta lista |
| R10 | esta lista |
