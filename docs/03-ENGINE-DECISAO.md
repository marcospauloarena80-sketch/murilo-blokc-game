# 03 — Decisão de Engine e Stack

## Decisão

**Godot 4.7.x (estável) + GDScript tipado.** Versão travada; upgrades só conscientes e testados.

## 1. Matriz de decisão

Escala: 🟢 forte · 🟡 aceitável · 🔴 fraco/eliminatório. Critérios agrupados (a lista completa do prompt está coberta pelos grupos).

| Critério | Godot 4.4 | Phaser 3 | Bevy | Unity | Defold | PlayCanvas | Three.js |
|---|---|---|---|---|---|---|---|
| Suporte 3D (voxel) | 🟢 | 🔴 sem 3D | 🟡 | 🟢 | 🔴 limitado | 🟢 | 🟡 é lib, não engine |
| Export Web | 🟡 ~35MB, WebGL2 | 🟢 leve | 🟡 wasm | 🔴 pesado | 🟢 leve | 🟢 nativo web | 🟢 |
| Export Desktop | 🟢 nativo | 🟡 wrapper | 🟢 | 🟢 | 🟢 | 🔴 wrapper | 🔴 wrapper |
| Export Mobile | 🟢 nativo | 🟡 wrapper | 🟡 | 🟢 | 🟢 | 🟡 | 🔴 wrapper |
| Curva de aprendizado | 🟢 | 🟢 | 🔴 Rust | 🟡 | 🟡 Lua | 🟡 | 🟡 |
| Documentação | 🟢 excelente | 🟢 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 |
| Comunidade | 🟢 enorme, crescente | 🟢 | 🟡 | 🟢 | 🟡 pequena | 🟡 | 🟢 |
| Custo/licença | 🟢 MIT total | 🟢 MIT | 🟢 MIT | 🔴 fechada, histórico de troca de termos | 🟢 | 🟡 editor proprietário cloud | 🟢 MIT |
| IA auxiliar no dev (corpus) | 🟢 GDScript enorme | 🟢 | 🔴 pequeno | 🟢 | 🔴 pequeno | 🔴 pequeno | 🟢 |
| Editor (cenas, animação, física, partículas, áudio) | 🟢 completo | 🔴 sem editor | 🔴 sem editor | 🟢 | 🟡 | 🟢 cloud | 🔴 sem editor |
| Arquitetura (composição/ECS, cenas, resources) | 🟢 nodes+resources | 🟡 | 🟢 ECS puro | 🟡 | 🟡 | 🟡 | 🔴 faça você mesmo |
| Save local (web incluso) | 🟢 `user://`→IndexedDB | 🟢 | 🟡 | 🟡 | 🟢 | 🟢 | 🟡 manual |
| Mapas grandes/chunks | 🟢 ArrayMesh/GridMap | 🔴 2D | 🟢 | 🟢 | 🔴 | 🟢 | 🟢 |
| Inventário/NPCs/IA (ferramentas prontas) | 🟢 UI nodes, FSM fácil | 🟡 | 🔴 | 🟢 | 🟡 | 🟡 | 🔴 |
| Testes + CI/CD headless | 🟢 GUT + `--headless` | 🟢 vitest | 🟢 cargo | 🟡 pesado | 🟡 | 🔴 | 🟢 |
| Multiplayer futuro | 🟢 high-level API | 🟡 | 🟡 | 🟢 | 🟡 | 🟢 | 🟡 |
| Estabilidade/maturidade | 🟢 | 🟢 | 🔴 API instável | 🟢 | 🟢 | 🟢 | 🟢 |
| Memória/performance | 🟢 leve | 🟢 | 🟢 | 🔴 pesado | 🟢 | 🟢 | 🟢 |

### Eliminações
- **Phaser 3 / Defold:** sem 3D real → beco sem saída para voxel (retrabalho total se a visão é Minecraft-like). Eliminados no critério mais importante.
- **Bevy:** experimental (API quebra a cada versão), sem editor, curva Rust, corpus de IA pequeno. Viola a regra "só tecnologias maduras".
- **Unity:** export web pesado/lento (pior critério = nossa plataforma principal), licença fechada com histórico de mudança de termos (risco de retrabalho por motivo não-técnico), overkill para o escopo.
- **PlayCanvas:** ótimo web-3D, mas o editor é cloud proprietário = lock-in + dependência de serviço externo para um projeto pessoal de longa duração.
- **Three.js:** biblioteca de render, não engine — física, áudio, cenas, input, animação e tooling viriam à mão. Centenas de horas de engine-building que a Godot dá pronto.

### Por que Godot vence
Única opção **madura + gratuita (MIT) + editor completo + 3D + exports nativos para web/desktop/mobile**. Resources = data-driven nativo. GDScript tem corpus enorme para assistência de IA. Testável headless em CI. Comunidade grande e crescente. Sem lock-in de nenhum tipo.

### Fraquezas assumidas + mitigação
| Fraqueza | Mitigação |
|---|---|
| Export web ~30–40MB | Aceitável para projeto pessoal; assets low-poly; tela de loading; testar tamanho no CI desde F1 |
| iOS/Safari exigente | Build **single-threaded** (padrão 4.3+) + renderer **Compatibility** (WebGL2); smoke test em tablet desde F1 |
| GDScript dinâmico por padrão | Tipagem estática obrigatória; warnings de tipo promovidos a erro; gdlint no CI |
| C# não exporta para web | Não usamos C#; GDScript é a linguagem única (ADR-003) |

## 2. Stack completa

| Camada | Escolha |
|---|---|
| Engine | Godot 4.7.x estável |
| Linguagem | GDScript tipado (única) |
| Build | Export presets Godot (Web primeiro); export headless no CI |
| CI/CD | GitHub Actions (container `godot-ci`): lint → testes GUT → export web → deploy |
| Hospedagem do build web | itch.io (página privada) — grátis, suporta wasm, acessível de tablet/celular; alternativa: Vercel static |
| Versionamento | git + GitHub privado; `.gitignore`/`.gitattributes` padrão Godot |
| Assets | Packs CC0 (Kenney, KayKit, Quaternius) + geração IA para texturas/UI ([Ferramentas](10-FERRAMENTAS.md)) |
| Save | JSON versionado em `user://` (web = IndexedDB automático) |
| Configuração | Resources `.tres` (conteúdo) + `ConfigFile` (opções do jogador) |
| Logs | Autoload `Logger` com níveis |
| Eventos | Autoload `EventBus` (signals) |
| UI | Control nodes + tema central `.tres` |
| Testes | GUT + lógica pura em `core/` ([Plano de Testes](08-PLANO-TESTES.md)) |
| Sistemas de jogo | Ver [Arquitetura](02-ARQUITETURA.md) §4 (inventário, craft, combate, IA, mundo/chunks…) |

## 3. Dependências classificadas

| Dependência | Classe | Nota |
|---|---|---|
| Godot 4.7.x | **Essencial** | A engine |
| GUT (addon de testes) | **Essencial** | Única dependência de código no MVP |
| gdtoolkit (gdformat/gdlint) | **Essencial** (dev/CI) | Fora do runtime |
| GitHub Actions + imagem godot-ci | **Essencial** (CI) | Export/testes automatizados |
| Packs CC0 Kenney/KayKit/Quaternius | Recomendável | Assets; entra na fase de assets |
| Dialogue Manager (Nathan Hoad) | Recomendável (F9) | Diálogos/NPCs; adiar até precisar |
| Phantom Camera | Opcional | Só se a câmera própria der trabalho |
| godot_voxel (Zylann) | **Não recomendado** | Módulo C++: exigiria compilar templates customizados (inclusive web). Nosso mundo pequeno não precisa |
| Qualquer plugin de inventário/RPG pronto | **Não recomendado** | Lógica central do jogo deve ser nossa (testável, sob controle); plugins genéricos trazem acoplamento sem ganho real |

Regra permanente: **dependência nova só entra com ADR** justificando ganho real vs custo de manutenção.
