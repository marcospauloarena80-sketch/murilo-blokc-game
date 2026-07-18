# 06 — Registro de Riscos

Revisar ao fim de cada fase. Escala: probabilidade/impacto Baixo·Médio·Alto.

| # | Risco | Prob. | Impacto | Mitigação | Gatilho / Plano B |
|---|---|---|---|---|---|
| R1 | **Scope creep** — adicionar features "legais" antes de fechar o funcional (maior risco do projeto) | Alta | Alto | Gate por fase (roadmap); toda ideia nova vai para P4 do backlog, nunca direto para o código; MVP intocável | Se uma fase passar de 2× a estimativa → cortar escopo da fase, não esticar |
| R2 | **Performance de meshing voxel na web** (single-thread, wasm) | Média | Alto | Mundo finito pequeno; face culling; time-slicing; medir FPS no CI manual desde F2 | Se <30 FPS no tablet: reduzir mundo (96×96×48), greedy meshing, ou última instância: mundo por "salas" carregadas |
| R3 | **iOS/Safari** — restrições de wasm/WebGL/áudio | Média | Médio | Build single-thread + renderer Compatibility; smoke test em tablet desde F1 | Se navegador iOS falhar: export nativo mobile antecipado (Godot cobre) |
| R4 | **Assets 3D de criaturas** — modelar/animar 12 espécies é caro | Alta | Médio | Packs CC0 (KayKit/Quaternius/Kenney) adaptados; estilo low-poly uniforme esconde origens diversas; roster reduzido (12, não 150) | Se faltar modelo: espécies compartilham base + variação de cor/acessório |
| R5 | **Save quebrar entre versões** — perder o mundo do Murilo destrói a confiança no jogo | Média | Alto | `schema_version` + migrações desde o 1º save; teste de migração no CI; autosave mantém backup do save anterior | Save corrompido: carregar backup automático |
| R6 | **Update da Godot quebrar o projeto** | Baixa | Médio | Travar 4.7.x; upgrade só entre fases, em branch, com suite de testes verde | Se upgrade quebrar: ficar na versão travada (nada obriga upgrade) |
| R7 | **Balanceamento de batalha ruim** (fácil/frustrante demais) | Média | Médio | Lógica pura permite simular milhares de batalhas em teste; validação com Murilo a cada fase | Ajustar curvas nos `.tres` — zero código |
| R8 | **Abandono/pausa longa do projeto** (projeto pessoal) | Média | Médio | Documentação completa (este diretório) permite retomar sem memória de conversa; fases curtas com entregas jogáveis | Retomar sempre pelo [Roadmap](04-ROADMAP.md) + [ADRs](07-DECISOES.md) |
| R9 | **Steering de criaturas em terreno voxel** travando/atravessando | Média | Baixo | FSM simples + testes de colisão; sem NavMesh (decisão consciente) | Limitar Cubelins a áreas planas de spawn |
| R10 | **Tamanho do export web crescer demais** (>60MB) | Baixa | Médio | Atlas único, modelos low-poly, áudio comprimido, monitorar tamanho no CI | Corte de assets, compressão agressiva, loading em etapas |
| R11 | **Física correndo mais rápido que meshing time-sliced** — confirmado na F2: player atravessava o chão inteiro porque a colisão do chunk ainda não existia quando ele chegava lá (custo de CPU do meshing é real, não é "grátis" só por ser time-sliced) | Confirmado (mitigado) | Alto | ADR-014: player só liga física após `mundo_gerado`; mesma lógica deve valer pra qualquer entidade nova que possa cair/mover antes do mundo pronto (Cubelins na F7, NPCs na F9) | Se mundo crescer e a espera incomodar: priorizar meshing dos chunks perto do spawn primeiro |
