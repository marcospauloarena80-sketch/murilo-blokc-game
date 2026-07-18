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
