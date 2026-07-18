# 10 — Skills, Plugins e Ferramentas Recomendadas

Formato exigido: Nome · Objetivo · Benefício · Complexidade · Vale a pena?

## Addons / plugins Godot

| Nome | Objetivo | Benefício | Complexidade | Vale a pena? |
|---|---|---|---|---|
| **GUT** (Godot Unit Test) | Framework de testes | Base de toda a estratégia de testes; roda headless no CI | Baixa | **Sim** (F1) |
| **gdtoolkit** (gdformat/gdlint) | Formatação e lint de GDScript | Padrão de código automático no CI, zero discussão de estilo | Baixa | **Sim** (F1) |
| **Dialogue Manager** (Nathan Hoad) | Diálogos de NPCs | Editor de diálogo maduro e gratuito; economiza um sistema inteiro | Média | **Sim, na F9** — não instalar antes |
| **Phantom Camera** | Câmeras avançadas | Transições/follow prontos | Média | **Opcional** — só se a câmera própria (F3) der trabalho |
| **godot_voxel** (Zylann) | Engine voxel completa | Voxel streaming profissional | **Alta** — módulo C++, exige compilar export templates customizados (inclusive web) | **Não** — nosso mundo pequeno (ADR-005) não justifica; hand-rolled cobre |
| Plugins genéricos de inventário/RPG | Sistemas prontos | — | Média | **Não** — lógica central deve ser nossa: testável e sob controle (ADR-011) |

## Assets (CC0 — fase de assets, F3+)

| Nome | Objetivo | Benefício | Complexidade | Vale a pena? |
|---|---|---|---|---|
| **Kenney** (kenney.nl) | Modelos/texturas/áudio CC0 | Milhares de assets low-poly consistentes, inclusive voxel e UI | Baixa | **Sim** |
| **KayKit** | Personagens/criaturas low-poly animados CC0 | Base para Cubelins e NPCs com animações prontas | Baixa | **Sim** |
| **Quaternius** | Modelos low-poly CC0 | Complementa criaturas/props | Baixa | **Sim** |

## Infra / serviços

| Nome | Objetivo | Benefício | Complexidade | Vale a pena? |
|---|---|---|---|---|
| **GitHub Actions + imagem godot-ci** | CI/CD | Lint+testes+export web automáticos a cada push | Média (setup 1×) | **Sim** (F1) |
| **itch.io** (página privada) | Hospedar build web | Grátis, suporta wasm/headers corretos, acessível de qualquer dispositivo | Baixa | **Sim** (F1) |
| **Vercel static** | Alternativa de hosting | Conta já existente do usuário | Baixa | Alternativa — escolher 1 na F1 |

## Skills já instaladas no ambiente (usar a partir do Prompt 1)

| Nome | Objetivo | Vale a pena? |
|---|---|---|
| `karpathy-guidelines` | Disciplina de código (simplicidade, mudanças cirúrgicas) | **Sim** — antes de todo código |
| `superpowers:test-driven-development` | TDD no core/ | **Sim** — regras de jogo nascem com teste |
| `superpowers:writing-plans` / `executing-plans` | Planos por fase | **Sim** — um plano por fase do roadmap |
| `git-workflow` | Commits semânticos, PRs | **Sim** |
| `test-generator` | Gerar testes de código existente | Sim, pontual |
| `nano-banana-2` | Gerar texturas/ícones/UI por IA | **Sim, fase de assets** (texturas de bloco, ícones de item) |
| `code-review` / `superpowers:requesting-code-review` | Revisão ao fim de cada fase | **Sim** |

## MCPs / ferramentas externas avaliadas

| Nome | Objetivo | Benefício | Complexidade | Vale a pena? |
|---|---|---|---|---|
| **godot-mcp** (servidor MCP comunitário para o editor Godot) | IA controla/inspeciona o editor (rodar cena, ler erros) | Encurta o ciclo editar→testar com IA | Média; maturidade média | **Avaliar na F1** — instalar só se o fluxo sem ele se mostrar lento |
| Blender | Edição de modelos 3D | Ajustar assets CC0 (cores, acessórios de evolução) | Média | Sim, pontual na fase de assets — sem modelagem do zero |

## Lacuna identificada (wishlist)

Não existe skill instalada de **desenvolvimento Godot/GDScript** (padrões de engine, gotchas de export web). Adicionada à wishlist em `memory/golden_rules.md` — candidata a skill própria quando o Prompt 1 começar.
