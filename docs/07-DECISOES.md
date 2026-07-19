# 07 — Registro de Decisões Técnicas (ADRs)

Formato curto: contexto → decisão → consequências. Toda decisão nova entra aqui **antes** de virar código. Nenhuma decisão vive só na memória de conversa.

## ADR-001 — Engine: Godot 4.7.x
- **Contexto:** jogo 3D voxel, navegador primeiro, depois desktop/mobile; prioridade em maturidade, custo zero, sem lock-in. Matriz completa em [03-ENGINE-DECISAO.md](03-ENGINE-DECISAO.md).
- **Decisão:** Godot 4.7.x estável, versão travada.
- **Consequências:** export web ~35MB aceito; upgrades de engine só conscientes, entre fases, com testes verdes.

## ADR-002 — Perspectiva: 3D voxel low-poly
- **Contexto:** visão do jogo é Minecraft+Roblox (ambos 3D). Alternativas 2D seriam mais rápidas, mas migrar 2D→3D depois = reescrever o jogo. Velocidade não é prioridade declarada.
- **Decisão:** 3D voxel low-poly, câmera 3ª pessoa (escolha do usuário, 2026-07-18).
- **Consequências:** F2 (mundo voxel) vira a fase de maior risco técnico; assets 3D via packs CC0.

## ADR-003 — Linguagem: GDScript tipado, única
- **Contexto:** C# não exporta para web na Godot; GDScript tem o maior corpus para assistência de IA e iteração mais rápida.
- **Decisão:** GDScript com tipagem estática obrigatória (warnings de tipo promovidos a erro).
- **Consequências:** disciplina de tipos via config + gdlint no CI; sem mistura de linguagens.

## ADR-004 — Renderer: Compatibility (WebGL2) + build single-thread
- **Contexto:** navegador é a plataforma principal; Forward+ não roda na web; iOS/Safari restringe threads.
- **Decisão:** renderer Compatibility em todas as plataformas; export web single-threaded.
- **Consequências:** visual low-poly estilizado (combina com a direção de arte); meshing precisa de time-slicing (sem worker threads).

## ADR-005 — Mundo finito pequeno (128×128×64), sem streaming infinito
- **Contexto:** mundo infinito exige streaming/geração contínua — complexidade e risco de performance enormes na web, sem ganho para um jogo pessoal com progressão dirigida (biomas em anéis, Arenas).
- **Decisão:** mundo finito 8×8 chunks (16×16×64), gerado por seed no primeiro load.
- **Consequências:** save leve (delta), mapa-múndi conhecido, level design possível (vilarejo/Arenas em posições planejadas). Plano B de tamanho em [Riscos R2](06-RISCOS.md).

## ADR-006 — Save: JSON versionado local, delta sobre seed
- **Contexto:** save local exigido (sem nuvem); mundo é derivável da seed; JSON é debugável e migrável.
- **Decisão:** `user://saves/slot1.json` com `schema_version`, seed + dicionário de blocos editados + estado do jogador/inventários/criaturas/missões; migradores encadeados desde a v1; backup automático do save anterior.
- **Consequências:** na web o `user://` persiste em IndexedDB automaticamente; limpar dados do navegador apaga o save (aceito e documentado); freeze de schema na 1.0.

## ADR-007 — Batalha por turnos 1×1
- **Contexto:** batalha em tempo real no mundo voxel = câmera, hitboxes e balanceamento muito mais caros; turnos são o padrão consagrado do gênero de captura.
- **Decisão:** batalha por turnos em cena-arena separada, mundo pausado; lógica 100% pura em `core/battle/`.
- **Consequências:** balanceamento simulável em testes automatizados; animações são só apresentação.

## ADR-008 — Conteúdo data-driven via Resources (.tres)
- **Contexto:** adicionar bloco/receita/criatura/missão não pode exigir tocar código (escalabilidade exigida).
- **Decisão:** `BlockDef`, `ItemDef`, `RecipeDef`, `CreatureDef`, `AttackDef`, `BiomeDef`, `QuestDef` como Resources tipados em `data/`.
- **Consequências:** balanceamento = editar arquivos; validação de dados entra na suite de testes (ex.: toda receita referencia itens existentes).

## ADR-009 — Assets: packs CC0 adaptados, nunca IPs oficiais
- **Contexto:** proibido copiar Minecraft/Roblox/Pokémon; modelar do zero é caro demais.
- **Decisão:** Kenney/KayKit/Quaternius (CC0) como base, adaptados para estilo low-poly uniforme; texturas/UI geradas por IA quando útil; universo 100% próprio (Vale Dourado, Cubelins).
- **Consequências:** direção de arte definida pelo que os packs cobrem bem (low-poly chanfrado, cores chapadas).

## ADR-010 — Sem multiplayer, sem nuvem, sem monetização até a 1.0
- **Contexto:** jogo pessoal; cada um desses eixos multiplica a complexidade.
- **Decisão:** single-player local até a 1.0. Arquitetura não bloqueia multiplayer futuro (lógica pura + sinais), mas nada é construído para ele.
- **Consequências:** P4 do backlog guarda as ideias; nenhuma decisão de código a serviço de multiplayer especulativo (YAGNI).

## ADR-011 — Testes: lógica pura + GUT headless no CI
- **Contexto:** testar cena/física na web é frágil; regras de jogo têm que ser confiáveis (save, craft, batalha).
- **Decisão:** toda regra em `core/` (RefCounted puro) coberta por GUT; CI roda `--headless` a cada push; cenas testadas por smoke manual roteirizado por fase.
- **Consequências:** disciplina de separar lógica de apresentação em todos os sistemas (ver [Arquitetura](02-ARQUITETURA.md)).

## ADR-013 — Hosting do build web: GitHub Actions artifact + deploy opcional itch.io
- **Contexto:** F1 exige export web verificável a cada push; criar conta/página em serviço externo (itch.io) é ação que exige o dono da conta, não a IA.
- **Decisão:** CI sempre publica o build web como artifact do GitHub Actions (baixável, sem depender de serviço externo). Deploy automático para itch.io via `butler` fica pronto no workflow, mas **desativado** até o usuário criar a página itch.io e adicionar o secret `BUTLER_API_KEY`.
- **Consequências:** F1 fecha sem bloquear em conta externa; ativar itch.io é 1 secret + trocar `itchUsername`/`itchGameId` no [ci.yml](../.github/workflows/ci.yml), sem mexer no resto do pipeline.

## ADR-012 — Craft por lista de receitas (sem grid de posicionamento)
- **Contexto:** grid estilo Minecraft exige descoberta por tentativa e UI complexa; lista estilo livro de receitas é mais direta, mais acessível e trivial de testar.
- **Decisão:** UI de craft em lista com receitas destacadas quando os ingredientes existem.
- **Consequências:** receitas novas aparecem automaticamente; descoberta vem de desbloqueios (bancada, insígnias), não de adivinhação.

## ADR-014 — Player espera o mundo terminar de gerar antes de ligar a física
- **Contexto:** bug real encontrado na F2 — o meshing time-sliced (2 chunks/frame) tem custo de CPU real por chunk, então o clock de física (60Hz fixo) avança mais rápido que o idle process consegue mesh+colisão dos 64 chunks. O player caía do spawn e atravessava toda a coluna de terreno sólido (chegava a y≈0,9 em vez de parar na superfície ~y=32), porque a colisão do próprio chunk ainda não existia quando ele chegava lá. Descoberto via prints de debug comparando dados do mundo (corretos) com a física real (furava tudo).
- **Decisão:** `Player._ready()` chama `set_physics_process(false)` imediatamente; só liga (`set_physics_process(true)`) quando `ChunkManager.mundo_gerado` dispara (ou de imediato se o mundo já estiver pronto).
- **Consequências:** pequena pausa (imperceptível para mundo 8x8 chunks) antes do jogador começar a cair/andar; zero risco de atravessar geometria não meshada. Teste de regressão em `tests/integration/test_player_world_ready_gate.gd`. Se o mundo crescer (fases futuras), reavaliar se o tempo de espera incomoda — mitigação seria priorizar meshing dos chunks perto do spawn primeiro.

## ADR-015 — Personagem blocky procedural + customização só de cor (F3)
- **Contexto:** usuário pediu customização de personagem "que nem Minecraft e Roblox" — não estava no GDD original. Baixar/adaptar um pack de personagem animado (rig, skeleton, animações) é trabalho pesado de asset pipeline; a fase de assets (ADR-009) ainda não começou.
- **Decisão:** (1) modelo do Murilo é **blocky, montado com primitivas da própria Godot** (BoxMesh por parte: cabeça/cabelo/tronco/braços/pernas) — sem depender de pack externo nesta fase; (2) animação de membros é **procedural** (rotação de nós por código, sem Skeleton3D/AnimationPlayer) — balanço de braço/perna proporcional à velocidade horizontal; (3) customização é **só cor** (pele/cabelo/camisa/calça, paleta fixa por categoria), sem itens equipáveis — isso fica pro backlog P4, como recompensa das Arenas (F10); (4) aparência mora em `GameState.aparencia_atual` (reaproveita autoload existente, não cria um 6º).
- **Consequências:** F3 continua risco baixo (cor é troca de material, não geometria variável); visual "blocky" combina com o nome do jogo e o mundo voxel; troca pra modelos com rig de verdade fica para quando a fase de assets (CC0) começar, sem quebrar a arquitetura (o método `aplicar_aparencia()` do player isola quem aplica cor de como o modelo é montado).

## ADR-016 — Coleta vai pra mochila, hotbar só por transferência manual (F4)
- **Contexto:** `GameState` tem dois `InventoryModel` (hotbar 8 + mochila 24). Craft precisa ler ingredientes de UM inventário fixo (o `CraftService` já testado opera sobre um único `InventoryModel`, não uma view combinada). Se materiais minerados caíssem direto na hotbar, craftar exigiria checar os dois inventários toda hora, complicando `CraftService` sem ganho real.
- **Decisão:** `GameState.adicionar_item()` (chamado pelo `ItemDrop` na coleta) enche a **mochila primeiro**, hotbar só recebe o excedente se a mochila lotar. A tela de inventário (`inventory_screen.gd`) deixa clicar num slot da mochila pra mover 1 stack inteiro pra hotbar via `GameState.mover_para_hotbar()`. Craft (`CraftService`) sempre opera sobre `GameState.inventario_mochila`; `tem_bancada()` continua checando os dois (ter a bancada em qualquer lugar já libera as receitas tier 2).
- **Consequências:** loop de jogo fica: minerar → material cai na mochila → craftar na mochila → mover ferramenta/bloco pronto pra hotbar → usar. Um passo a mais de UI (clicar pra mover) comparado a ferramentas irem direto pra hotbar, mas mantém `CraftService` simples e já testado sem reescrever. Reavaliar na F6 (baús) se esse fluxo incomodar no uso real com o Murilo.

## ADR-017 — Dano de queda, morte e respawn via cama (F6)
- **Contexto:** GDD pede "morte com drop recuperável" mas Cubelins hostis só chegam na F7 — F6 precisa de uma fonte de morte própria. Cama já existia como bloco (`tipo_especial = "cama"`) sem função. Faltava decidir: o que causa dano, o que a morte dropa, e onde o jogador reaparece.
- **Decisão:** (1) **dano de queda** é a fonte de morte da F6 — `Player` rastreia a altura em que o ar começou (`_y_inicio_queda`) e, ao pousar (`is_on_floor()` volta a `true`), aplica `max(0, altura_caída − 3 blocos)` de dano, 1 ponto de vida por bloco excedente, arredondado pra baixo; só se aplica no estado `PLAYING` (não durante o assentamento da criação de personagem). (2) **morte** dropa **toda a mochila** no local da morte (um `ItemDrop` por slot ocupado, mesma cena usada pra drop de bloco), zera a mochila, restaura `vida_atual = vida_maxima` e teleporta o jogador pra `GameState.ponto_respawn` — a **hotbar não é tocada** (consistente com ADR-016: ferramentas/blocos já transferidos manualmente ficam seguros). (3) **cama define o respawn**: apertar `interagir` (E) mirando um bloco com `tipo_especial == "cama"` grava `GameState.ponto_respawn`; sem cama, o padrão é o centro do mundo (`Vector3(64,45,64)`). `ponto_respawn` agora é persistido no save (`salvar_jogo()`/`_ao_continuar()`), senão a cama "esqueceria" ao continuar o jogo.
- **Consequências:** morte nunca é permanente nem punitiva além de perder o trajeto de volta até o local da queda — itens ficam recuperáveis (`ItemDrop` já tem tempo de vida de 300s e ímã de coleta). Sem XP/Cubelins na F6, não há mais nada a perder. Quando Cubelins hostis chegarem (F7), a mesma `_processar_morte()` deve ser reaproveitada como fonte de morte adicional — só muda o que dispara `_verificar_morte()`.

## ADR-018 — Baú: inventário por posição, aberto via "interagir", tela dupla
- **Contexto:** `GameState.baus` (Dictionary "x,y,z" → `InventoryModel(24)`) e `GameState.obter_bau()`/`chave_posicao()` já existiam como scaffold sem uso real nem testes. Faltava decidir como abrir o baú, como transferir itens, e o que acontece se o bloco for quebrado.
- **Decisão:** (1) mirar um bloco `tipo_especial == "bau"` e apertar `interagir` (E) emite `EventBus.chest_requested(chave)` — novo sinal (2 sistemas: `Player` emite, `ChestScreen` escuta, dentro da regra do `event_bus.gd`); (2) `ChestScreen` (nova tela, mesmo padrão de `InventoryScreen`: `CanvasLayer` com grids construídos em `_ready()`, sem simular clique nos testes) mostra **duas grids lado a lado** — baú (24 slots) e mochila (24 slots) — clicar num slot move o stack inteiro pro outro lado (`_mover_stack`, usa só a API pública de `InventoryModel`, sem tocar a classe pura); abrir pausa o jogo (reaproveita `GameState.PAUSED`, igual `InventoryScreen`); (3) `baus` é serializado no save (`main.gd._serializar_baus()` / `menu.gd._dicionario_para_baus()`) — cada `InventoryModel` vira `Array` via `.serializar()`, senão o baú "esqueceria" o conteúdo ao continuar o jogo; (4) quebrar um bloco baú dropa **todo o conteúdo armazenado** como `ItemDrop`s (reaproveitando `LootSpawner`, que já escuta `block_broken`) e remove a entrada de `GameState.baus` — mesma filosofia "recuperável" da morte (ADR-017), nunca perda silenciosa.
- **Consequências:** baú vira armazenamento persistente de verdade (sobrevive a save/continue), sem exigir uma classe de UI nova além do padrão já estabelecido em F4. Quebrar um baú cheio nunca deleta itens — sempre vira drop no chão. Se baús ficarem populares no uso real com o Murilo, o próximo ajuste natural seria permitir nomear/colorir baús — fora de escopo da F6.

## ADR-019 — Tocha: luz reage a block_placed/block_broken, sem sistema novo
- **Contexto:** `BlockDef.emite_luz` já existia (scaffold sem uso) e `tocha.tres` já tinha `emite_luz = true`. `ChunkManager.set_block()` já emite `EventBus.block_placed`/`block_broken` pra todo bloco colocado/quebrado (usado hoje só por `LootSpawner`). Faltava decidir só onde a luz mora e como ela sobrevive ao save.
- **Decisão:** novo `TorchLightManager` (`systems/torch_light_manager.gd`, mesmo padrão de `LootSpawner`: `Node3D` que só escuta `EventBus`, sem lógica de mundo própria) escuta `block_placed` — se `BlockDef.emite_luz`, cria um `OmniLight3D` filho na posição do bloco — e `block_broken` — remove a luz daquela posição se existir. Rastreio por `GameState.chave_posicao()` num Dictionary interno (mesma chave usada pelos baús). **Nenhuma persistência própria**: como `ChunkManager.aplicar_delta()` (chamado ao continuar) já re-chama `set_block()` pra cada edição salva, tochas salvas re-emitem `block_placed` sozinhas e a luz reacende de graça — sem precisar salvar nada extra no JSON.
- **Consequências:** zero acoplamento novo (Player não sabe que tochas dão luz; `ChunkManager` não sabe que luzes existem). Bloqueio de spawn de criaturas perto de tocha (mecânica clássica de "luz afasta hostis") fica pra F7, quando Cubelins hostis existirem — hoje não há o que bloquear. Se no futuro blocos com luz também precisarem sobreviver a um `queue_free` de chunk inteiro (ex.: um sistema de descarregar chunks distantes), reavaliar — hoje o mundo é fixo 8×8 e nunca descarrega (ADR-005).
