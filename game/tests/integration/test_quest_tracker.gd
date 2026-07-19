extends GutTest
## Ver docs/01-GDD.md §12 e docs/07-DECISOES.md ADR-022. Chama os handlers
## privados direto (em vez de emitir no EventBus) — instâncias de main.tscn
## noutros arquivos de teste (test_menu_fluxo_completo.gd etc.) também têm
## um QuestTracker real conectado ao EventBus, e o `add_child_autofree` entre
## scripts diferentes não garante que ele já foi liberado quando este arquivo
## roda, então emitir de verdade pode disparar handlers duplicados.

var _quest: QuestDef


func before_each() -> void:
	_quest = QuestDef.new()
	_quest.quest_id = "teste_quest"
	_quest.tipo = "coletar"
	_quest.alvo_id = "pedra"
	_quest.quantidade_alvo = 3
	QuestRegistry._quests[_quest.quest_id] = _quest

	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)


func after_each() -> void:
	QuestRegistry._quests.erase(_quest.quest_id)
	QuestRegistry._quests.erase("teste_proxima")
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []


func test_coletar_item_que_bate_avanca_progresso() -> void:
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_coletar_item("pedra", 2)

	assert_eq(GameState.progresso_quest_atual, 2)


func test_coletar_item_que_nao_bate_nao_avanca() -> void:
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_coletar_item("tronco", 5)

	assert_eq(GameState.progresso_quest_atual, 0)


func test_capturar_criatura_avanca_quest_de_captura() -> void:
	_quest.tipo = "capturar"
	_quest.alvo_id = "brotinho"
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_capturar_criatura("brotinho")

	assert_eq(GameState.progresso_quest_atual, 1)


func test_derrotar_criatura_avanca_quest_de_derrota() -> void:
	_quest.tipo = "derrotar"
	_quest.alvo_id = "pedrolim"
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_derrotar_criatura("pedrolim")

	assert_eq(GameState.progresso_quest_atual, 1)


func test_colocar_bloco_avanca_quest_de_construcao() -> void:
	_quest.tipo = "construir"
	_quest.alvo_id = "3"
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_colocar_bloco(Vector3i(1, 1, 1), 3)

	assert_eq(GameState.progresso_quest_atual, 1)


func test_sem_quest_ativa_nao_faz_nada() -> void:
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)

	tracker._ao_coletar_item("pedra", 2)

	assert_eq(GameState.progresso_quest_atual, 0)


func test_completar_quest_entrega_recompensa_de_itens() -> void:
	_quest.recompensa_itens = {"tabua": 5}
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_coletar_item("pedra", 3)

	assert_eq(GameState.inventario_mochila.contar("tabua"), 5)


func test_completar_quest_marca_como_concluida() -> void:
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_coletar_item("pedra", 3)

	assert_true(GameState.quests_concluidas.has("teste_quest"))


func test_completar_quest_avanca_para_proxima() -> void:
	var proxima := QuestDef.new()
	proxima.quest_id = "teste_proxima"
	QuestRegistry._quests[proxima.quest_id] = proxima
	_quest.proxima_quest_id = "teste_proxima"

	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_coletar_item("pedra", 3)

	assert_eq(GameState.quest_atual_id, "teste_proxima")
	assert_eq(GameState.progresso_quest_atual, 0)


func test_completar_quest_sem_proxima_limpa_quest_atual() -> void:
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_coletar_item("pedra", 3)

	assert_eq(GameState.quest_atual_id, "")


func test_quest_repetivel_zera_progresso_mas_continua_ativa() -> void:
	_quest.repetivel = true
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_coletar_item("pedra", 3)

	assert_eq(GameState.quest_atual_id, "teste_quest")
	assert_eq(GameState.progresso_quest_atual, 0)
	assert_true(GameState.quests_concluidas.has("teste_quest"))


func test_craftar_receita_que_bate_avanca_quest_de_craftar() -> void:
	_quest.tipo = "craftar"
	_quest.alvo_id = "tabua"
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("teste_quest")

	tracker._ao_craftar_receita("tabua")

	assert_eq(GameState.progresso_quest_atual, 1)
