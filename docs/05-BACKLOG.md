# 05 — Backlog priorizado

Regra: **entregar funcional antes de adicionar novo**. IDs `MB-xxx` estáveis para rastreio. Prioridades mapeiam fases do [Roadmap](04-ROADMAP.md): P0 = MVP (F1–F5) · P1 = F6–F8 · P2 = F9–F10 · P3 = F11–F12 · P4 = pós-1.0 (não prometido).

## P0 — MVP (F1–F5)

| ID | Item | Fase |
|---|---|---|
| MB-001 | Repo git + GitHub privado + .gitignore Godot | F1 |
| MB-002 | Projeto Godot: renderer Compatibility, tipagem→erro, estrutura de pastas | F1 |
| MB-003 | Autoloads esqueleto (EventBus, GameState, SaveManager, AudioManager, Logger) | F1 |
| MB-004 | GUT instalado + 1 teste exemplo + execução headless | F1 |
| MB-005 | CI GitHub Actions: lint + testes + export web + deploy | F1 |
| MB-006 | Cena base: chão + cápsula anda/pula no navegador | F1 |
| MB-007 | `core/worldgen`: geração por seed (altura + camadas) + testes | F2 |
| MB-008 | ChunkManager: dados de chunk, get/set_block | F2 |
| MB-009 | Meshing: face culling, atlas, colisão, time-slicing | F2 |
| MB-010 | Re-mesh incremental ao editar bloco | F2 |
| MB-011 | 6 BlockDef (grama, terra, pedra, tronco, folhas, areia) | F2 |
| MB-012 | Quebrar bloco (tempo por dureza×ferramenta) + colocar com preview | F2 |
| MB-013 | Modelo blocky do Murilo (partes primitivas) + animação procedural de membros | F3 |
| MB-014 | Câmera 3ª pessoa orbital com colisão | F3 |
| MB-015 | InputMap completo remapeável | F3 |
| MB-013b | `CharacterAppearance` (pele/cabelo/camisa/calça) + paletas + GameState.aparencia_atual | F3 |
| MB-013c | Estado `CHARACTER_CREATION` no GameState + gate de input no player | F3 |
| MB-013d | Tela de criação de personagem (swatches de cor + preview ao vivo + botão Jogar) | F3 |
| MB-016 | `InventoryModel` puro + testes (slots, stack 64, mover) | F4 |
| MB-017 | Drops físicos + ItemMagnet | F4 |
| MB-018 | Hotbar 8 + mochila 24 + tela inventário/craft | F4 |
| MB-019 | `CraftService` puro + testes + 6 RecipeDef + bancada | F4 |
| MB-020 | Ferramentas (madeira/pedra) afetam velocidade de quebra | F4 |
| MB-021 | SaveManager: JSON versionado, delta de mundo, autosave | F5 |
| MB-022 | Menu principal (Novo/Continuar) + pausa | F5 |
| MB-023 | HUD: hotbar + vida | F5 |
| MB-024 | Sessão de validação MVP com Murilo | F5 |

## P1 — Sobrevivência e Cubelins (F6–F8)

| ID | Item | Fase |
|---|---|---|
| MB-030 | Ciclo dia/noite + iluminação | F6 |
| MB-031 | Fome + comidas + fornalha (cozinhar) | F6 |
| MB-032 | Energia (corrida/regeneração) | F6 |
| MB-033 | Cama (respawn) + morte com drop recuperável | F6 |
| MB-034 | Baús persistidos | F6 |
| MB-035 | Tochas (luz + bloqueio de spawn) | F6 |
| MB-036 | Minérios carvão/ferrite + tier ferrite | F6 |
| MB-037 | CreatureDef + 4 espécies + modelos | F7 |
| MB-038 | SpawnSystem (bioma × hora × densidade) | F7 |
| MB-039 | FSM criaturas (Idle/Wander/Flee/Aggro) + steering | F7 |
| MB-040 | Espada + dano por contato de agressivos | F7 |
| MB-041 | `BattleService` puro (turnos, dano, ordem) + testes completos | F8 |
| MB-042 | Cena de batalha (arena, UI de ações, animações) | F8 |
| MB-043 | Cubo de Captura + fórmula de captura | F8 |
| MB-044 | Equipe de 3 + troca em batalha | F8 |
| MB-045 | XP/nível/evolução + aprendizado de ataques | F8 |
| MB-046 | 12+ AttackDef + poções | F8 |

## P2 — Vilarejo e Arenas (F9–F10)

| ID | Item | Fase |
|---|---|---|
| MB-050 | Vilarejo Raiz (layout + construções) | F9 |
| MB-051 | Professora Lina + laboratório (armazém de Cubelins) | F9 |
| MB-052 | Refúgio (cura) + comerciante + construtor | F9 |
| MB-053 | Sistema de diálogo | F9 |
| MB-054 | QuestDef + QuestLog + cadeia principal (~8) + 4 repetíveis | F9 |
| MB-055 | 4 Arenas Elementais + Guardiões | F10 |
| MB-056 | Insígnias + recompensas (receitas/áreas) | F10 |
| MB-057 | Roster completo: 12 espécies, 6 evoluções | F10 |
| MB-058 | Cristal dourado + tier final de ferramentas | F10 |
| MB-059 | Desafio final: Guardião do Coração Dourado | F10 |

## P3 — Mundo completo e 1.0 (F11–F12)

| ID | Item | Fase |
|---|---|---|
| MB-060 | 4 biomas restantes + cavernas decoradas | F11 |
| MB-061 | Clima (chuva/tempestade + efeito em spawns) | F11 |
| MB-062 | Música por bioma + SFX completos + menu de volumes | F11 |
| MB-063 | Minimapa (opcional — cortar se apertar) | F11 |
| MB-064 | Partículas e polish visual | F11 |
| MB-065 | Passe de balanceamento geral | F12 |
| MB-066 | Controles touch (joystick virtual) | F12 |
| MB-067 | Export desktop (macOS/Windows) | F12 |
| MB-068 | Export mobile nativo (se navegador não bastar) | F12 |
| MB-069 | Créditos + freeze do schema de save | F12 |

## P4 — Ideias futuras (fora do escopo 1.0; sem compromisso)

- Multiplayer local/online (arquitetura não bloqueia; high-level multiplayer da Godot)
- Save em nuvem / múltiplos slots com perfis
- Novos modos (criativo puro, boss rush de Arenas)
- Criaturas lendárias raras + eventos sazonais
- Sistema de pets seguindo o jogador fora de batalha
- Guarda-roupa com itens equipáveis desbloqueáveis (chapéus, camisas, acessórios) — recompensa das Arenas Elementais (F10); editor de cor básico já sai na F3
- Conquistas
