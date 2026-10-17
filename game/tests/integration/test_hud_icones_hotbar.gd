extends GutTest
## Hotbar com ícones (Ciclo 6, 6B): o slot mostra o ícone do item num
## TextureRect e a quantidade num Label no canto, sem texto no botão. Os
## estilos de seleção continuam (ver test_hud_aviso_hotbar.gd).

const CENA_HUD := preload("res://ui/hud/hud.tscn")


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.hotbar_selecionado = 0


func after_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)


func _criar_hud() -> Hud:
	var hud: Hud = CENA_HUD.instantiate()
	add_child_autofree(hud)
	return hud


func _filho_do_tipo(no: Node, tipo: String) -> Node:
	for filho: Node in no.get_children():
		if filho.is_class(tipo):
			return filho
	return null


func test_slot_com_pedra_mostra_icone_e_quantidade() -> void:
	GameState.inventario_hotbar.adicionar("pedra", 5)
	var hud := _criar_hud()

	hud._atualizar_slot(0)

	var botao: Button = hud._botoes[0]
	var icone := _filho_do_tipo(botao, "TextureRect") as TextureRect
	var rotulo := _filho_do_tipo(botao, "Label") as Label
	assert_not_null(icone, "slot precisa de um TextureRect filho")
	assert_not_null(rotulo, "slot precisa de um Label filho")
	if icone == null or rotulo == null:
		return
	assert_not_null(icone.texture, "ícone da pedra")
	assert_same(icone.texture, IconesItens.textura("pedra"))
	assert_eq(rotulo.text, "5")
	assert_eq(botao.text, "", "o botão não mostra mais texto")
	assert_eq(botao.tooltip_text, "Pedra")


func test_slot_vazio_fica_sem_icone_nem_quantidade() -> void:
	GameState.inventario_hotbar.adicionar("pedra", 5)
	var hud := _criar_hud()
	hud._atualizar_slot(0)

	GameState.inventario_hotbar = InventoryModel.new(8)
	hud._atualizar_slot(0)

	var botao: Button = hud._botoes[0]
	var icone := _filho_do_tipo(botao, "TextureRect") as TextureRect
	var rotulo := _filho_do_tipo(botao, "Label") as Label
	assert_null(icone.texture)
	assert_eq(rotulo.text, "")
	assert_eq(botao.tooltip_text, "")


func test_icone_nao_rouba_o_clique_nem_o_estilo_do_botao() -> void:
	GameState.inventario_hotbar.adicionar("tronco", 2)
	var hud := _criar_hud()
	hud._atualizar_slot(0)

	var botao: Button = hud._botoes[0]
	var icone := _filho_do_tipo(botao, "TextureRect") as TextureRect
	var rotulo := _filho_do_tipo(botao, "Label") as Label
	assert_eq(icone.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(rotulo.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_same(botao.get_theme_stylebox("normal"), hud._estilos_selecionado[0])
