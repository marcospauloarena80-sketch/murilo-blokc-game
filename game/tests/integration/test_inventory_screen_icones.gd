extends GutTest
## Mochila e baú com ícones (Ciclo 6, 6B): slot mostra ícone + quantidade e o
## nome do item no tooltip (antes era o texto "tronco\n3"); a linha de receita
## mostra o ícone do resultado, o nome e "Nx [ícone]" por ingrediente.

const CENA_MOCHILA := preload("res://ui/inventory_screen/inventory_screen.tscn")
const CENA_BAU := preload("res://ui/chest_screen/chest_screen.tscn")


func before_each() -> void:
	GameState.baus = {}
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)


func after_each() -> void:
	GameState.baus = {}
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.mudar_estado(GameState.State.MENU)


func _filho_do_tipo(no: Node, tipo: String) -> Node:
	for filho: Node in no.get_children():
		if filho.is_class(tipo):
			return filho
	return null


func _filhos_do_tipo(no: Node, tipo: String) -> Array[Node]:
	var achados: Array[Node] = []
	for filho: Node in no.get_children():
		if filho.is_class(tipo):
			achados.append(filho)
	return achados


func test_slot_da_mochila_mostra_icone_quantidade_e_nome_no_tooltip() -> void:
	GameState.inventario_mochila.adicionar("tronco", 3)
	var tela := CENA_MOCHILA.instantiate() as InventoryScreen
	add_child_autofree(tela)

	tela._atualizar()

	var botao: Button = tela._botoes_mochila[0]
	var icone := _filho_do_tipo(botao, "TextureRect") as TextureRect
	var rotulo := _filho_do_tipo(botao, "Label") as Label
	assert_not_null(icone)
	assert_not_null(rotulo)
	if icone == null or rotulo == null:
		return
	assert_same(icone.texture, IconesItens.textura("tronco"))
	assert_eq(rotulo.text, "3")
	assert_eq(botao.text, "", "sem o id escrito no botão")
	assert_eq(botao.tooltip_text, "Tronco")
	var vazio: Button = tela._botoes_mochila[1]
	assert_null((_filho_do_tipo(vazio, "TextureRect") as TextureRect).texture)
	assert_eq((_filho_do_tipo(vazio, "Label") as Label).text, "")


func test_linha_de_receita_mostra_icone_do_resultado_nome_e_ingredientes() -> void:
	var tela := CENA_MOCHILA.instantiate() as InventoryScreen
	add_child_autofree(tela)
	var receitas: Array[RecipeDef] = RecipeRegistry.todas()
	var indice: int = -1
	for i: int in range(receitas.size()):
		if receitas[i].id == "picareta_madeira":
			indice = i
	assert_gt(indice, -1, "receita picareta_madeira existe")

	var linha: HBoxContainer = tela._lista_receitas.get_child(indice)
	var icones: Array[Node] = _filhos_do_tipo(linha, "TextureRect")
	var rotulos: Array[Node] = _filhos_do_tipo(linha, "Label")
	assert_eq(icones.size(), 3, "ícone do resultado + 2 ingredientes")
	assert_same((icones[0] as TextureRect).texture, IconesItens.textura("picareta_madeira"))
	assert_eq((rotulos[0] as Label).text, "Picareta de Madeira")
	var textos: Array[String] = []
	var texturas: Array[Texture2D] = []
	for k: int in range(1, icones.size()):
		textos.append((rotulos[k] as Label).text)
		texturas.append((icones[k] as TextureRect).texture)
	assert_true(textos.has("3x") and textos.has("2x"), "quantidades: %s" % str(textos))
	assert_true(texturas.has(IconesItens.textura("tabua")), "ícone da tábua")
	assert_true(texturas.has(IconesItens.textura("graveto")), "ícone do graveto")
	for icone: Node in icones:
		assert_eq((icone as TextureRect).custom_minimum_size, Vector2(20, 20))
	var botao: Button = linha.get_child(linha.get_child_count() - 1)
	assert_eq(botao.text, "Craftar")


func test_botao_craftar_continua_refletindo_se_da_pra_craftar() -> void:
	var tela := CENA_MOCHILA.instantiate() as InventoryScreen
	add_child_autofree(tela)
	var receitas: Array[RecipeDef] = RecipeRegistry.todas()
	var indice: int = -1
	for i: int in range(receitas.size()):
		if receitas[i].id == "tabua":
			indice = i
	var linha: HBoxContainer = tela._lista_receitas.get_child(indice)
	var botao: Button = linha.get_child(linha.get_child_count() - 1)

	tela._atualizar()
	assert_true(botao.disabled, "sem tronco não crafta tábua")
	GameState.inventario_mochila.adicionar("tronco", 1)
	tela._atualizar()
	assert_false(botao.disabled, "com tronco crafta tábua")


func test_slots_do_bau_e_da_mochila_na_tela_de_bau_mostram_icones() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)
	GameState.inventario_mochila.adicionar("maca", 4)
	GameState.obter_bau("1,2,3").adicionar("carvao", 7)
	var tela := CENA_BAU.instantiate() as ChestScreen
	add_child_autofree(tela)

	tela._abrir("1,2,3")

	var slot_bau: Button = tela._botoes_bau[0]
	var slot_mochila: Button = tela._botoes_mochila[0]
	assert_same(
		(_filho_do_tipo(slot_bau, "TextureRect") as TextureRect).texture,
		IconesItens.textura("carvao")
	)
	assert_eq((_filho_do_tipo(slot_bau, "Label") as Label).text, "7")
	assert_eq(slot_bau.tooltip_text, "Carvão")
	assert_same(
		(_filho_do_tipo(slot_mochila, "TextureRect") as TextureRect).texture,
		IconesItens.textura("maca")
	)
	assert_eq((_filho_do_tipo(slot_mochila, "Label") as Label).text, "4")
	assert_eq(slot_bau.text, "")
	tela._fechar()
