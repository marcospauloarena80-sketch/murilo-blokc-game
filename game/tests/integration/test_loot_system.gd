extends GutTest
## Ver docs/02-ARQUITETURA.md §4.4 (drops + ímã) e docs/08-PLANO-TESTES.md.

const ItemDropScene := preload("res://entities/props/item_drop.tscn")


func test_quebrar_bloco_spawna_drop_com_item_certo() -> void:
	var spawner := LootSpawner.new()
	add_child_autofree(spawner)

	EventBus.block_broken.emit(Vector3i(5, 10, 5), 3)  # pedra -> drop "pedra"

	assert_eq(spawner.get_child_count(), 1)
	var drop: ItemDrop = spawner.get_child(0)
	assert_eq(drop.item_id, "pedra")
	assert_eq(drop.quantidade, 1)


func test_bloco_sem_drop_nao_spawna_nada() -> void:
	var spawner := LootSpawner.new()
	add_child_autofree(spawner)

	EventBus.block_broken.emit(Vector3i(0, 0, 0), 999)  # id inexistente -> BlockRegistry retorna null

	assert_eq(spawner.get_child_count(), 0)


func test_coletar_drop_adiciona_ao_inventario_e_remove_o_drop() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)

	var drop := ItemDropScene.instantiate() as ItemDrop
	drop.item_id = "tronco"
	drop.quantidade = 3
	add_child_autofree(drop)

	var jogador_falso := Node3D.new()
	jogador_falso.add_to_group("player")
	add_child_autofree(jogador_falso)

	drop._ao_tocar_corpo(jogador_falso)

	assert_eq(GameState.inventario_mochila.contar("tronco"), 3, "coleta vai pra mochila primeiro")
	assert_true(drop.is_queued_for_deletion())


func test_quebrar_bau_dropa_conteudo_e_limpa_registro() -> void:
	GameState.baus = {}
	var spawner := LootSpawner.new()
	add_child_autofree(spawner)

	var chave := GameState.chave_posicao(Vector3i(2, 10, 2))
	var bau := GameState.obter_bau(chave)
	bau.adicionar("pedra", 4)

	EventBus.block_broken.emit(Vector3i(2, 10, 2), 8)  # bau

	# 1 drop do conteúdo (pedra) + 1 drop do próprio bloco baú
	assert_eq(spawner.get_child_count(), 2)
	assert_false(GameState.baus.has(chave), "registro do baú devia ser removido ao quebrar")


func test_quebrar_bau_vazio_so_dropa_o_proprio_bloco() -> void:
	GameState.baus = {}
	var spawner := LootSpawner.new()
	add_child_autofree(spawner)

	EventBus.block_broken.emit(Vector3i(9, 10, 9), 8)  # bau sem registro em GameState.baus

	assert_eq(spawner.get_child_count(), 1)


func test_corpo_que_nao_e_player_nao_coleta() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)

	var drop := ItemDropScene.instantiate() as ItemDrop
	drop.item_id = "tronco"
	drop.quantidade = 3
	add_child_autofree(drop)

	var outro_corpo := Node3D.new()
	add_child_autofree(outro_corpo)

	drop._ao_tocar_corpo(outro_corpo)

	assert_eq(GameState.inventario_hotbar.contar("tronco"), 0)
	assert_false(drop.is_queued_for_deletion())
