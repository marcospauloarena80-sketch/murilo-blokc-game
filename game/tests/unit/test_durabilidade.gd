extends GutTest
## Ciclo 8 (8E): durabilidade por slot, save antigo sem o campo e barrinha do slot.


func test_valores_de_durabilidade_dos_itens() -> void:
	assert_eq(ItemRegistry.get_item("picareta_madeira").durabilidade, 60)
	assert_eq(ItemRegistry.get_item("picareta_pedra").durabilidade, 130)
	assert_eq(ItemRegistry.get_item("picareta_ferrite").durabilidade, 250)
	assert_eq(ItemRegistry.get_item("picareta_cristal_dourado").durabilidade, 1000)
	assert_eq(ItemRegistry.get_item("pedra").durabilidade, 0, "bloco não gasta")


func test_ferramenta_nova_tem_durabilidade_cheia() -> void:
	var inv := InventoryModel.new(4)
	inv.adicionar("picareta_madeira", 1)
	assert_eq(inv.get_durabilidade(0), 60)
	assert_eq(inv.fracao_durabilidade(0), 1.0)


func test_gastar_reduz_e_ao_zerar_o_item_some() -> void:
	var inv := InventoryModel.new(4)
	inv.adicionar("picareta_madeira", 1)
	for i in range(59):
		assert_false(inv.gastar_durabilidade(0))
	assert_eq(inv.get_durabilidade(0), 1)
	assert_true(inv.gastar_durabilidade(0), "o 60º uso quebra")
	assert_true(inv.slot_vazio(0))


func test_item_sem_desgaste_nunca_quebra() -> void:
	var inv := InventoryModel.new(4)
	inv.adicionar("pedra", 3)
	assert_false(inv.gastar_durabilidade(0))
	assert_eq(inv.get_quantidade(0), 3)
	assert_eq(inv.fracao_durabilidade(0), 1.0)


func test_durabilidade_sobrevive_ao_round_trip_json() -> void:
	var inv := InventoryModel.new(4)
	inv.adicionar("picareta_pedra", 1)
	inv.gastar_durabilidade(0, 30)
	var texto := JSON.stringify(inv.serializar())
	var lido: Array = JSON.parse_string(texto)
	var novo := InventoryModel.new(4)
	novo.carregar_serializado(lido)
	assert_eq(novo.get_durabilidade(0), 100)
	assert_typeof(novo.get_durabilidade(0), TYPE_INT)


func test_save_antigo_sem_campo_carrega_com_durabilidade_cheia() -> void:
	var novo := InventoryModel.new(4)
	novo.carregar_serializado([{"item_id": "picareta_ferrite", "quantidade": 1}])
	assert_eq(novo.get_durabilidade(0), 250)
	assert_eq(novo.fracao_durabilidade(0), 1.0)


func test_trocar_de_slot_leva_a_durabilidade_junto() -> void:
	var inv := InventoryModel.new(4)
	inv.adicionar("picareta_madeira", 1)
	inv.gastar_durabilidade(0, 10)
	inv.mover(0, 2)
	assert_eq(inv.get_durabilidade(2), 50)


func test_slot_item_mostra_barra_so_quando_gasta() -> void:
	var botao := Button.new()
	add_child_autofree(botao)
	var slot := SlotItem.decorar(botao)
	slot.mostrar("picareta_madeira", 1, 1.0)
	assert_false(slot.barra_fundo.visible, "cheia: sem barra")
	slot.mostrar("picareta_madeira", 1, 0.5)
	assert_true(slot.barra_fundo.visible)
	assert_almost_eq(slot.barra_preenchimento.anchor_right, 0.5, 0.001)
	slot.mostrar("", 0)
	assert_false(slot.barra_fundo.visible, "slot vazio: sem barra")
