# Lista de verificação manual no relógio

Verifica R10 de `2026-10-aod-toggle-complication`: roda no OnePlus Watch 3 real, por adb sobre Wi-Fi, em **dois mostradores** (Gravity e um segundo que aceite `SMALL_IMAGE`). Os resultados são copiados para o `evidence.md` da change.

Cobre R1–R8, R12, N1, N6 e N7 (N8 foi retirado). R9 (testes de unidade) e R11 (README) são verificados em outro lugar (`./gradlew testDebugUnitTest` e o próprio README); R10 é esta lista.

## Cabeçalho

- Roda sobre o **release** `rs.prelude.aodtoggle` (rótulo "AOD"), assinado com o keystore do autor. Sem keystore o release sai `unsigned` e o relógio recusa a instalação: registre isso como **bloqueio**, não como OK.
- Antes de tudo, desinstale o pacote antigo: `adb uninstall cc.floresta.aodtoggle` e, se houver, o debug antigo: `adb uninstall cc.floresta.aodtoggle.debug` (nomes usados antes de 2026-10-25).
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
| 0a | Premissa 1, Risco 1 (prova automatizada) | **Antes** de desinstalar o debug: `./gradlew installDebug`, `adb shell pm grant rs.prelude.aodtoggle.debug android.permission.WRITE_SECURE_SETTINGS`, `./gradlew connectedDebugAndroidTest` | Testes instrumentados passam (app lê e escreve a chave). Falha de asserção em leitura ou escrita **com a concessão feita**: reabre a spec. Erro de arnês (conexão, instalação, "harness: pm grant failed"): reconecte e rode de novo | | |
| 0b | Premissa 1, R4 | Desinstale o pacote antigo (`adb uninstall cc.floresta.aodtoggle` e, se houver, `cc.floresta.aodtoggle.debug`; nomes usados antes de 2026-10-25) e o debug: `adb uninstall rs.prelude.aodtoggle.debug`. Instale o release e conceda: `adb install -r app/build/outputs/apk/release/app-release.apk` e `adb shell pm grant rs.prelude.aodtoggle android.permission.WRITE_SECURE_SETTINGS`. Confirme só um provedor/app "AOD": `adb shell pm list packages \| grep aodtoggle` | Só `package:rs.prelude.aodtoggle`. Erro de instalação ou de `pm grant` é problema de arnês (corrija e repita), não da premissa | | |
| 0c | Premissa 1, R4 | `adb shell settings get global ambient_enabled` (anote N). Ponha a complication "AOD Toggle" em um mostrador (README, "Use it") e toque nela. Repita o `settings get`. | O valor passa de N para 1-N (0 ↔ 1). Só leitura ou escrita negada ao app (com a concessão feita) reabre a spec | | |

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
| F1 | R1, R12 | Abra a edição do mostrador e o seletor do espaço de imagem. Veja o cabeçalho e a entrada da complication; em cada espaço de imagem, veja a arte com AOD ligado, desligado e (item F3) sem permissão. | O seletor lista **"AOD Toggle"** sob o cabeçalho "AOD" (R12), **só** como imagem. arte N1 (O em forma de relógio), sem aro, em branco (desligado), âmbar (ligado) e cinza (indisponível) — R1. A imagem não é recortada nem retingida e é legível (Review Focus; Riscos). | | |
| F2 | R2, N7 | Com a **tela ligada**, mude o AOD em Configurações > Tela (ligado, depois desligado) e volte ao mostrador sem tocar na complication. Cronometre até a complication acompanhar a mudança. Pode ser feito na medida de N7 (item T8, no carregador, tela mantida ligada). | Âmbar com AOD ligado, branco com desligado, em ≤ ~5 min (N7); registre o tempo de cada mudança. | | Tempos: ____ / ____ |
| F3 | R3 | `adb shell pm revoke rs.prelude.aodtoggle android.permission.WRITE_SECURE_SETTINGS`, recoloque a complication (ou recarregue o mostrador), **sem tocar**. | Cinza já ao aparecer, mesmo com o estado legível | | |
| F4 | R6 | Com a complication cinza, `adb shell pm grant rs.prelude.aodtoggle android.permission.WRITE_SECURE_SETTINGS`; anote `adb shell settings get global ambient_enabled`; toque na complication cinza; releia a chave. | Passa a branco/âmbar conforme o AOD, sem reinstalar; a chave não muda | | |
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
| T3 | R7 | Em Configurações do relógio, mapeie o botão físico ao app "AOD" (README, "Use it"; o caminho do menu varia). Com permissão, pressione o botão 2 vezes; depois, com a tela do gatilho aberta, (a) toque no interruptor, (b) pressione o botão mapeado de novo, (c) apague a tela. | O app "AOD" aparece na lista do app e do mapeamento do botão. Cada pressão alterna o AOD (Configurações acompanha) e mostra a imagem "AOD" e o interruptor "AOD" no novo estado; a tela **fica aberta** até o usuário sair (o outro botão, voltar/home, ou deslizar). (a) Tocar no interruptor alterna o AOD de novo, e imagem e interruptor passam ao estado relido. (b) Pressionar o botão mapeado com a tela aberta alterna de novo. (c) Apagar a tela: a tela some, ou continua aberta mostrando o estado atual (sem alternar); a próxima pressão do botão mapeado alterna (`evidence.md` § Rulings, R14). Se o botão não aceitar o gatilho, R7 não se verifica e a spec é reaberta. | | |
| T4 | R8 | `adb shell pm revoke rs.prelude.aodtoggle android.permission.WRITE_SECURE_SETTINGS`, `adb shell settings get global ambient_enabled`, pressione o botão. Toque no interruptor. Releia a chave. Re-conceda. | Imagem **cinza**, texto "AOD unavailable" e interruptor **desabilitado**, que não responde ao toque; a tela fica aberta até o usuário sair; a chave não muda | | |
| T6 | N6 | Com o app em repouso (sem toque, gatilho fechado): `adb shell dumpsys alarm \| grep rs.prelude.aodtoggle` e `adb shell dumpsys jobscheduler \| grep rs.prelude.aodtoggle`; também `adb shell dumpsys activity services rs.prelude.aodtoggle`. | Os dois `grep` não retornam nada; nenhum alarme, job ou serviço em primeiro plano do pacote. Um bind transitório do sistema em `AodComplicationService` no `dumpsys activity services` não é trabalho em segundo plano do app e não é falha | | |
| T7 | N6 | Fora do carregador, com a complication no mostrador **ativo**: `adb shell dumpsys batterystats --reset`; deixe ~1 h (tela como de costume); reconecte o adb (a conexão cai com a tela apagada) e leia `adb shell dumpsys batterystats \| grep -A30 rs.prelude.aodtoggle` (acionamentos do serviço e CPU). Repita com a complication **removida de todo mostrador**: novo `--reset`, ~1 h, reconectar o adb antes da leitura. | Com a complication: ≤ ~12 acionamentos/h do serviço e CPU desprezível. Sem ela em mostrador nenhum: 0 acionamentos | | Com: ____ /h; sem: ____ |
| T8 | N7 | **No carregador**, mantenha a tela ligada: `adb shell svc power stayon true` (ou "Permanecer ativo" nas opções do desenvolvedor). Com a complication no mostrador, mude o AOD em Configurações e cronometre (é a medida de F2). Ao final, restaure (Restauração final). | A complication acompanha a mudança em ≤ ~5 min (N7) | | Tempo: ____ |

## Complication monocromática (`2026-10-complication-monochrome`)

Verifica R8 desta change: a complication também responde como `MONOCHROMATIC_IMAGE` (cor do tema do mostrador; estado pela forma: ligado sólido, desligado com A e D vazados e relógio a 60%, indisponível = desligado cortado por tarja diagonal com folga transparente), e o `SMALL_IMAGE` não muda (R5). Roda no relógio real, por adb, em **dois mostradores**: um que usa a monocromática (Chic) e um que usa o `SMALL_IMAGE` (Gravity, se a lista dele permitir). Os resultados (mostradores, tipo usado em cada um, data, cada item OK/falha/bloqueio) vão para o `evidence.md` da change.

Cobre R1–R6, N1, N4, N5 e N6 desta change. R7 (testes de unidade) é verificado por `./gradlew testDebugUnitTest`; R8 é esta lista. Os itens abaixo se somam aos de cima, que ficam como estão. Os IDs com prefixo `M` são desta change.

Pode rodar sobre o debug (`rs.prelude.aodtoggle.debug`, complication "AOD Toggle (debug)"; `./gradlew installDebug` e `pm grant` do README, "Development") ou sobre o release (`rs.prelude.aodtoggle`, "AOD Toggle"); nos comandos abaixo troque o pacote conforme o caso. Debug e release podem coexistir (applicationId diferente); recomenda-se testar um por vez, para só um provedor "AOD Toggle" aparecer no seletor.

**Slots já configurados mantêm o tipo escolhido antes da atualização** (o mostrador escolhe o tipo uma vez, ao configurar). **Antes de verificar, remova a complication de cada slot e recoloque-a.**

Registro (preencha):

| Campo | Valor |
|---|---|
| Data | ____ |
| Pacote testado (debug / release) | ____ |
| Lista de tipos do Chic (slots 1–3) | `GOAL_PROGRESS, RANGED_VALUE, SHORT_TEXT, MONOCHROMATIC_IMAGE, SMALL_IMAGE` (lida por adb em 2026-10-25) |
| Lista de tipos do Gravity | ____ (preencher na execução, pelo M0; hoje só se sabe que aceita `SMALL_IMAGE`) |
| Tipo usado pela complication no Chic | ____ |
| Tipo usado pela complication no Gravity | ____ |
| Mostrador que usa `SMALL_IMAGE` (ou "nenhum") | ____ |

### M0 — Ler a lista de tipos de cada mostrador (primeiro)

Mesma leitura da seção "Verificação do segundo mostrador", com o mostrador ativo e repetida para cada um:

```sh
adb shell dumpsys wallpaper | grep mWallpaperComponent        # componente do mostrador ativo
adb shell dumpsys activity service <pacote/serviço do mostrador> | grep supportedTypes
```

Registre, por mostrador e por slot, a ordem da lista de tipos e **qual tipo a complication usa** (o primeiro da lista que o app também declara, `MONOCHROMATIC_IMAGE` ou `SMALL_IMAGE`; confira também no próprio relógio pela cor da complication). Se o filtro `supportedTypes` não mostrar nada, tente `grep -i MONOCHROMATIC_IMAGE`.

**Risco 4 (fallback):** se nenhum dos dois mostradores usar o `SMALL_IMAGE` depois da mudança (ambos preferem a monocromática), procure outro mostrador cujos slots só aceitem `SMALL_IMAGE`. Se não houver, R5 (e o lado colorido de R1) se apoia nos testes de unidade das cores (`testDebugUnitTest`), e **esta lista registra esse fato** no `evidence.md`.

### Itens no mostrador monocromático (Chic)

Estado inicial: complication recolocada num slot de imagem, permissão concedida.

| ID | Verifica | Passo | Esperado | Resultado | Observação |
|---|---|---|---|---|---|
| M1 | R1 | Abra a edição do Chic, escolha um slot de imagem e a complication "AOD Toggle". Veja o resultado no mostrador. | Aparece na **cor do tema**, não âmbar nem branca. Nenhum slot que hoje mostra a complication deixa de mostrá-la (teste os slots 1–3) | | |
| M2 | R2 | Com o AOD ligado (`adb shell settings get global ambient_enabled` = 1), olhe a complication. | A, relógio e D **cheios**, na cor do tema | | |
| M3 | R3, Risco 2, Risco 5 | Com o AOD desligado (valor 0), olhe a complication. | A e D **vazados** (só o contorno) e relógio esmaecido (~60%); distinguível do ligado (M2) a olho. Letras legíveis no tamanho do slot. Se o mostrador ignorar a opacidade e o relógio sair cheio, o desligado ainda difere pelas letras vazadas: registre. Se ligado e desligado ficarem indistinguíveis, a spec é reaberta | | |
| M4 | R4 | `adb shell pm revoke <pacote> android.permission.WRITE_SECURE_SETTINGS`, recoloque a complication (ou recarregue o mostrador), sem tocar. | Desenho do desligado **cortado por tarja diagonal** com folga transparente; distinguível do desligado (M3) a olho | | |
| M5 | R6 | Com permissão, toque na complication desligada, depois na ligada. Após cada toque: `adb shell settings get global ambient_enabled` e o interruptor em Configurações > Tela. | A chave e o interruptor alternam; a forma muda (sólido ↔ vazado) | | |
| M6 | R6 | Indisponível (M4): `adb shell pm grant <pacote> android.permission.WRITE_SECURE_SETTINGS`; anote a chave; toque na complication com tarja; releia a chave. | Redesenha para sólido ou vazado conforme o AOD, **sem alternar** (a chave não muda) | | |
| M7 | R6 | Com a tela ligada, mude o AOD em Configurações > Tela e volte ao mostrador sem tocar na complication. Cronometre. | A forma acompanha a mudança em ≤ ~5 min; registre o tempo | | Tempo: ____ |
| M8 | N1 | Meça do toque até a nova forma visível (cronômetro ou `adb shell screenrecord /sdcard/m8.mp4` e contagem de quadros). 3 toques; registre cada tempo. | ≤ 1 s. Passar de 1 s é falha de N1 neste mostrador | | Tempos: ____ / ____ / ____ |
| M9 | N5 | `adb logcat -c && adb logcat -s AodToggle`. Com permissão, alterne 2 vezes na complication monocromática. Depois, `pm revoke` e toque. Re-conceda. | Caminho feliz: nenhuma linha. Indisponível por permissão: ≥1 linha na tag `AodToggle` | | |

### Itens no mostrador que usa `SMALL_IMAGE` (preservação, R5)

Mostrador: **Gravity** (se a lista lida no M0 puser `SMALL_IMAGE` antes da monocromática ou sem ela) ou outro cujo slot só aceite `SMALL_IMAGE`. Complication recolocada, permissão concedida. Se não existir tal mostrador, marque M10–M11 como "n/a: sem mostrador com `SMALL_IMAGE`" e aponte o relatório do `testDebugUnitTest` (Risco 4).

| ID | Verifica | Passo | Esperado | Resultado | Observação |
|---|---|---|---|---|---|
| M10 | R1, R5 | Com a complication no slot, alterne o AOD (ligado, desligado) e veja as cores. | Âmbar ligado, branca desligado, como antes; arte cheia, sem recorte nem retinta | | |
| M11 | R5, R6 | `pm revoke` e recoloque a complication; depois `pm grant`, anote a chave (`adb shell settings get global ambient_enabled`), toque na cinza e releia a chave. | Cinza com permissão revogada. Após o toque, a chave **fica igual** (não alterna) e a complication redesenha para branca (AOD desligado) ou âmbar (ligado) conforme a chave | | |

### Itens independentes de mostrador

| ID | Verifica | Passo | Esperado | Resultado | Observação |
|---|---|---|---|---|---|
| M12 | N4 | `$ANDROID_HOME/build-tools/<versão>/aapt dump permissions app/build/outputs/apk/release/app-release.apk` (como T1) com o APK desta change. | Lista só `android.permission.WRITE_SECURE_SETTINGS` | | |
| M13 | N6 | Como T6, com o app em repouso: `adb shell dumpsys alarm \| grep <pacote>` e `adb shell dumpsys jobscheduler \| grep <pacote>`. | Nenhuma linha: nenhum alarme ou job do pacote | | |
| M14 | N6 | Como T7, com a complication **monocromática** no mostrador ativo: `adb shell dumpsys batterystats --reset`; ~1 h; reconecte o adb; `adb shell dumpsys batterystats \| grep -A30 <pacote>`. | Acionamentos do serviço na mesma ordem dos medidos com o `SMALL_IMAGE` (≤ ~12/h), CPU desprezível | | Acionamentos: ____ /h |

### Cobertura desta change

| Spec | Itens |
|---|---|
| R1 | M0, M1, M10 |
| R2 | M2 |
| R3 | M3 |
| R4 | M4 |
| R5 | M10, M11 (ou testes de unidade, se o Risco 4 se aplicar) |
| R6 | M5, M6, M7, M11 |
| R7 | verificado fora desta lista (`testDebugUnitTest`) |
| R8 | esta lista |
| N1 | M8 |
| N4 | M12 |
| N5 | M9 |
| N6 | M13, M14 |
| Risco 1 (perde âmbar/branco no Chic) | M1–M3 (estado lido pela forma) |
| Risco 2 (mostrador ignora opacidade) | M3 |
| Risco 3 (slots mantêm o tipo antigo) | preâmbulo da seção: recolocar a complication antes de verificar |
| Risco 4 (nenhum mostrador usa `SMALL_IMAGE`) | M0 (busca e registro do fato), M10–M11 (n/a + testes de unidade) |
| Risco 5 (letras vazadas finas) | M3 |

## Complication em texto curto (`2026-10-complication-short-text`)

Verifica R8 desta change: a complication também responde como `SHORT_TEXT` (relógio pequeno na cor do tema e o texto "AOD" ligado, "OFF" desligado, "---" indisponível; relógio sólido no ligado, esmaecido a 60% nos outros), antes da imagem monocromática e do `SMALL_IMAGE`, que não mudam (R5). Roda no relógio real, por adb, no **Gravity** e no **Chic**. Os resultados (mostradores, tipo usado em cada um, data, cada item OK/falha/n.a.) vão para o `evidence.md` da change. `<pacote>` como na seção anterior (debug: `rs.prelude.aodtoggle.debug`).

**Antes de verificar, remova a complication do slot e recoloque-a** (o mostrador escolhe o tipo uma vez, ao configurar — Risco 1 da spec).

| ID | Verifica | Passo | Esperado | Resultado | Observação |
|---|---|---|---|---|---|
| S0 | R1 | Em cada mostrador, com a complication recolocada: `adb shell dumpsys wallpaper \| grep mWallpaperComponent`, depois `adb shell dumpsys activity service <pacote/serviço do mostrador> \| grep -o 'lastComplications=.*'`. | O slot da complication traz `ShortTextComplicationData` do `<pacote>`; o seletor lista uma só "AOD Toggle" | | Gravity: ____ / Chic: ____ |
| S1 | R1, R2 | AOD ligado (`adb shell settings get global ambient_enabled` = 1): olhe a complication. | Relógio sólido em cima, na cor do tema; "AOD" embaixo | | |
| S2 | R3 | AOD desligado (valor 0). | Relógio esmaecido; "OFF"; distinguível do ligado a olho | | |
| S3 | R4 | `adb shell pm revoke <pacote> android.permission.WRITE_SECURE_SETTINGS`, recoloque (ou toque) a complication. | Relógio esmaecido; "---"; distinguível do desligado a olho | | |
| S4 | R6 | Com permissão, toque duas vezes; após cada toque, `adb shell settings get global ambient_enabled` e Configurações > Tela. | A chave e o interruptor alternam; o texto troca entre "AOD" e "OFF" | | |
| S5 | R6 | Indisponível (S3): `pm grant`; anote a chave; toque; releia. | Redesenha para "AOD" ou "OFF" conforme a chave, **sem alternar** | | |
| S6 | R6 | Tela ligada no mostrador: mude o AOD em Configurações e volte sem tocar na complication. Cronometre. Confira também `aapt2 dump xmltree --file AndroidManifest.xml app-release.apk \| grep -A1 UPDATE_PERIOD`. | O texto acompanha em ≤ ~5 min; `UPDATE_PERIOD_SECONDS` = 300 | | Tempo: ____ |
| S7 | N1 | Toque e observe. | Novo estado visível em ≤ 1 s | | |
| S8 | N5 | `adb logcat -c && adb logcat -s AodToggle`; alterne 2 vezes; depois `pm revoke` e toque; re-conceda. | Caminho feliz: nenhuma linha; indisponível: ≥1 linha | | |
| S9 | R5 | Num slot que use a imagem monocromática ou o `SMALL_IMAGE` (se houver no relógio), alterne o AOD. Se nenhum slot usar esses tipos, registre "n/a" e aponte `MonochromeFormTest`/`PresentationTest` (`testDebugUnitTest`). | Formas e cores como antes | | |
| S10 | N4, N6 | `aapt dump permissions` do release; `adb shell dumpsys alarm \| grep <pacote>` e `dumpsys jobscheduler \| grep <pacote>`. | Só `WRITE_SECURE_SETTINGS`; nenhum alarme ou job do pacote | | |

### Cobertura desta change

| Spec | Itens |
|---|---|
| R1 | S0, S1 |
| R2 | S1 |
| R3 | S2 |
| R4 | S3 |
| R5 | S9 (ou testes de unidade) |
| R6 | S4, S5, S6 |
| R7 | fora da lista (`testDebugUnitTest`) |
| R8 | esta lista |
| N1 | S7 |
| N4 | S10 |
| N5 | S8 |
| N6 | S10 |
| Risco 1 (slots mantêm o tipo antigo) | preâmbulo: recolocar antes de verificar |
| Risco 2 (relógio esmaecido sutil) | S2 (o texto distingue) |
| Risco 3 (mostrador sem ícone ou texto cortado) | S1–S3 |

## Restauração final

1. Re-conceda a permissão se estiver revogada: `adb shell pm grant <pacote> android.permission.WRITE_SECURE_SETTINGS` (`<pacote>` como na regra da seção anterior: `rs.prelude.aodtoggle` no release, `rs.prelude.aodtoggle.debug` numa rodada com o debug).
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
