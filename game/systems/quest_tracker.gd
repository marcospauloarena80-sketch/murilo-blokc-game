class_name QuestTracker
extends Node
## Escuta EventBus e avança a missão ativa conforme tipo/alvo batem — mesmo
## padrão de LootSpawner/TorchLightManager (Node que só reage a sinais, sem
## lógica de mundo própria). Ver docs/01-GDD.md §12 e docs/07-DECISOES.md ADR-022.


func _ready() -> void:
	EventBus.item_collected.connect(_ao_coletar_item)
	EventBus.creature_captured.connect(_ao_capturar_criatura)
	EventBus.creature_defeated.connect(_ao_derrotar_criatura)
	EventBus.block_placed.connect(_ao_colocar_bloco)
	EventBus.recipe_crafted.connect(_ao_craftar_receita)


func _ao_coletar_item(item_id: String, quantidade: int) -> void:
	_avancar("coletar", item_id, quantidade)


func _ao_capturar_criatura(especie_id: String) -> void:
	_avancar("capturar", especie_id, 1)


func _ao_derrotar_criatura(especie_id: String) -> void:
	_avancar("derrotar", especie_id, 1)


func _ao_colocar_bloco(_pos: Vector3i, block_id: int) -> void:
	_avancar("construir", str(block_id), 1)


func _ao_craftar_receita(recipe_id: String) -> void:
	_avancar("craftar", recipe_id, 1)


func _avancar(tipo: String, alvo_id: String, quantidade: int) -> void:
	var quest := GameState.quest_atual()
	if quest == null or quest.tipo != tipo or quest.alvo_id != alvo_id:
		return
	GameState.progresso_quest_atual += quantidade
	if GameState.quest_atual_completa():
		_concluir_quest(quest)


func _concluir_quest(quest: QuestDef) -> void:
	for item_id: String in quest.recompensa_itens:
		GameState.adicionar_item(item_id, int(quest.recompensa_itens[item_id]))
	if not GameState.quests_concluidas.has(quest.quest_id):
		GameState.quests_concluidas.append(quest.quest_id)
	EventBus.quest_completed.emit(quest.quest_id)

	if quest.repetivel:
		GameState.progresso_quest_atual = 0
		return

	if quest.proxima_quest_id != "":
		GameState.iniciar_quest(quest.proxima_quest_id)
	else:
		GameState.quest_atual_id = ""
		GameState.progresso_quest_atual = 0
