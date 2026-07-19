extends GutTest
## Ver docs/04-ROADMAP.md F4 — critério "quebrar árvore → tábuas → bancada →
## picareta de pedra" ponta a ponta. Os testes de cada peça já existem
## (worldgen, chunk manager, craft service); o que faltava provar é o elo
## real entre eles: ChunkManager.set_block -> EventBus.block_broken ->
## LootSpawner -> ItemDrop -> coleta -> GameState.inventario_mochila.


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.hotbar_selecionado = 0


func test_quebrar_bloco_real_ate_material_utilizavel_no_craft() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 99
	add_child_autofree(cm)

	var spawner := LootSpawner.new()
	add_child_autofree(spawner)

	var jogador_falso := Node3D.new()
	jogador_falso.add_to_group("player")
	add_child_autofree(jogador_falso)

	# planta um "tronco" numa posição conhecida (simula a árvore já existir)
	cm.set_block(Vector3i(2, 40, 2), 4)
	# player minera: quebra o bloco de verdade via a API que o player usa
	cm.set_block(Vector3i(2, 40, 2), BlockRegistry.AR_ID)

	assert_eq(spawner.get_child_count(), 1, "quebrar tronco deveria spawnar 1 drop")
	var drop: ItemDrop = spawner.get_child(0)
	assert_eq(drop.item_id, "tronco")

	drop._ao_tocar_corpo(jogador_falso)
	assert_eq(GameState.inventario_mochila.contar("tronco"), 1, "coleta deveria ir pra mochila")

	var servico := CraftService.new()
	var craftou_tabua := servico.craftar(
		GameState.inventario_mochila, RecipeRegistry.get_receita("tabua"), false
	)
	assert_true(craftou_tabua, "material minerado de verdade deveria servir pro craft")
	assert_eq(GameState.inventario_mochila.contar("tabua"), 4)


func test_loop_completo_ate_picareta_de_pedra_via_gamestate() -> void:
	# Cadeia completa via GameState.adicionar_item (caminho real de coleta),
	# fechando com a picareta indo pra hotbar e virando ferramenta selecionável.
	GameState.adicionar_item("tronco", 2)
	GameState.adicionar_item("pedra", 3)

	var servico := CraftService.new()
	var mochila := GameState.inventario_mochila

	assert_true(servico.craftar(mochila, RecipeRegistry.get_receita("tabua"), false))
	assert_true(servico.craftar(mochila, RecipeRegistry.get_receita("tabua"), false))
	assert_eq(mochila.contar("tabua"), 8)

	assert_true(servico.craftar(mochila, RecipeRegistry.get_receita("bancada"), false))
	assert_true(GameState.tem_bancada())

	assert_true(servico.craftar(mochila, RecipeRegistry.get_receita("graveto"), false))
	assert_true(
		servico.craftar(
			mochila, RecipeRegistry.get_receita("picareta_pedra"), GameState.tem_bancada()
		)
	)
	assert_eq(mochila.contar("picareta_pedra"), 1)

	var indice_picareta := -1
	for i in range(24):
		if mochila.get_item_id(i) == "picareta_pedra":
			indice_picareta = i
			break
	assert_ne(indice_picareta, -1)

	GameState.mover_para_hotbar(indice_picareta)
	assert_eq(GameState.inventario_hotbar.contar("picareta_pedra"), 1)
	assert_eq(mochila.contar("picareta_pedra"), 0)
