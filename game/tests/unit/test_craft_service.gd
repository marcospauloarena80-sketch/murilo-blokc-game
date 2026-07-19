extends GutTest
## Ver docs/02-ARQUITETURA.md §4.5 e docs/08-PLANO-TESTES.md.


func test_craftar_tabua_a_partir_de_tronco() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("tronco", 1)
	var servico := CraftService.new()
	var receita := RecipeRegistry.get_receita("tabua")
	assert_true(servico.pode_craftar(inv, receita, false))
	var sucesso := servico.craftar(inv, receita, false)
	assert_true(sucesso)
	assert_eq(inv.contar("tronco"), 0)
	assert_eq(inv.contar("tabua"), 4)


func test_nao_pode_craftar_sem_ingredientes() -> void:
	var inv := InventoryModel.new(8)
	var servico := CraftService.new()
	var receita := RecipeRegistry.get_receita("tabua")
	assert_false(servico.pode_craftar(inv, receita, false))
	assert_false(servico.craftar(inv, receita, false))


func test_craftar_sem_ingredientes_nao_consome_nada() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("tronco", 0)
	var servico := CraftService.new()
	var receita := RecipeRegistry.get_receita("tabua")
	servico.craftar(inv, receita, false)
	assert_eq(inv.contar("tabua"), 0, "não deveria ter craftado nada")


func test_receita_com_bancada_falha_sem_bancada() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("tabua", 3)
	inv.adicionar("graveto", 2)
	var servico := CraftService.new()
	var receita := RecipeRegistry.get_receita("picareta_madeira")
	assert_false(servico.pode_craftar(inv, receita, false), "exige bancada")
	assert_true(servico.pode_craftar(inv, receita, true), "com bancada deveria poder")


func test_craftar_picareta_madeira_com_bancada() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("tabua", 3)
	inv.adicionar("graveto", 2)
	var servico := CraftService.new()
	var receita := RecipeRegistry.get_receita("picareta_madeira")
	var sucesso := servico.craftar(inv, receita, true)
	assert_true(sucesso)
	assert_eq(inv.contar("tabua"), 0)
	assert_eq(inv.contar("graveto"), 0)
	assert_eq(inv.contar("picareta_madeira"), 1)


func test_receitas_do_mvp_existem() -> void:
	var ids := [
		"tabua",
		"graveto",
		"bancada",
		"picareta_madeira",
		"machado_madeira",
		"picareta_pedra",
		"cama",
		"bau",
		"tocha",
		"fornalha",
		"picareta_ferrite",
		"machado_ferrite",
		"maca_assada",
		"espada_pedra",
		"cubo_captura",
		"pocao_cura",
	]
	for id: String in ids:
		assert_not_null(RecipeRegistry.get_receita(id), "receita %s deveria existir" % id)
	assert_eq(RecipeRegistry.todas().size(), ids.size())


func test_craftar_cadeia_completa_arvore_ate_picareta_pedra() -> void:
	# Simula o loop MVP: madeira -> tábua -> graveto + pedra -> picareta de pedra
	var inv := InventoryModel.new(24)
	inv.adicionar("tronco", 1)
	inv.adicionar("pedra", 3)
	var servico := CraftService.new()

	assert_true(servico.craftar(inv, RecipeRegistry.get_receita("tabua"), false))
	assert_eq(inv.contar("tabua"), 4)

	assert_true(servico.craftar(inv, RecipeRegistry.get_receita("graveto"), false))
	assert_eq(inv.contar("graveto"), 4)
	assert_eq(inv.contar("tabua"), 2)

	assert_true(servico.craftar(inv, RecipeRegistry.get_receita("picareta_pedra"), true))
	assert_eq(inv.contar("picareta_pedra"), 1)
	assert_eq(inv.contar("pedra"), 0)
	assert_eq(inv.contar("graveto"), 2)
