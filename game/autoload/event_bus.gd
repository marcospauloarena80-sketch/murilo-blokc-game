extends Node
## Catálogo central de sinais do jogo. Não guarda estado — só declara e emite.
## Regra: um sinal só entra aqui quando ≥2 sistemas precisam dele.
## Ver docs/02-ARQUITETURA.md §4.11.

signal block_broken(pos: Vector3i, block_id: int)
signal block_placed(pos: Vector3i, block_id: int)
signal item_collected(item_id: String, amount: int)
signal chest_requested(chave: String)
signal recipe_crafted(recipe_id: String)
signal player_died
signal day_started
signal night_started
signal battle_started(criatura: Creature)
signal battle_ended
signal creature_captured(species_id: String)
signal creature_defeated(species_id: String)
signal quest_completed(quest_id: String)
signal dialogue_started(npc: Npc)
signal laboratorio_requested
signal arena_challenge_started(arena_id: String)
signal game_completed
signal game_saved
