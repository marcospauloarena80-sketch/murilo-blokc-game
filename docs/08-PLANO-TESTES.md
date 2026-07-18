# 08 — Plano de Testes e Validação

## Estratégia (pirâmide)

```
        Validação com o Murilo  ← cada fim de fase
       Smoke manual roteirizado  ← cada fase, no navegador
      Integração (GUT, headless)  ← sistemas combinados
   Unit (GUT sobre core/ puro)     ← a maior parte: regras de jogo
```

**Princípio:** tudo que é regra de jogo vive em `core/` (classes puras) e é testado por unit test rápido. Cenas e física recebem smoke test manual roteirizado — não vale o custo de automatizar UI 3D num projeto deste porte (decisão consciente, ADR-011).

## 1. Testes unitários (GUT, `game/tests/unit/`)

Rodam headless no CI a cada push. Cobertura obrigatória por sistema:

| Sistema | Casos mínimos |
|---|---|
| `worldgen` | mesma seed = mesmo mundo (determinismo); alturas dentro dos limites; distribuição de camadas |
| `inventory_model` | add/remove, stack até 64, overflow, mover/dividir slots, resultado explícito quando cheio |
| `craft_service` | receita com/sem ingredientes; transação atômica (falha não consome nada); exigência de bancada |
| `battle_service` | ordem por Agilidade; fórmula de dano (vantagem ×1,5 / desvantagem ×0,75); captura por faixa de HP; fuga; XP/level-up; evolução no nível certo |
| `save_migrator` | cada migração vN→vN+1 com fixtures de saves antigos; save corrompido → erro limpo, não crash |
| `quest_log` | avanço de objetivo por evento; conclusão; pré-requisitos |
| Validação de dados | todo `.tres` íntegro: receitas referenciam itens existentes, ataques têm elemento válido, curvas de criaturas monotônicas |

## 2. Testes de integração (GUT, `game/tests/integration/`)

- ChunkManager: `set_block` → chunk re-meshado marcado sujo; borda de chunk atualiza vizinho.
- Save ida-e-volta: jogar (programaticamente) → salvar → carregar → estado idêntico.
- EventBus: quebrar bloco emite cadeia correta (block_broken → drop → item_collected).

## 3. Smoke manual roteirizado (por fase, no navegador)

Checklist fixo executado no PC **e** no tablet antes de fechar cada fase:

1. Carregar o jogo do zero (cache limpo) — mede tempo de load.
2. Roteiro da fase (ex. F4: derrubar árvore → craftar picareta de pedra → construir abrigo 3×3).
3. Salvar, fechar navegador, reabrir, continuar.
4. FPS overlay ligado: anotar mínimo/médio ([budgets](09-PERFORMANCE.md)).
5. 10 min de jogo livre procurando bugs.

## 4. Performance como teste

Budgets de [09-PERFORMANCE.md](09-PERFORMANCE.md) verificados no smoke de cada fase. Regressão de budget = bug bloqueante da fase, igual a crash.

## 5. Plano de validação (o teste que importa)

Ao fim de **F3, F5 (MVP), F6, F8, F10 e F12**, o Murilo joga uma sessão sem instruções:

- **Observar sem ajudar:** onde ele trava sem ajuda? (problema de onboarding/UX)
- **Perguntar depois:** o que foi mais divertido? O que foi chato? O que você queria que existisse?
- **Métrica única de sucesso:** ele pede para jogar de novo?
- Feedback vira itens de backlog (priorizados normalmente — não fura o gate de fase, exceto diversão quebrada no core loop, que é P0 imediato).

## 6. CI (GitHub Actions, desde a F1)

Pipeline a cada push: `gdlint`/`gdformat --check` → GUT headless (unit + integração) → export web → deploy (itch.io/Vercel) → publicar tamanho do build no log. Falhou = não mergeia.
