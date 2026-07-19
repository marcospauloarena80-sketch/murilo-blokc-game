extends GutTest
## Ver docs/01-GDD.md §13 e docs/07-DECISOES.md ADR-023 — receita exclusiva
## de Arena só desbloqueia depois da insígnia correspondente.

const InventoryScreenScene := preload("res://ui/inventory_screen/inventory_screen.tscn")


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.insignias_conquistadas = []


func test_receita_com_insignia_nao_crafta_sem_a_insignia() -> void:
	GameState.inventario_mochila.adicionar("cristal_dourado", 3)
	GameState.inventario_mochila.adicionar("graveto", 2)
	GameState.inventario_mochila.adicionar("bancada", 1)
	var tela := InventoryScreenScene.instantiate() as InventoryScreen
	add_child_autofree(tela)

	tela._ao_craftar(RecipeRegistry.get_receita("picareta_cristal_dourado"))

	assert_eq(GameState.inventario_mochila.contar("picareta_cristal_dourado"), 0)


func test_receita_com_insignia_crafta_depois_de_conquistada() -> void:
	GameState.conquistar_insignia("pedra")
	GameState.inventario_mochila.adicionar("cristal_dourado", 3)
	GameState.inventario_mochila.adicionar("graveto", 2)
	GameState.inventario_mochila.adicionar("bancada", 1)
	var tela := InventoryScreenScene.instantiate() as InventoryScreen
	add_child_autofree(tela)

	tela._ao_craftar(RecipeRegistry.get_receita("picareta_cristal_dourado"))

	assert_eq(GameState.inventario_mochila.contar("picareta_cristal_dourado"), 1)
