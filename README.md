# mengazo-horizon

**Português** · [English](README.en.md)

Marcadores do mapa projetados no horizonte. O jogador segura a tecla (padrão `J`), o jogo desfoca e os blips próximos aparecem na direção real em que estão. Mirando em um marcador, abre o card com nome, localização e distância, e ele pode definir o destino (clique esquerdo) ou abrir o mapa nele (clique direito).

## Instalação

1. Adicione `ensure mengazo-horizon` no `resources.cfg`.
2. A interface já vai buildada em `web/build`. Para alterar: `npm ci --prefer-offline` e `npm run build` dentro de `web/`.

## Idioma

Os textos vêm em inglês. Para português, coloque `LANGUAGE = 'pt-BR'` no `config/config.lua`, ou edite os textos em `config/lang.lua`.

## De onde vêm os marcadores

| Origem | Como |
| --- | --- |
| Blips do mapa | Lidos automaticamente (`SCAN_GAME_BLIPS`), sem configurar nada: nome real do blip, cor do blip e rua/bairro da posição |
| Ajuste opcional de um blip | `exports['mengazo-horizon']:setBlipDetails(blip, { label, description, icon, color, image, priority, hidden })` |
| Ponto sem blip (client) | `exports['mengazo-horizon']:registerPoint(id, { coords, label, description, icon, color, image, priority })` |
| Ponto por jogador (server) | `exports['mengazo-horizon']:setPlayerPoint(source, id, dados)` e `removePlayerPoint(source, id)` |
| Pontos fixos | `CUSTOM_POINTS` no config |

`priority` maior aparece na frente dos demais (objetivo de missão, por exemplo). `image` é o avatar exibido no card.

## Como o nome real do blip é capturado

O jogo não tem native que devolva o nome de um blip como texto, mas tem `AddTextComponentSubstringBlipName(blip)`, que injeta esse nome em um texto desenhado pelo próprio jogo. Por isso o título do card dos blips é desenhado pelo jogo (fonte `TITLE_FONT`) em uma janela aberta no card da interface; o restante do card é NUI.

Ordem do nome: `label` do `setBlipDetails` → nome real do blip → nome padrão do jogo para o sprite (`BLIP_<sprite>`) → `DEFAULT_LABEL` (em `config/lang.lua`, ou em `config/config.lua` para sobrescrever).

Se o texto ficar desalinhado na vertical, ajuste `TITLE_OFFSET_Y`.

## Exports (client)

`registerPoint`, `removePoint`, `setBlipDetails`, `clearBlipDetails`, `openHorizon`, `closeHorizon`, `isHorizonActive`

## Eventos (client)

| Evento | Parâmetros |
| --- | --- |
| `mengazo-horizon:opened` | |
| `mengazo-horizon:closed` | |
| `mengazo-horizon:destinationChanged` | `pointId` (nil ao remover), `coords` |
| `mengazo-horizon:viewedOnMap` | `pointId`, `coords` |

## Exemplo: descrição e ícone próprios em um blip

```lua
local blip = AddBlipForCoord(x, y, z)

exports['mengazo-horizon']:setBlipDetails(blip, { description = 'Atendimento 24 horas.', icon = 'medical' })
```

## Ícones disponíveis

`pin`, `store`, `weapon`, `car`, `garage`, `medical`, `police`, `money`, `home`, `star`, `flag`, `tool`, `user`, `work`

Esses ícones valem para pontos registrados e para sprites sem imagem. Os blips do mapa usam o desenho real do sprite, pintado com a cor do blip (`USE_BLIP_IMAGES`). As imagens ficam em `web/public/blips/<sprite>.png` e vieram da referência de blips do docs.fivem.net; para adicionar um sprite novo, coloque o arquivo lá, inclua o id em `web/src/lib/blipSprites.ts` e rode o build.

## Licença

Código sob a licença MIT (veja `LICENSE`). As imagens em `web/public/blips` são os ícones de blip do GTA V, propriedade da Rockstar Games, obtidos da referência de blips do docs.fivem.net, e não estão cobertas pela licença MIT.
