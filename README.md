# Murilo Blocks Game

Jogo pessoal de exploração, sobrevivência, construção e captura de criaturas, ambientado no **Vale Dourado**. Inspirado em Minecraft (exploração/construção), Roblox (visual low-poly) e jogos de captura de monstros — com universo, nomes e criaturas 100% próprios.

- **Protagonista:** Murilo
- **Plataforma principal:** navegador (depois PC, tablet e celular)
- **Idioma:** português
- **Engine:** Godot 4.7.x + GDScript tipado (ver [docs/03-ENGINE-DECISAO.md](docs/03-ENGINE-DECISAO.md))
- **Save:** local, sem nuvem
- **Status:** Fase 0 concluída (pré-produção). Nenhum código escrito ainda — por regra do Prompt 0.

## Mapa da documentação

| Documento | Conteúdo |
|---|---|
| [docs/00-VISAO.md](docs/00-VISAO.md) | Pilares de design, experiência-alvo, universo, o que o jogo NÃO é |
| [docs/01-GDD.md](docs/01-GDD.md) | Game Design Document completo — loops, mecânicas, criaturas, mundo |
| [docs/02-ARQUITETURA.md](docs/02-ARQUITETURA.md) | Technical Design Document — camadas, sistemas, padrões Godot |
| [docs/03-ENGINE-DECISAO.md](docs/03-ENGINE-DECISAO.md) | Matriz de decisão de engine, stack completa, dependências |
| [docs/04-ROADMAP.md](docs/04-ROADMAP.md) | Fases F0→F12 até a versão 1.0 |
| [docs/05-BACKLOG.md](docs/05-BACKLOG.md) | Backlog priorizado P0–P4 |
| [docs/06-RISCOS.md](docs/06-RISCOS.md) | Riscos, probabilidade, impacto e mitigação |
| [docs/07-DECISOES.md](docs/07-DECISOES.md) | Registro de decisões técnicas (ADRs) |
| [docs/08-PLANO-TESTES.md](docs/08-PLANO-TESTES.md) | Estratégia de testes e plano de validação |
| [docs/09-PERFORMANCE.md](docs/09-PERFORMANCE.md) | Budgets de performance e estratégias |
| [docs/10-FERRAMENTAS.md](docs/10-FERRAMENTAS.md) | Skills, plugins e ferramentas recomendadas |
| [docs/11-PROMPT-1.md](docs/11-PROMPT-1.md) | Checklist de preparação para iniciar o desenvolvimento (Prompt 1) |

## Plano de documentação (regra permanente)

Nenhuma decisão pode depender só da memória da conversa:

1. **Toda decisão técnica nova** → vira ADR em `docs/07-DECISOES.md` (contexto, decisão, consequências).
2. **Todo sistema novo ou alterado** → atualiza a seção correspondente em `docs/02-ARQUITETURA.md`.
3. **Toda mecânica nova** → atualiza `docs/01-GDD.md` com a fase do roadmap em que entra.
4. **Fim de cada fase** → marcar critérios de conclusão em `docs/04-ROADMAP.md` e reavaliar riscos em `docs/06-RISCOS.md`.
5. Documentação sempre em português, sempre versionada em git junto com o código.

## Estrutura de pastas (alvo)

```
jogo do murilo/
├── README.md
├── docs/                  ← documentação (este Prompt 0)
├── game/                  ← projeto Godot (criado no Prompt 1)
└── .github/workflows/     ← CI (Fase 1)
```
