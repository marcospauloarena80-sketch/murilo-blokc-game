extends GutTest
## Ver docs/01-GDD.md linha 48 (morte com drop recuperável) e docs/04-ROADMAP.md
## F6 (cama = respawn). Segue o padrão de test_main_save_flow.gd (instancia
## main.tscn, chama métodos privados direto) e test_player_hotbar_tools.gd
## (chama lógica privada do Player direto, sem simular input).

const MainScene := preload("res://scenes/main.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.vida_atual = GameState.vida_maxima
	GameState.ponto_respawn = Vector3(64, 45, 64)


func after_each() -> void:
	GameState.vida_atual = GameState.vida_maxima
	GameState.ponto_respawn = Vector3(64, 45, 64)


func _drenar_fila(main_instance: Node3D) -> void:
	var cm: ChunkManager = main_instance.get_node("ChunkManager")
	while cm.tem_chunks_pendentes():
		cm._process(0.0)


func test_morte_dropa_itens_da_mochila_e_limpa_mochila() -> void:
	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)
	_drenar_fila(main_instance)

	GameState.inventario_mochila.adicionar("pedra", 5)
	var loot_spawner: Node3D = main_instance.get_node("LootSpawner")
	var antes := loot_spawner.get_child_count()

	main_instance._processar_morte()

	assert_eq(loot_spawner.get_child_count(), antes + 1, "deveria ter dropado 1 item-drop")
	assert_true(GameState.inventario_mochila.slot_vazio(0))


func test_morte_preserva_hotbar() -> void:
	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)
	_drenar_fila(main_instance)

	GameState.inventario_hotbar.adicionar("tabua", 3)

	main_instance._processar_morte()

	assert_eq(GameState.inventario_hotbar.contar("tabua"), 3, "hotbar não deveria ser afetada")


func test_morte_restaura_vida_e_teleporta_pro_respawn() -> void:
	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)
	_drenar_fila(main_instance)

	GameState.vida_atual = 0
	GameState.ponto_respawn = Vector3(10, 50, 10)

	main_instance._processar_morte()

	assert_eq(GameState.vida_atual, GameState.vida_maxima)
	var player: Player = main_instance.get_node("Player")
	assert_eq(player.global_position, GameState.ponto_respawn)


func test_verificar_morte_nao_faz_nada_se_vida_positiva() -> void:
	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)
	_drenar_fila(main_instance)

	GameState.inventario_mochila.adicionar("pedra", 1)
	GameState.vida_atual = 10

	main_instance._verificar_morte()

	assert_false(GameState.inventario_mochila.slot_vazio(0), "não deveria ter morrido com vida > 0")


func test_interagir_com_cama_define_ponto_respawn() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 42
	add_child_autofree(cm)

	var pos := Vector3i(5, 40, 5)
	cm.set_block(pos, 7)  # id da cama (data/blocks/cama.tres)

	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._processar_interacao(pos)

	assert_eq(GameState.ponto_respawn, Vector3(pos) + Vector3(0.5, 1.0, 0.5))


func test_interagir_com_bloco_comum_nao_altera_respawn() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 43
	add_child_autofree(cm)

	var pos := Vector3i(6, 40, 6)
	cm.set_block(pos, 3)

	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	var respawn_antes := GameState.ponto_respawn
	player._processar_interacao(pos)

	assert_eq(GameState.ponto_respawn, respawn_antes)


func test_queda_pequena_nao_causa_dano() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	GameState.vida_atual = GameState.vida_maxima

	player._aplicar_dano_de_queda(2.0)

	assert_eq(GameState.vida_atual, GameState.vida_maxima)


func test_queda_no_limite_exato_nao_causa_dano() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	GameState.vida_atual = GameState.vida_maxima

	player._aplicar_dano_de_queda(Player.ALTURA_QUEDA_SEGURA)

	assert_eq(GameState.vida_atual, GameState.vida_maxima)


func test_queda_grande_causa_dano_proporcional() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	GameState.vida_atual = GameState.vida_maxima

	player._aplicar_dano_de_queda(Player.ALTURA_QUEDA_SEGURA + 4.0)

	assert_eq(GameState.vida_atual, GameState.vida_maxima - 4)
