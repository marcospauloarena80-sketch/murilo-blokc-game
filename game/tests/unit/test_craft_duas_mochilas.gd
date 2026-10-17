extends GutTest
## Ciclo 6 (Frente 6E): o craft conta hotbar + mochila. CraftService ganha
## pode_craftar_em/craftar_em com um segundo inventário opcional (consome do
## principal primeiro, entrega o resultado nele e a sobra no extra); o
## GameState embrulha isso com a mochila como principal e a hotbar como extra.


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.insignias_conquistadas = []


func after_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.insignias_conquistadas = []


func test_pode_craftar_em_soma_os_ingredientes_dos_dois_inventarios() -> void:
	var mochila := InventoryModel.new(24)
	var hotbar := InventoryModel.new(8)
	mochila.adicionar("tabua", 2)
	hotbar.adicionar("tabua", 1)
	hotbar.adicionar("graveto", 2)
	var servico := CraftService.new()
	var receita := RecipeRegistry.get_receita("picareta_madeira")

	assert_false(servico.pode_craftar(mochila, receita, true), "só a mochila não basta")
	assert_true(servico.pode_craftar_em(mochila, hotbar, receita, true))


func test_craftar_em_consome_do_principal_primeiro_e_depois_do_extra() -> void:
	var mochila := InventoryModel.new(24)
	var hotbar := InventoryModel.new(8)
	mochila.adicionar("tabua", 2)
	hotbar.adicionar("tabua", 3)
	hotbar.adicionar("graveto", 2)
	var servico := CraftService.new()
	var receita := RecipeRegistry.get_receita("picareta_madeira")

	assert_true(servico.craftar_em(mochila, hotbar, receita, true))

	assert_eq(mochila.contar("tabua"), 0, "gasta as 2 tábuas da mochila primeiro")
	assert_eq(hotbar.contar("tabua"), 2, "só 1 tábua sai da hotbar")
	assert_eq(hotbar.contar("graveto"), 0)
	assert_eq(mochila.contar("picareta_madeira"), 1, "resultado vai pro principal")


func test_craftar_em_sem_extra_funciona_como_craftar() -> void:
	var mochila := InventoryModel.new(24)
	mochila.adicionar("tronco", 1)
	var servico := CraftService.new()
	var receita := RecipeRegistry.get_receita("tabua")

	assert_true(servico.craftar_em(mochila, null, receita, false))

	assert_eq(mochila.contar("tronco"), 0)
	assert_eq(mochila.contar("tabua"), 4)


func test_craftar_em_sem_ingredientes_nao_consome_nada() -> void:
	var mochila := InventoryModel.new(24)
	var hotbar := InventoryModel.new(8)
	hotbar.adicionar("tabua", 1)
	var servico := CraftService.new()
	var receita := RecipeRegistry.get_receita("picareta_madeira")

	assert_false(servico.craftar_em(mochila, hotbar, receita, true))

	assert_eq(hotbar.contar("tabua"), 1)


func test_game_state_crafta_com_ingrediente_so_na_hotbar() -> void:
	GameState.inventario_hotbar.adicionar("tronco", 1)
	var receita := RecipeRegistry.get_receita("tabua")

	assert_true(GameState.pode_craftar(receita))
	assert_true(GameState.craftar(receita))

	assert_eq(GameState.inventario_hotbar.contar("tronco"), 0, "consome da hotbar")
	assert_eq(GameState.inventario_mochila.contar("tabua"), 4, "resultado vai pra mochila")


func test_game_state_nao_crafta_sem_ingredientes() -> void:
	var receita := RecipeRegistry.get_receita("tabua")

	assert_false(GameState.pode_craftar(receita))
	assert_false(GameState.craftar(receita))


func test_game_state_aceita_bancada_na_hotbar() -> void:
	GameState.inventario_hotbar.adicionar("bancada", 1)
	GameState.inventario_mochila.adicionar("tabua", 3)
	GameState.inventario_mochila.adicionar("graveto", 2)
	var receita := RecipeRegistry.get_receita("picareta_madeira")

	assert_true(GameState.craftar(receita))

	assert_eq(GameState.inventario_mochila.contar("picareta_madeira"), 1)
	assert_eq(GameState.inventario_hotbar.contar("bancada"), 1, "a bancada não é consumida")


func test_game_state_respeita_receita_bloqueada_por_insignia() -> void:
	GameState.inventario_mochila.adicionar("cristal_dourado", 3)
	GameState.inventario_mochila.adicionar("graveto", 2)
	GameState.inventario_mochila.adicionar("bancada", 1)
	var receita := RecipeRegistry.get_receita("picareta_cristal_dourado")

	assert_false(GameState.pode_craftar(receita), "sem a insígnia da Arena não crafta")
	GameState.conquistar_insignia("pedra")
	assert_true(GameState.pode_craftar(receita))


func test_game_state_sobra_do_resultado_vai_pra_hotbar_com_mochila_cheia() -> void:
	GameState.inventario_mochila = InventoryModel.new(1)
	GameState.inventario_mochila.adicionar("pedra", 1)
	GameState.inventario_hotbar.adicionar("tronco", 1)
	var receita := RecipeRegistry.get_receita("tabua")

	assert_true(GameState.craftar(receita))

	assert_eq(GameState.inventario_mochila.contar("tabua"), 0, "mochila cheia")
	assert_eq(GameState.inventario_hotbar.contar("tabua"), 4, "sobra cai na hotbar")
