# 01 — Game Design Document (GDD)

> Cada mecânica está marcada com a fase do roadmap em que entra (**F1–F12**, ver [Roadmap](04-ROADMAP.md)). O MVP jogável fecha na **F5**.

## Ficha técnica

| Campo | Valor |
|---|---|
| Título | Murilo Blocks Game |
| Gênero | Sobrevivência / construção voxel / captura de criaturas |
| Perspectiva | 3D voxel low-poly, câmera em 3ª pessoa |
| Público | Pessoal (Murilo, 12+) |
| Plataforma | Navegador primeiro; desktop/mobile depois |
| Idioma | Português |
| Modo | Single-player, save local |

---

## 1. Loops de jogo

### Game loop (estrutura da partida)
Boot → Menu (Novo jogo / Continuar) → Jogando ⇄ Pausado → Salvar → Sair. Estado gerenciado por máquina de estados global (ver [Arquitetura §3](02-ARQUITETURA.md)).

### Core loop (minuto a minuto) — F2–F5
```
Explorar → Minerar/Coletar → Craftar → Construir/Equipar → Explorar mais longe
```
Cada volta do loop deixa o jogador com mais recursos, ferramentas melhores e acesso a áreas novas.

### Player loop (por sessão) — F5+
```
Definir objetivo → Preparar (craft/comida/equipe) → Expedição → Retornar à base → Guardar/Upgrades → Salvar
```

### Progression loop (longo prazo) — F6–F10
```
Ferramentas melhores → Biomas mais distantes → Recursos raros + Cubelins mais fortes
→ Vencer Arena Elemental → Insígnia desbloqueia área/receitas → repete
```

---

## 2. Personagem — Murilo

- **Movimentação (F3):** andar, correr, pular, agachar. Câmera 3ª pessoa orbital com zoom; colisão de câmera com terreno.
- **Ações (F2–F4):** quebrar bloco (segurar botão, tempo depende de bloco × ferramenta), colocar bloco, interagir (E), usar item da hotbar.
- **Atributos:** Vida (F5) · Fome (F6) · Energia (F6). Sem fôlego/sede — YAGNI.
- **Morte (F6):** respawn na cama/Vilarejo; dropa itens da mochila no local (hotbar preservada). Recuperável ao voltar. Sem perda de XP de Cubelins.

### Personalização do Murilo (F3)

Inspirado em Minecraft (escolher aparência) e Roblox (visual customizável), mas com escopo enxuto pro MVP — decisão do usuário (2026-07-18): **editor de cores, sem itens equipáveis ainda**.

- **Modelo:** blocky/low-poly (partes: cabeça, cabelo, tronco, 2 braços, 2 pernas) — mesma linguagem visual do mundo voxel, construído com primitivas da própria Godot (sem depender de pack externo nesta fase).
- **Customização:** 4 categorias, cada uma com paleta fixa de cores pra escolher — **pele**, **cabelo**, **camisa**, **calça**. Sem desbloqueáveis, sem tela de inventário de roupas.
- **Tela de criação:** aparece antes do jogo começar (estado `CHARACTER_CREATION`), com preview ao vivo do próprio Murilo já no mundo; botão "Jogar" confirma e libera o controle.
- **Fora do MVP de customização (backlog P4):** guarda-roupa com itens equipáveis desbloqueáveis (chapéus, camisas, acessórios) como recompensa das Arenas Elementais (F10) — ideia natural de progressão, mas não faz parte da F3.

## 3. Mundo

- **Estrutura (F2):** mundo finito de 128×128×64 blocos (8×8 chunks de 16×16×64), gerado proceduralmente por seed (noise de altura + camadas). Sem mundo infinito (ADR-005).
- **Biomas (F2 = 1 bioma; F11 = todos):** em anéis a partir do centro:
  | Bioma | Recursos típicos | Cubelins típicos |
  |---|---|---|
  | Campos Dourados (centro, F2) | madeira, terra, pedra superficial | Mato, Vento |
  | Floresta Cúbica (F11) | madeiras raras, frutas | Mato, Faísca |
  | Colinas de Pedra (F11) | minérios expostos | Pedra |
  | Deserto de Âmbar (F11) | areia, âmbar, cactos | Brasa, Pedra |
  | Picos Gelados (F11) | gelo, cristal | Gota, Vento |
  | Cavernas (F6) | carvão, ferrite, cristal dourado | Pedra, Faísca |
- **Ciclo dia/noite (F6):** dia 10 min / noite 5 min. À noite Cubelins agressivos aparecem na superfície; tochas afastam spawns.
- **Clima (F11):** chuva (Gota mais comum), tempestade (Faísca aparece). Visual + spawn, sem dano.

## 4. Blocos e mineração (F2)

**Blocos do MVP (6):** grama, terra, pedra, tronco, folhas, areia.
**Pós-MVP:** carvão (F6), ferrite (F6), cristal dourado (F10), gelo, âmbar, madeiras raras (F11).

- Cada bloco: dureza, ferramenta ideal, drop (`BlockDef` — data-driven).
- Quebrar sem ferramenta ideal = mais lento (nunca impossível no tier certo).
- Colocar bloco: da hotbar, com preview de posição.

## 5. Coleta e inventário

- **Drops (F4):** blocos quebrados viram itens flutuantes com atração magnética ao jogador.
- **Inventário (F4):** mochila 24 slots + hotbar 8 slots + slots de equipamento (F8: armadura). Empilhamento até 64.
- **Baús (F6):** 24 slots, colocáveis; conteúdo salvo no mundo.

## 6. Craft (F4)

- **Interface:** lista de receitas (estilo livro de receitas — sem grid de posicionamento; mais direto e mais fácil de testar). Receita acende quando há ingredientes.
- **Bancada:** desbloqueia receitas avançadas; craft de bolso para receitas básicas.
- **Receitas do MVP (6):** tábuas, gravetos, bancada, picareta de madeira, machado de madeira, picareta de pedra.
- **Tiers de ferramenta:** madeira → pedra (F4) → ferrite (F6) → cristal dourado (F10). Tier maior = quebra mais rápido + acessa blocos novos.
- **Pós-MVP:** armas (espada F7), armaduras (F8), Cubo de Captura (F8), comida cozida (F6), tochas (F6).

## 7. Construção (F2+)

Colocar/remover blocos livremente. Estruturas funcionais: bancada (F4), cama = respawn (F6), baú (F6), fornalha (F6), tocha (F6). Casa/base é objetivo emergente — o jogo sugere via missões (F9), nunca obriga.

## 8. Sobrevivência (F6)

- **Fome:** barra que desce com o tempo/ações; zerada = drena vida até 1 (não mata sozinha). Comer restaura.
- **Comida:** frutas (coleta), carne? — não: **cogumelos e frutas cozidos** na fornalha (evita tema de abate; mundo com Cubelins não tem "animais de corte").
- **Energia:** correr/quebrar gasta; regenera parado/comendo. Simples — só limita spam de corrida.
- **Perigo noturno:** Cubelins agressivos selvagens (a partir da F7; na F6 a noite só limita visão).

## 9. Cubelins (F7–F8)

Criaturas elementais cúbicas do Vale Dourado. **Nada de nomes/designs de IPs existentes.**

- **Elementos (6):** Pedra, Mato, Brasa, Gota, Vento, Faísca.
- **Vantagem elemental (2 triângulos):**
  - Brasa → Mato → Gota → Brasa
  - Pedra → Faísca → Vento → Pedra
  - Vantagem = dano ×1,5 · desvantagem = ×0,75.
- **Stats:** Vigor (HP), Força, Guarda, Agilidade (ordem de turno). Crescem por nível (curvas no `CreatureDef`).
- **Nível e XP:** XP por batalha vencida; nível máx. 30 na 1.0.
- **Evolução:** parte das espécies evolui 1× (nível fixo por espécie, ex. 12). Evolução muda modelo, stats e destrava ataques.
- **Ataques:** até 4 slots; aprendidos por nível (data-driven). Cada ataque: elemento, poder, custo de energia da criatura.
- **Roster 1.0:** 12 espécies (2 por elemento), 6 com evolução → 18 formas. Nomes e designs definidos na F7 (ex. de direção: *Pedrolim* (Pedra), *Brotinho* (Mato), *Brasita* (Brasa), *Gotelo* (Gota), *Ventim* (Vento), *Faiscolt* (Faísca)).
- **Spawn:** por bioma + hora do dia; selvagens vagam pelo mundo (visíveis, sem encontro aleatório invisível).

## 10. Captura (F8)

- **Cubo de Captura:** item craftável (ferrite + cristal).
- Só captura Cubelin selvagem **enfraquecido em batalha**. Chance = f(HP restante %, tier do cubo). Falhou = consome o cubo, batalha continua.
- **Equipe:** até 3 Cubelins ativos; excedentes ficam no **Laboratório** da Professora Lina (F9).

## 11. Batalha (F8)

- **Formato: turnos, 1×1** (troca de Cubelin gasta o turno). Encostar num selvagem/aceitar desafio inicia a batalha em modo arena (câmera fixa, mundo pausado).
- **Ações por turno:** Atacar (escolher 1 dos 4) · Trocar · Item (poção, Cubo de Captura) · Fugir (chance por Agilidade; impossível vs Guardiões).
- **Dano:** `poder × (Força/Guarda) × elemento × variação(0,9–1,1)`.
- **Derrota do jogador:** Cubelins desmaiam, jogador volta ao Refúgio; sem perda de itens.
- Por que turnos e não tempo real: mais fácil de balancear, testável de forma automatizada (lógica pura), roda perfeito na web e combina com o público (ADR-007).

## 12. NPCs e missões (F9)

- **Vilarejo Raiz:** Professora Lina (laboratório: guarda/cura Cubelins, tutorial de captura), **Refúgio** (cura rápida), Comerciante (troca recursos), Construtor (missões de construção).
- **Diálogo:** caixas de texto simples com escolhas ocasionais.
- **Missões (data-driven, `QuestDef`):** tipos — coletar X, construir Y, derrotar Z, capturar W, explorar bioma. Recompensas: receitas, itens, acesso a áreas. Cadeia principal curta (guia até as Arenas) + missões repetíveis.

## 13. Arenas Elementais (F10)

- 4 Arenas (Pedra, Brasa, Gota, Faísca), cada uma num bioma, com **Guardião** (NPC com equipe de 2–3 Cubelins, nível crescente).
- Vitória = **Insígnia**: desbloqueia receita exclusiva + área nova + missões novas.
- 4ª insígnia libera o desafio final: Guardião do Coração Dourado (batalha 3×3 alternada) → créditos da 1.0.

## 14. UX / UI

- **HUD (F5):** hotbar, vida; fome/energia (F6); equipe Cubelin (F8). Minimalista, ícones grandes.
- **Telas:** menu principal, pausa, inventário/craft (uma tela só, F4), batalha (F8), diálogo (F9), mapa (F11, opcional).
- **Controles (F3):** WASD + mouse (padrão); tudo remapeável via InputMap. Touch (F12): joystick virtual + botões contextuais.
- **Onboarding:** sem tutorial formal no MVP; missões da Professora Lina (F9) ensinam jogando.
- **Acessibilidade:** fontes legíveis, alto contraste no HUD, sem dependência de cor pura para informação.

## 15. Áudio (F11)

- Música ambiente por bioma (loops calmos), tema de batalha, tema do vilarejo.
- SFX: quebrar/colocar bloco (por material), passos, craft, UI, ataques, captura.
- Fontes: packs CC0 (Kenney Audio e afins). Buses: Master / Música / SFX com volumes no menu.

## 16. Conteúdo × fase (resumo)

| Sistema | Fases |
|---|---|
| Mundo voxel, minerar/construir | F2 |
| Personagem + câmera | F3 |
| Inventário + craft | F4 |
| Save/HUD → **MVP 0.1** | F5 |
| Dia/noite, fome, fornalha, baús, tier ferrite | F6 |
| Cubelins selvagens + IA | F7 |
| Batalha, captura, XP, evolução | F8 |
| Vilarejo, NPCs, missões | F9 |
| Arenas + insígnias + desafio final | F10 |
| Biomas extras, clima, áudio, mapa | F11 |
| 1.0: balanceamento, touch, exports | F12 |
