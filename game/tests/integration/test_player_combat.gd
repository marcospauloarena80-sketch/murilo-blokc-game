extends GutTest
## Ver docs/04-ROADMAP.md F7 (espada de pedra + combate) e docs/07-DECISOES.md ADR-020.
## Mesmo padrão de test_player_hotbar_tools.gd: chama lógica privada direto,
## sem simular raycast/clique (limitação conhecida de input simulado).

const PlayerScene := preload("res://entities/player/player.tscn")


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.hotbar_selecionado = 0


func test_sem_arma_dano_e_mao_nua() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	assert_eq(player._dano_de_ataque_atual(), Player.DANO_MAO_NUA)


func test_com_espada_de_pedra_dano_e_o_da_espada() -> void:
	GameState.inventario_hotbar.adicionar("espada_pedra", 1)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	assert_eq(player._dano_de_ataque_atual(), 4)


func test_com_ferramenta_de_mineracao_selecionada_dano_e_mao_nua() -> void:
	GameState.inventario_hotbar.adicionar("picareta_pedra", 1)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	assert_eq(player._dano_de_ataque_atual(), Player.DANO_MAO_NUA)


func test_espada_de_pedra_crafta_com_2_pedra_1_graveto_na_bancada() -> void:
	var receita := RecipeRegistry.get_receita("espada_pedra")
	assert_not_null(receita)
	assert_eq(receita.ingredientes.get("pedra"), 2)
	assert_eq(receita.ingredientes.get("graveto"), 1)
	assert_true(receita.exige_bancada)

	var mochila := InventoryModel.new(24)
	mochila.adicionar("pedra", 2)
	mochila.adicionar("graveto", 1)
	var craft_service := CraftService.new()

	assert_true(craft_service.pode_craftar(mochila, receita, true))
	craft_service.craftar(mochila, receita, true)

	assert_eq(mochila.contar("espada_pedra"), 1)
	assert_eq(mochila.contar("pedra"), 0)
	assert_eq(mochila.contar("graveto"), 0)
