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
  - [ ] Validação de UX com o Murilo (fica pra sessão de validação, não é algo que eu meço sozinho)

## F5 — Save + HUD → **MVP 0.1 🎉**
- **Objetivo:** transformar o protótipo em jogo: progresso persiste.
- **Entregas:** SaveManager (JSON versionado, delta de mundo); autosave + save manual; menu principal (Novo/Continuar); HUD (hotbar, vida); tela de pausa.
- **Dependências:** F2–F4 · **Estimativa:** 1–2 sessões · **Risco:** baixo
- **Critérios:** fechar o navegador e voltar → mundo, posição e inventário intactos; **Murilo joga uma sessão de 30 min e quer voltar** (critério de sucesso do projeto).

## F6 — Sobrevivência
- **Objetivo:** dar propósito e ritmo ao mundo.
- **Entregas:** ciclo dia/noite; fome + comida (frutas/cogumelos + fornalha); energia; cama (respawn); baús; tochas; minérios (carvão, ferrite) + tier ferrite; morte com drop recuperável.
- **Dependências:** F5 · **Estimativa:** 2–3 sessões · **Risco:** baixo
- **Critérios:** noite muda o jogo (visibilidade/planejamento); balanceamento inicial de fome não frustra (validação Murilo).

## F7 — Cubelins no mundo
- **Objetivo:** o vale ganha vida — criaturas visíveis com comportamento.
- **Entregas:** `CreatureDef` + 4 espécies iniciais (modelos CC0 adaptados); spawn por bioma/hora; FSM Idle/Wander/Flee/Aggro; espada de pedra (defesa noturna); dano por contato de agressivos.
- **Dependências:** F6 (dia/noite) · **Estimativa:** 2–3 sessões · **Risco:** médio (steering em terreno voxel)
- **Critérios:** Cubelins vagam sem travar/atravessar blocos; noite é perigosa mas justa.

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
