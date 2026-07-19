extends GutTest
## Ver docs/07-DECISOES.md ADR-022 — craftar com sucesso emite
## EventBus.recipe_crafted (usado pelo QuestTracker pra missões tipo "craftar").

const InventoryScreenScene := preload("res://ui/inventory_screen/inventory_screen.tscn")


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)


func test_craftar_com_sucesso_emite_recipe_crafted() -> void:
	GameState.inventario_mochila.adicionar("tronco", 1)
	var tela := InventoryScreenScene.instantiate() as InventoryScreen
	add_child_autofree(tela)

	var recebido: Array = [""]
	var callback := func(id: String) -> void: recebido[0] = id
	EventBus.recipe_crafted.connect(callback)

	tela._ao_craftar(RecipeRegistry.get_receita("tabua"))

	EventBus.recipe_crafted.disconnect(callback)
	assert_eq(recebido[0], "tabua")


func test_craftar_sem_sucesso_nao_emite_recipe_crafted() -> void:
	var tela := InventoryScreenScene.instantiate() as InventoryScreen
	add_child_autofree(tela)

	var recebido: Array = [""]
	var callback := func(id: String) -> void: recebido[0] = id
	EventBus.recipe_crafted.connect(callback)

	tela._ao_craftar(RecipeRegistry.get_receita("tabua"))

	EventBus.recipe_crafted.disconnect(callback)
	assert_eq(recebido[0], "")
