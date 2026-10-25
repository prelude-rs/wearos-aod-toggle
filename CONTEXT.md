# CONTEXT — glossário do domínio

| Termo | Definição | Evitar |
|---|---|---|
| AOD | Always-On Display: o mostrador continua visível, esmaecido, com o pulso abaixado. Ligado ou desligado pelo usuário em Configurações → Tela. | ambient mode, doze (nomes internos da plataforma) |
| complication | O elemento que o app oferece para o mostrador exibir; mostra o estado do AOD e o alterna ao toque. | widget, tile |
| mostrador | A face do relógio (watch face) que hospeda a complication. | tela inicial |
| ligado / desligado | Os dois estados do AOD como o sistema os reporta. | ativo / inativo |
| indisponível | Estado da complication em que ela não consegue alternar o AOD (falta a permissão ou a chave do AOD não existe). Distinto de desligado. | erro, N/A |
| gatilho | O app "AOD", aberto pela lista de apps ou por um botão físico mapeado; ao abrir, alterna o AOD e mostra o estado com um interruptor. | launcher, atalho |
| interruptor | O controle liga/desliga na tela do gatilho; reflete o estado relido e alterna o AOD ao toque. | toggle, switch (nomes de código) |
| imagem monocromática | A forma da complication que o mostrador pinta com a cor do tema dele (tipo `MONOCHROMATIC_IMAGE`); o estado aparece pela forma (sólido, vazado, tarja), não pela cor. | silhueta, ícone tingido |
| cor do tema | A cor de destaque escolhida no mostrador, aplicada por ele às imagens monocromáticas. | accent color, cor do relógio |
| tarja | O traço diagonal, com uma folga transparente em volta, que marca o estado indisponível na imagem monocromática. | risco, barra |
