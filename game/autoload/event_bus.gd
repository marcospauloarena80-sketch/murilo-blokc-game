extends Node
## Catálogo central de sinais do jogo. Não guarda estado — só declara e emite.
## Regra: um sinal só entra aqui quando ≥2 sistemas precisam dele.
## Ver docs/02-ARQUITETURA.md §4.11.

signal block_broken(pos: Vector3i, block_id: int)
signal block_placed(pos: Vector3i, block_id: int)
## Bloco que emite luz surgiu por geração ou por save carregado — não é ação do
## jogador, então não toca som, não dropa item e não conta pra missão (ADR-026).
signal light_block_loaded(pos: Vector3i, block_id: int)
signal item_collected(item_id: String, amount: int)
signal chest_requested(chave: String)
signal recipe_crafted(recipe_id: String)
signal player_died
## Jogador tocou o chão depois de cair mais de 1,5 bloco (Ciclo 5): pos é a
## posição dos pés; só cosmético (poeira), o dano de queda fica no Player.
signal player_landed(pos: Vector3, altura_queda: float)
## Jogador deitou numa cama à noite (Ciclo 6): o main.gd amanhece o dia, cura
## e faz o fade preto.
signal player_slept
## Texto curto pro toast do HUD, vindo de quem não enxerga o HUD (Player,
## main.gd). O HUD liga este sinal ao _mostrar_aviso.
signal aviso(texto: String)
signal day_started
signal night_started
signal battle_started(criatura: Creature)
signal battle_ended
## Equipe de Cubelins mudou (adicionar, trocar, soltar): o Companheiro do mundo
## se refaz com o primeiro da equipe (Ciclo 9, 9C).
signal team_changed
signal creature_captured(species_id: String)
signal creature_defeated(species_id: String)
signal quest_completed(quest_id: String)
## Treinador de mundo (Ciclo 9, 9E) vencido; arena_id é o da ArenaDef sem insígnia.
signal treinador_vencido(arena_id: String)
signal dialogue_started(npc: Npc)
signal laboratorio_requested
signal caderno_requested
signal arena_challenge_started(arena_id: String)
signal game_completed
signal game_saved
