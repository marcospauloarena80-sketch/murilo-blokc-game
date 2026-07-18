# 11 — Plano para o Prompt 1 (Fase 1: Fundação)

O Prompt 0 está concluído (só planejamento). O Prompt 1 executa a **F1 do [Roadmap](04-ROADMAP.md)**: esqueleto profissional rodando no navegador. Nada além da F1.

**Status: F1 concluída localmente em 18/jul/2026.** Único pendente é a criação do repo remoto no GitHub (ação de conta, ver nota abaixo).

## Pré-requisitos (checklist de preparação)

- [x] **Instalar Godot 4.7.x estável** (via `brew install --cask godot`; a stable disponível é 4.7.1, não 4.4.x — ADR-001 atualizado)
- [x] Baixar os **export templates** da mesma versão (1,28GB, autorizado pelo usuário, instalado em `~/Library/Application Support/Godot/export_templates/4.7.1.stable/`)
- [x] `git init` local na raiz `jogo do murilo/` — 3 commits feitos
- [ ] **Criar repo remoto no GitHub** `murilo-blocks-game` — **pendente do usuário**: exige `gh auth login` (OAuth interativo) ou criar manualmente em github.com e me passar a URL para `git remote add origin` + push
- [x] Hosting do build web: decidido via **ADR-013** — CI publica sempre como artifact do GitHub Actions; deploy itch.io fica pronto no workflow mas inativo até o usuário criar a página e adicionar o secret `BUTLER_API_KEY`
- [ ] Confirmar acesso do tablet/celular real do Murilo — testei em emulação de viewport tablet (768×1024) no navegador; teste no dispositivo físico fica para quando o usuário rodar a sessão de validação

## Escopo exato da F1 (nada a mais) — ✅ tudo entregue

1. ✅ Projeto Godot em `game/` com estrutura de pastas da [Arquitetura §2](02-ARQUITETURA.md)
2. ✅ `project.godot`: renderer **Compatibility** (`gl_compatibility`); tipagem estática com warnings promovidos a erro; InputMap com as ações base
3. ✅ Autoloads esqueleto: `EventBus`, `GameState`, `SaveManager`, `AudioManager`, `Logger` (com contrato documentado em cada arquivo)
4. ✅ GUT v9.7.1 instalado + 1 teste exemplo — roda headless local (`1/1 passed`, exit code 0)
5. ✅ Workflow `.github/workflows/ci.yml`: gdlint + gdformat --check → GUT → export web → artifact + log de tamanho (deploy itch.io condicional)
6. ✅ Cena `main.tscn`: chão 40×40 + Murilo cápsula com movimento/pulo/corrida + SpringArm3D câmera 3ª pessoa
7. ✅ Smoke test: build web exportado (39MB), servido localmente, testado no navegador — renderiza correto em desktop (800×450) e em viewport tablet (768×1024); console sem erros; confirmado via logs "Compatibility" + "single-threaded" (ADR-004)

## Critérios de conclusão (gate para a F2)

- [ ] CI verde de ponta a ponta **no GitHub Actions real** — não testável até existir o repo remoto; localmente replicei os 3 passos (lint, GUT, export) manualmente com sucesso
- [x] Build abre e roda no navegador (desktop real testado; tablet testado via emulação de viewport) — engine carrega, renderiza, responde a input, sem erros de console
- [x] `git log` limpo com commits semânticos (2 commits: docs Prompt 0 + feat Fase 1)
- [x] ADRs novos registrados: ADR-001 atualizado (versão real 4.7.x) + ADR-013 (hosting)

## Texto sugerido para abrir o Prompt 1

> Inicie o Prompt 1 do Murilo Blocks Game: execute a Fase 1 (Fundação) exatamente como definida em `docs/11-PROMPT-1.md` e `docs/04-ROADMAP.md`. Siga a arquitetura de `docs/02-ARQUITETURA.md`. Não implemente nada das fases seguintes. Ao final, apresente o checklist de critérios da F1 preenchido com evidências (CI verde, URL funcionando).

## Regras permanentes a partir do Prompt 1

- Skills de processo antes de codar: `karpathy-guidelines` + TDD no `core/`
- Toda decisão nova → ADR **antes** do código
- Gate de fase: critérios + smoke + (quando marcado) validação com o Murilo
- Ideia nova no meio da fase → vai para o [Backlog P4](05-BACKLOG.md), não para o código
