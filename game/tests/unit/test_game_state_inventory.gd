extends GutTest
## Ver docs/07-DECISOES.md (F4) — GameState orquestra hotbar+mochila.


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)


func test_adicionar_item_vai_pra_mochila_primeiro() -> void:
	GameState.adicionar_item("pedra", 10)
	assert_eq(GameState.inventario_mochila.contar("pedra"), 10)
	assert_eq(GameState.inventario_hotbar.contar("pedra"), 0)


func test_tem_bancada_verifica_os_dois_inventarios() -> void:
	assert_false(GameState.tem_bancada())
	GameState.inventario_mochila.adicionar("bancada", 1)
	assert_true(GameState.tem_bancada())


func test_mover_para_hotbar_transfere_da_mochila() -> void:
	GameState.inventario_mochila.adicionar("picareta_pedra", 1)
	GameState.mover_para_hotbar(0)
	assert_eq(GameState.inventario_hotbar.contar("picareta_pedra"), 1)
	assert_eq(GameState.inventario_mochila.contar("picareta_pedra"), 0)


func test_mover_para_hotbar_de_slot_vazio_nao_quebra() -> void:
	GameState.mover_para_hotbar(5)
	assert_true(GameState.inventario_hotbar.slot_vazio(0), "nada deveria ter sido movido")
