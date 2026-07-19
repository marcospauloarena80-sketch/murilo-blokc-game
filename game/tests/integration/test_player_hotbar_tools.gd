extends GutTest
## Ver docs/07-DECISOES.md (MB-020, F4) — ferramentas afetam velocidade de quebra
## e colocar bloco usa o item selecionado na hotbar real (não mais o seletor
## numérico temporário do F2).

const PlayerScene := preload("res://entities/player/player.tscn")


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.hotbar_selecionado = 0


func test_sem_ferramenta_multiplicador_e_1() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	assert_eq(player._multiplicador_ferramenta_atual(), 1.0)


func test_com_picareta_de_pedra_selecionada_multiplicador_e_3_5() -> void:
	GameState.inventario_hotbar.adicionar("picareta_pedra", 1)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	assert_eq(player._multiplicador_ferramenta_atual(), 3.5)


func test_item_nao_ferramenta_selecionado_multiplicador_e_1() -> void:
	GameState.inventario_hotbar.adicionar("tabua", 5)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	assert_eq(player._multiplicador_ferramenta_atual(), 1.0)


func test_colocar_bloco_consome_item_placeavel_da_hotbar() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)

	GameState.inventario_hotbar.adicionar("pedra", 5)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._tentar_colocar_bloco(Vector3i(3, 40, 3))

	assert_eq(cm.get_block(Vector3i(3, 40, 3)), 3, "deveria ter colocado pedra")
	assert_eq(GameState.inventario_hotbar.contar("pedra"), 4, "deveria ter consumido 1")


func test_colocar_sem_item_na_hotbar_nao_faz_nada() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 2
	add_child_autofree(cm)

	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._tentar_colocar_bloco(Vector3i(3, 40, 3))

	assert_eq(cm.get_block(Vector3i(3, 40, 3)), BlockRegistry.AR_ID)


func test_colocar_item_nao_placeavel_nao_faz_nada() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 3
	add_child_autofree(cm)

	GameState.inventario_hotbar.adicionar("picareta_pedra", 1)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._tentar_colocar_bloco(Vector3i(3, 40, 3))

	assert_eq(cm.get_block(Vector3i(3, 40, 3)), BlockRegistry.AR_ID)
	assert_eq(
		GameState.inventario_hotbar.contar("picareta_pedra"), 1, "ferramenta não deve ser consumida"
	)
