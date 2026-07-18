# 09 — Plano de Performance

Meta declarada: **60 FPS constantes** no navegador desktop, ≥30 FPS em tablet, com folga de memória. Performance é critério de conclusão de fase, não polimento final.

## Budgets

| Métrica | Budget | Onde medir |
|---|---|---|
| Frame (navegador desktop) | ≤16,6ms (60 FPS) | Overlay de FPS no smoke de fase |
| Frame (tablet) | ≤33ms (30 FPS) | Idem |
| Meshing por frame (time-slice) | ≤4ms | Timer no ChunkManager (debug) |
| Geração de mundo (primeiro load) | <5s | Smoke F2 |
| Load total no navegador (cache frio) | <15s | Smoke de fase |
| Save (escrita) | <100ms, sem hitch | Timer no SaveManager |
| Tamanho do export web | <60MB (alerta em 45MB) | Log do CI |
| Memória (web) | <512MB | Monitor do navegador no smoke |
| Draw calls em jogo | <300 | Profiler Godot |

## Estratégias por área

### Mundo voxel (o gastador principal)
- 1 mesh por chunk; **só faces expostas** (face culling entre blocos sólidos).
- **Texture atlas único** para todos os blocos → 1 material → chunks em pouquíssimos draw calls.
- Meshing **time-sliced** (fila de chunks sujos, budget de 4ms/frame) — a web é single-thread, nunca meshar tudo num frame.
- Colisão gerada junto do mesh, só de chunks próximos ao jogador.
- Greedy meshing **só se** o budget estourar (complexidade não paga adiantado).
- Sem LOD: mundo pequeno (ADR-005) torna desnecessário.

### Entidades
- Cubelins/NPCs: modelos low-poly (<2k tris), pooling de instâncias, densidade máxima por bioma controlada pelo SpawnSystem.
- Drops: pooling + merge de drops iguais próximos + despawn após 5 min.
- FSM dorme quando o jogador está longe (tick reduzido a 1/s fora de raio).

### Regras de código
- Nunca alocar em `_process`/`_physics_process` (sem `new`, sem arrays temporários) — GC/alloc é hitch na web.
- Pooling para tudo que spawna repetido (drops, partículas, audio players).
- Sinais em vez de polling; `_process` desligado em nós ociosos.

### Assets
- Texturas do atlas em resolução mínima estilizada (16–32px por bloco).
- Áudio: OGG comprimido, música em stream.
- Import 3D com compressão de mesh da Godot.

## Medição contínua

- Overlay de debug (FPS, frame time, chunks na fila, draw calls) atrás de flag — presente desde a F2.
- Profiler da Godot nas sessões de desenvolvimento das fases de risco (F2, F7, F11).
- Tamanho do export publicado pelo CI a cada push (tendência visível cedo).
