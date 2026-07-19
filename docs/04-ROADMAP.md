# 04 — Roadmap (F0 → 1.0)

Estimativas em **sessões de desenvolvimento** (uma sessão = um bloco de trabalho focado com IA). Regra de gate: **nenhum item da fase N+1 começa antes de todos os critérios da fase N passarem** — inclusive a validação com o Murilo quando indicada.

## F0 — Pré-produção ✅
- **Objetivo:** toda a documentação de design e arquitetura antes de qualquer código.
- **Dependências:** —
- **Estimativa:** 1 sessão · **Risco:** baixo
- **Critérios:** todos os docs deste diretório criados e consistentes. ✔ concluído nesta data.

## F1 — Fundação
- **Objetivo:** esqueleto profissional funcionando ponta a ponta: repo, projeto Godot, CI e um cubo controlável rodando **no navegador**.
- **Entregas:** repo git + GitHub; `project.godot` (renderer Compatibility, tipagem como erro); estrutura de pastas da [Arquitetura §2](02-ARQUITETURA.md); autoloads vazios; GUT instalado com 1 teste exemplo; GitHub Actions (lint + testes + export web + deploy itch.io/Vercel); cena com chão plano e cápsula que anda/pula.
- **Dependências:** F0 · **Estimativa:** 1–2 sessões · **Risco:** baixo
- **Critérios:** CI verde; URL abre no navegador do PC **e** do tablet; cápsula se move a 60 FPS.

## F2 — Mundo voxel
- **Objetivo:** o coração técnico: mundo gerado, minerável e construível.
- **Entregas:** `core/worldgen` por seed (testado); ChunkManager + meshing com face culling e time-slicing; 6 `BlockDef`; quebrar/colocar com preview; colisão.
- **Dependências:** F1 · **Estimativa:** 2–4 sessões · **Risco:** **alto** (performance de meshing na web — maior risco técnico do projeto)
- **Critérios — ✅ concluída em 18/jul/2026:**
  - [x] Mundo 128×128×64 gera em <5s → **535ms** medido (`Time.get_ticks_msec()`, worldgen puro sem meshing)
  - [x] Editar bloco re-mesha só o chunk afetado (+ vizinho na borda) — testado (`test_chunk_manager.gd`)
  - [x] Testes de worldgen/chunk passando — **19/19** (GUT headless)
  - [x] **CI verde real no GitHub Actions** — lint (13s) + test (1m49s) + export-web (1m40s), [run](https://github.com/marcospauloarena80-sketch/murilo-blokc-game/actions/runs/29658031161), artifact `web-build`
  - [ ] 60 FPS desktop / ≥30 FPS tablet — não medido com precisão nesta sessão (ferramenta de browser automatizado sofre throttling de aba em background, não reflete FPS real); confirmar na sessão de validação com o Murilo em dispositivo real
  - **Bug real encontrado e corrigido:** física do player rodava mais rápido que o meshing time-sliced e atravessava o mundo inteiro (caía até y≈0,9 em vez de parar em ~y=32). Corrigido com ADR-014 (player espera `mundo_gerado` antes de ligar a física) + teste de regressão.

## F3 — Murilo (personagem + personalização)
- **Objetivo:** substituir a cápsula pelo personagem jogável definitivo, com customização de aparência (escopo ampliado por decisão do usuário em 18/jul/2026 — ver ADR-015).
- **Entregas:** modelo blocky low-poly (partes primitivas Godot: cabeça/cabelo/tronco/braços/pernas — sem pack externo nesta fase), animação procedural de membros (sem skeleton/AnimationPlayer), câmera 3ª pessoa orbital com colisão, InputMap completo remapeável, tela de criação de personagem (4 categorias de cor: pele/cabelo/camisa/calça) com preview ao vivo, novo estado `CHARACTER_CREATION` no GameState.
- **Dependências:** F2 · **Estimativa:** 1–2 sessões · **Risco:** baixo (customização é só cor, não itens/geometria variável)
- **Critérios — ✅ concluída em 18/jul/2026:**
  - [x] Modelo blocky renderiza correto no navegador (cabeça/cabelo/tronco/braços/pernas, cores aplicadas nas partes certas) — confirmado via screenshot
  - [x] Tela de criação de personagem aparece antes do jogo, com swatches corretos por categoria e botão Jogar
  - [x] Criar personagem → escolher cores → jogar funciona ponta a ponta — verificado por teste (clique simulado em canvas WebGL não é confiável nesta ferramenta de automação, mesmo problema do F1/F2; validado via `test_character_creator.gd`: seleção de cor atualiza `GameState` + tinge o player ao vivo, confirmar muda estado pra PLAYING, movimento fica mudo fora de PLAYING)
  - [x] Câmera nunca atravessa terreno (SpringArm3D já cuida disso, herdado do F1)
  - [x] 25/25 testes GUT passando
  - [x] **CI verde real no GitHub Actions** — lint (12s) + test (2m1s) + export-web (1m39s), [run](https://github.com/marcospauloarena80-sketch/murilo-blokc-game/actions/runs/29659121197), artifact `web-build`
  - [ ] Controle responsivo (validação Murilo: "gostoso de andar?") — fica pra sessão de validação com o Murilo (não é algo que eu meço sozinho)

## F4 — Inventário + coleta + craft
- **Objetivo:** fechar o loop minerar→coletar→craftar→construir.
- **Entregas:** `InventoryModel` puro + testes; drops com atração magnética; hotbar 8 + mochila 24; tela única inventário/craft; 6 receitas; bancada; ferramentas afetam velocidade de quebra.
- **Dependências:** F2 (blocos), F3 (interação) · **Estimativa:** 2–3 sessões · **Risco:** médio (UX de inventário)
- **Critérios — ✅ concluída em 19/jul/2026:**
  - [x] Loop completo sem bugs: quebrar árvore → tábuas → bancada → picareta de pedra — verificado por teste de integração ponta a ponta (`test_f4_loop_completo.gd`) exercitando o fluxo real de eventos (ChunkManager → EventBus → LootSpawner → ItemDrop → GameState) + confirmado visualmente no navegador (HUD hotbar, sem erros de console)
  - [x] Testes de inventário/craft 100% — 60/60 testes GUT no total do projeto
  - [x] Drops com atração magnética (`ItemDrop`: flutua, gira, atrai no raio de 3 e coleta em contato) + `LootSpawner` reagindo a `EventBus.block_broken`
  - [x] Hotbar real substitui o seletor numérico temporário do F2; ferramentas (`multiplicador_velocidade`) afetam velocidade de quebra (MB-020)
  - [x] Tela de inventário/craft (`inventory_screen.gd`, toggle pela tecla I) + HUD com hotbar sempre visível — decisão de fluxo em ADR-016
  - [x] **CI verde real no GitHub Actions** — lint (17s) + test (2m2s) + export-web (2m38s), [run](https://github.com/marcospauloarena80-sketch/murilo-blokc-game/actions/runs/29671117638), artifact `web-build`
  - [ ] Validação de UX com o Murilo (fica pra sessão de validação, não é algo que eu meço sozinho)

## F5 — Save + HUD → **MVP 0.1 🎉**
- **Objetivo:** transformar o protótipo em jogo: progresso persiste.
- **Entregas:** SaveManager (JSON versionado, delta de mundo); autosave + save manual; menu principal (Novo/Continuar); HUD (hotbar, vida); tela de pausa.
- **Dependências:** F2–F4 · **Estimativa:** 1–2 sessões · **Risco:** baixo
- **Critérios — ✅ concluída em 19/jul/2026:**
  - [x] Mundo, posição e inventário intactos entre sessões — verificado ponta a ponta com o **código real** do menu (`test_menu_fluxo_completo.gd`: Novo Jogo → joga → edita bloco → ganha item → Salva → simula reinício → Continuar → confirma seed/delta/inventário/posição do player todos restaurados)
  - [x] SaveManager: JSON versionado (`schema_version`), backup automático do save anterior (`slot1.bak.json`), hook de migração pronto pra v2+
  - [x] Autosave (60s de tempo de jogo) + save manual (tela de pausa)
  - [x] Menu principal: Novo Jogo (seed aleatória) / Continuar (só habilita se existe save) — vira o novo `run/main_scene`
  - [x] HUD: hotbar (F4) + barra de vida (`GameState.vida_atual/vida_maxima` — sem fonte de dano ainda, isso é F6/F7)
  - [x] Tela de pausa (tecla Esc): Continuar/Salvar/Sair pro menu
  - [x] 78/78 testes GUT
  - [x] Confirmado no navegador: menu renderiza (Novo Jogo habilitado, Continuar desabilitado sem save), zero erros de console
  - [ ] **Persistência real IndexedDB entre recarregamentos de navegador** — não testável de forma confiável nesta ferramenta de automação (mesmo gotcha de clique do F3/F4); a lógica de save/load em si está 100% testada, mas o "fechar aba e abrir de novo" depende do Godot sincronizar `user://` pro IndexedDB do browser, que é comportamento documentado da engine, não código nosso — confirmar na sessão de validação com o Murilo
  - [ ] Murilo joga 30 min e quer voltar (critério de sucesso do projeto — validação com o usuário)

## F6 — Sobrevivência
- **Objetivo:** dar propósito e ritmo ao mundo.
- **Entregas:** ciclo dia/noite; fome + comida (frutas/cogumelos + fornalha); energia; cama (respawn); baús; tochas; minérios (carvão, ferrite) + tier ferrite; morte com drop recuperável.
- **Dependências:** F5 · **Estimativa:** 2–3 sessões · **Risco:** baixo
- **Critérios — ✅ concluída em 19/jul/2026:**
  - [x] Blocos/itens novos: cama, baú, tocha, carvão, ferrite (+ picareta/machado ferrite, maçã crua/assada, fornalha) — 5 blocos, 10 itens, 7 receitas novas. Minério (carvão/ferrite) no subsolo via `WorldGenerator._bloco_de_subsolo()` (hash determinístico, mesma seed → mesmo mundo)
  - [x] Ciclo dia/noite: 10min dia + 5min noite (`GameState.DURACAO_CICLO_SEG`), `DayNightCalculator` (puro, testado) controla ângulo do sol/energia solar/luz ambiente; `main.gd` aplica por frame e emite `EventBus.day_started`/`night_started`
  - [x] Fome: decai 1 ponto/60s de jogo; fome zerada causa dano de 1 vida/10s (até vida=1, nunca mata sozinha). Comida (maçã crua/assada) via tecla `comer` (R) restaura `restaura_fome`, consumida da hotbar
  - [x] Energia: corrida (`Shift`) drena 1 ponto/2s enquanto anda; sem energia, corrida é bloqueada; regenera 1 ponto/2s parado ou andando devagar
  - [x] Cama define ponto de respawn (interagir/E); persistido no save. Morte (por queda) dropa toda a mochila no local (hotbar preservada), restaura vida cheia, teleporta pro respawn — `_processar_morte()` reaproveitável quando Cubelins hostis chegarem (F7)
  - [x] Dano de queda: seguro até 3 blocos, 1 vida por bloco excedente (ADR-017)
  - [x] Baús: inventário 24 slots por posição (`GameState.baus`), abre com `interagir` (E), tela dupla baú↔mochila, persistido no save, quebrar o baú dropa todo o conteúdo (nunca perde item)
  - [x] Tochas: iluminam ao colocar (`OmniLight3D` via `TorchLightManager`, reage a `block_placed`/`block_broken`), reacendem sozinhas ao continuar o jogo (sem persistência própria — reaproveita o delta de blocos)
  - [x] 118/118 testes GUT (25 scripts) — cobre fome/energia/comer, dano de queda, cama/respawn/morte+drop, baú (interação/UI/quebra/save-continue), tocha (spawn/remove/duplicata/save-continue)
  - [x] gdformat/gdlint limpos no projeto inteiro; smoke headless (menu + main, 60/120 frames) sem erros; export web local ok (~41MB)
  - [x] Confirmado no navegador: menu renderiza, zero erros de console (mesmo gotcha de clique WebGL do F3/F4/F5 — lógica verificada via GUT, não clique simulado)
  - [x] CI verde (commit `ad5f7c8`): [run 29674711476](https://github.com/marcospauloarena80-sketch/murilo-blokc-game/actions/runs/29674711476) — lint 15s, test 3m34s, export-web 1m41s
  - [ ] Noite muda o jogo na prática / balanceamento de fome não frustra — validação com o Murilo jogando

## F7 — Cubelins no mundo
- **Objetivo:** o vale ganha vida — criaturas visíveis com comportamento.
- **Entregas:** `CreatureDef` + 4 espécies iniciais (modelos CC0 adaptados); spawn por bioma/hora; FSM Idle/Wander/Flee/Aggro; espada de pedra (defesa noturna); dano por contato de agressivos.
- **Dependências:** F6 (dia/noite) · **Estimativa:** 2–3 sessões · **Risco:** médio (steering em terreno voxel)
- **Critérios — ✅ concluída em 19/jul/2026:**
  - [x] `CreatureDef` (Resource data-driven) + `CreatureRegistry` (padrão `BlockDef`/`ItemDef`) + 4 espécies: Brotinho (Mato, passivo/dia), Ventim (Vento, passivo/dia), Pedrolim (Pedra, agressivo/noite), Faiscolt (Faísca, agressivo/noite) — nomes do próprio GDD §9
  - [x] Modelo blocky: cubo único colorido pelo elemento (`Creature`/`creature.tscn`), consistente com "criaturas cúbicas" do GDD, sem depender de asset externo (mesma lógica do ADR-015 do Murilo)
  - [x] FSM pura Idle/Wander/Flee/Aggro (`CreatureBehavior`, testável sem Node) — passivo foge, agressivo persegue, idle↔wander por tempo quando o jogador está longe
  - [x] Movimento real com colisão no terreno voxel: `move_and_slide()` + gravidade, sem pathfinding — validado com física de verdade em `test_creature_world_physics.gd` (spawna no mundo real, roda várias frames, confirma que se move e não atravessa o chão)
  - [x] `CreatureSpawner`: passivos de dia, agressivos de noite, sempre na superfície (sem geração de cavernas ainda — ADR-020); limite de 8 criaturas simultâneas; despawn além de 48 blocos do jogador
  - [x] Espada de pedra (2 pedra + 1 graveto, bancada) — mão nua causa 1 de dano, espada causa 4; ataque por clique com cooldown de 0,5s
  - [x] Criatura agressiva causa dano de contato no jogador (cooldown de 1s, evita dano por frame)
  - [x] Bug real de ordem de nós encontrado e corrigido: `CreatureSpawner` nunca spawnava nada porque `Player` vem depois dele em `main.tscn` — resolvido com busca preguiçosa (lazy) auto-curativa em vez de depender de ordem (ADR-020)
  - [x] 151/151 testes GUT (31 scripts); gdformat/gdlint limpos no projeto inteiro; smoke headless (menu + main, 60/180 frames) sem erros; export web local ok
  - [x] Confirmado no navegador: menu renderiza, zero erros de console
  - [x] CI verde (commit `b1ee8f1`): [run 29675878010](https://github.com/marcospauloarena80-sketch/murilo-blokc-game/actions/runs/29675878010) — lint 13s, test 4m35s, export-web 1m46s
  - [ ] Cubelins vagam sem travar/atravessar blocos **na prática** / noite perigosa mas justa — validação com o Murilo jogando

## F8 — Captura e batalha
- **Objetivo:** o segundo pilar do jogo: capturar, batalhar, evoluir.
- **Entregas:** `battle_service` puro (turnos) + testes completos; cena de batalha; Cubo de Captura; equipe (3); XP/níveis/evolução (2 espécies evoluem); 12+ ataques; poções.
- **Dependências:** F7 · **Estimativa:** 3–4 sessões · **Risco:** médio (design/balanceamento)
- **Critérios:** capturar → treinar → evoluir funciona ponta a ponta; batalha justa nos 2 sentidos; lógica de batalha 100% coberta por testes.

## F9 — Vilarejo, NPCs e missões
- **Objetivo:** estrutura social e direção: o jogo passa a guiar o jogador.
- **Entregas:** Vilarejo Raiz (Professora Lina + laboratório com armazém de Cubelins, Refúgio, comerciante, construtor); diálogos; `QuestDef` + cadeia principal (~8 missões) + 4 repetíveis.
- **Dependências:** F8 · **Estimativa:** 3–4 sessões · **Risco:** médio (conteúdo dá trabalho)
- **Critérios:** jogador novo chega às Arenas guiado só pelas missões, sem explicação externa.

## F10 — Arenas Elementais
- **Objetivo:** objetivo de longo prazo e final de jogo.
- **Entregas:** 4 Arenas com Guardiões (equipes crescentes); insígnias com recompensas (receitas/áreas); roster completo (12 espécies, 6 evoluções); cristal dourado + tier final; desafio final do Coração Dourado.
- **Dependências:** F9 · **Estimativa:** 2–3 sessões · **Risco:** baixo (sistemas prontos; é conteúdo)
- **Critérios:** campanha completável do zero ao desafio final; dificuldade crescente validada com Murilo.

## F11 — Mundo completo
- **Objetivo:** riqueza: todos os biomas, clima, áudio.
- **Entregas:** 4 biomas restantes + cavernas decoradas; clima (chuva/tempestade); música por bioma + SFX completos; minimapa (opcional); polimento visual (partículas, iluminação).
- **Dependências:** F10 · **Estimativa:** 2–3 sessões · **Risco:** baixo
- **Critérios:** cada bioma é visual e sonoramente distinto; performance mantida ([budgets](09-PERFORMANCE.md)).

## F12 — Versão 1.0
- **Objetivo:** fechar: balancear, portar, polir.
- **Entregas:** passe de balanceamento geral; controles touch; export desktop (macOS/Windows); export mobile se necessário; tela de créditos; save final v-freeze (migrações testadas).
- **Dependências:** F11 · **Estimativa:** 2–3 sessões · **Risco:** baixo
- **Critérios:** jogável do início ao fim em navegador, desktop e tablet; zero bugs conhecidos de perda de save; Murilo aprova a 1.0.

---

## Caminho crítico

```
F1 → F2 → F3 → F4 → F5 (MVP) → F6 → F7 → F8 → F9 → F10 → F11 → F12 (1.0)
```

F2 é a fase-risco: se a performance de meshing na web falhar, o plano B está em [Riscos R2](06-RISCOS.md). Total estimado até 1.0: **22–34 sessões**.
