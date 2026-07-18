# 11 — Plano para o Prompt 1 (Fase 1: Fundação)

O Prompt 0 está concluído (só planejamento). O Prompt 1 executa a **F1 do [Roadmap](04-ROADMAP.md)**: esqueleto profissional rodando no navegador. Nada além da F1.

## Pré-requisitos (checklist de preparação)

- [ ] **Instalar Godot 4.7.x estável** (`brew install --cask godot` no macOS) e anotar a versão exata em [07-DECISOES.md](07-DECISOES.md)
- [ ] Baixar os **export templates** da mesma versão (Editor → Manage Export Templates)
- [ ] Criar **repo GitHub privado** `murilo-blocks-game` e conectar esta pasta (`git init` na raiz `jogo do murilo/`)
- [ ] Escolher hosting do build web: **itch.io privado** (criar página) ou Vercel — registrar como ADR
- [ ] Confirmar acesso do tablet/celular que o Murilo usará (para o smoke test da F1)

## Escopo exato da F1 (nada a mais)

1. Projeto Godot em `game/` com estrutura de pastas da [Arquitetura §2](02-ARQUITETURA.md)
2. `project.godot`: renderer **Compatibility**; tipagem estática com warnings promovidos a erro; InputMap com as ações base
3. Autoloads esqueleto: `EventBus`, `GameState`, `SaveManager`, `AudioManager`, `Logger` (vazios, com contrato documentado)
4. GUT instalado + 1 teste exemplo rodando headless local
5. CI GitHub Actions: gdlint + gdformat --check → GUT → export web → deploy → log do tamanho do build
6. Cena `main.tscn`: chão plano + cápsula com movimento/pulo + câmera básica
7. Smoke test: URL abre e roda no navegador do PC e do tablet

## Critérios de conclusão (gate para a F2)

- [ ] CI verde de ponta a ponta no push
- [ ] URL pública (privada/unlisted) abre no PC e no tablet, 60 FPS com a cena base
- [ ] `git log` limpo com commits semânticos
- [ ] ADRs novos registrados (versão exata da Godot, hosting escolhido)

## Texto sugerido para abrir o Prompt 1

> Inicie o Prompt 1 do Murilo Blocks Game: execute a Fase 1 (Fundação) exatamente como definida em `docs/11-PROMPT-1.md` e `docs/04-ROADMAP.md`. Siga a arquitetura de `docs/02-ARQUITETURA.md`. Não implemente nada das fases seguintes. Ao final, apresente o checklist de critérios da F1 preenchido com evidências (CI verde, URL funcionando).

## Regras permanentes a partir do Prompt 1

- Skills de processo antes de codar: `karpathy-guidelines` + TDD no `core/`
- Toda decisão nova → ADR **antes** do código
- Gate de fase: critérios + smoke + (quando marcado) validação com o Murilo
- Ideia nova no meio da fase → vai para o [Backlog P4](05-BACKLOG.md), não para o código
