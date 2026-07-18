# 00 — Visão do jogo

## Frase-resumo

> Explore o Vale Dourado, minere e construa seu mundo bloco a bloco, e torne-se o maior domador de Cubelins do vale.

## Pilares de design

Toda decisão de escopo é testada contra estes 4 pilares. O que não serve a nenhum deles, sai.

1. **Construir é livre** — o mundo é editável bloco a bloco; a criatividade do jogador nunca é punida.
2. **Explorar recompensa** — cada bioma novo tem recursos, Cubelins e segredos que não existem no anterior.
3. **Progressão visível** — ferramentas melhores, criaturas mais fortes, base maior: o jogador vê o próprio progresso a cada sessão.
4. **Simples de aprender, difícil de esgotar** — controles e menus diretos; profundidade vem da combinação dos sistemas, não da complicação de cada um.

## Experiência-alvo

- **Jogador:** Murilo, 12+ anos. Desafio padrão de jogo de sobrevivência — sem simplificação infantil, sem hardcore punitivo.
- **Sessão típica:** 20–60 minutos: definir um objetivo (minerar X, construir Y, capturar Z), executar a expedição, voltar mais forte.
- **Tom:** aventura leve e colorida. Sem horror, sem gore, sem temas adultos.
- **Idioma:** 100% português.

## Universo — Vale Dourado

Um vale isolado, cercado por montanhas cúbicas, onde toda a matéria se organiza em blocos. No centro do vale brilha o **Coração Dourado**, a fonte de energia que dá vida aos **Cubelins** — criaturas elementais cúbicas que habitam cada bioma. Murilo chega ao vale como aprendiz de explorador: precisa sobreviver, construir sua base e conquistar a confiança (e a captura) dos Cubelins para, um dia, enfrentar os Guardiões das **Arenas Elementais**.

- **Biomas em anéis** ao redor do Coração: Campos Dourados → Floresta Cúbica → Colinas de Pedra → Deserto de Âmbar → Picos Gelados (+ cavernas subterrâneas).
- **Cubelins:** 6 elementos — Pedra, Mato, Brasa, Gota, Vento, Faísca.
- **Vilarejo Raiz:** casa do jogador, laboratório da Professora Lina, **Refúgio** (centro de cura), comerciantes e NPCs de missões.

Detalhes completos no [GDD](01-GDD.md).

## O que este jogo NÃO é

- **Não é clone:** nenhum nome, personagem, criatura, mapa ou asset de Minecraft, Roblox, Pokémon ou qualquer IP oficial.
- **Não é multiplayer** (até a 1.0 — arquitetura não fecha a porta, mas nada é construído para isso).
- **Não é produto:** sem monetização, sem publicação comercial, sem analytics, sem conta online.
- **Não é mundo infinito:** mundo finito e pequeno por decisão de performance e escopo (ADR-005).
- **Não salva em nuvem:** save local apenas.

## Plataformas

| Plataforma | Quando |
|---|---|
| Navegador (PC) | MVP — alvo principal desde a Fase 1 |
| Navegador (tablet/celular) | Testado desde cedo; controles touch na Fase 12 |
| Desktop (executável) | Fase 12 (export nativo Godot) |
| Mobile (app nativo) | Fase 12, se o navegador não bastar |

## Critério de sucesso do projeto

O jogo é um sucesso se o Murilo **pedir para jogar de novo**. Cada fase do roadmap termina com uma sessão de validação em que ele joga e dá feedback (ver [Plano de Testes](08-PLANO-TESTES.md)).
