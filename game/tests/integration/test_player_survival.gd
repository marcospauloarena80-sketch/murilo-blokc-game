extends GutTest
## Ver docs/01-GDD.md §3 (fome/energia/comida) e docs/04-ROADMAP.md F6.
## Testa lógica privada diretamente (padrão já usado em
## test_player_hotbar_tools.gd) em vez de simular input entre frames.

const PlayerScene := preload("res://entities/player/player.tscn")


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.hotbar_selecionado = 0
	GameState.fome_atual = GameState.fome_maxima
	GameState.energia_atual = GameState.energia_maxima


func after_each() -> void:
	GameState.fome_atual = GameState.fome_maxima
	GameState.energia_atual = GameState.energia_maxima


func test_comer_maca_restaura_fome_e_consome_item() -> void:
	GameState.fome_atual = 10
	GameState.inventario_hotbar.adicionar("maca", 2)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._tentar_comer()

	assert_gt(GameState.fome_atual, 10, "fome deveria ter aumentado")
	assert_eq(GameState.inventario_hotbar.contar("maca"), 1, "deveria ter consumido 1 maçã")


func test_comer_com_fome_cheia_nao_consome_item() -> void:
	GameState.fome_atual = GameState.fome_maxima
	GameState.inventario_hotbar.adicionar("maca", 1)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._tentar_comer()

	assert_eq(GameState.fome_atual, GameState.fome_maxima)
	assert_eq(GameState.inventario_hotbar.contar("maca"), 1, "não deveria desperdiçar comida")


func test_comer_item_nao_comestivel_nao_faz_nada() -> void:
	GameState.fome_atual = 5
	GameState.inventario_hotbar.adicionar("pedra", 1)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._tentar_comer()

	assert_eq(GameState.fome_atual, 5)
	assert_eq(GameState.inventario_hotbar.contar("pedra"), 1)


func test_comer_hotbar_vazia_nao_faz_nada() -> void:
	GameState.fome_atual = 5
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._tentar_comer()

	assert_eq(GameState.fome_atual, 5)


func test_energia_drena_1_ponto_apos_correr_o_suficiente() -> void:
	GameState.energia_atual = 10
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._atualizar_energia(Player.SEGUNDOS_POR_PONTO_ENERGIA, true)

	assert_eq(GameState.energia_atual, 9)


func test_energia_regenera_1_ponto_apos_parar_de_correr() -> void:
	GameState.energia_atual = 10
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._atualizar_energia(Player.SEGUNDOS_POR_PONTO_ENERGIA, false)

	assert_eq(GameState.energia_atual, 11)


func test_energia_nao_passa_do_zero() -> void:
	GameState.energia_atual = 0
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._atualizar_energia(Player.SEGUNDOS_POR_PONTO_ENERGIA, true)

	assert_eq(GameState.energia_atual, 0)


func test_energia_nao_passa_do_maximo() -> void:
	GameState.energia_atual = GameState.energia_maxima
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._atualizar_energia(Player.SEGUNDOS_POR_PONTO_ENERGIA, false)

	assert_eq(GameState.energia_atual, GameState.energia_maxima)


func test_energia_nao_muda_antes_do_intervalo() -> void:
	GameState.energia_atual = 10
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._atualizar_energia(Player.SEGUNDOS_POR_PONTO_ENERGIA * 0.5, true)

	assert_eq(GameState.energia_atual, 10)
