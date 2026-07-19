extends GutTest
## Ver docs/02-ARQUITETURA.md §4.4 e docs/08-PLANO-TESTES.md.


func test_inventario_novo_comeca_vazio() -> void:
	var inv := InventoryModel.new(8)
	for i in range(8):
		assert_true(inv.slot_vazio(i))


func test_adicionar_em_slot_vazio() -> void:
	var inv := InventoryModel.new(8)
	var sobra := inv.adicionar("pedra", 10)
	assert_eq(sobra, 0)
	assert_eq(inv.contar("pedra"), 10)


func test_adicionar_empilha_no_slot_existente() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("pedra", 10)
	inv.adicionar("pedra", 5)
	assert_eq(inv.contar("pedra"), 15)
	var slots_usados := 0
	for i in range(8):
		if not inv.slot_vazio(i):
			slots_usados += 1
	assert_eq(slots_usados, 1, "deveria ter empilhado no mesmo slot")


func test_adicionar_respeita_stack_maximo_e_retorna_sobra() -> void:
	var inv := InventoryModel.new(8)
	var sobra := inv.adicionar("pedra", 70)  # stack_maximo pedra = 64
	assert_eq(sobra, 0, "deveria abrir 2º slot pro excedente")
	assert_eq(inv.contar("pedra"), 70)


func test_adicionar_em_inventario_cheio_retorna_sobra_explicita() -> void:
	var inv := InventoryModel.new(1)
	inv.adicionar("pedra", 64)
	var sobra := inv.adicionar("pedra", 10)
	assert_eq(sobra, 10, "inventário cheio não deve aceitar mais")
	assert_eq(inv.contar("pedra"), 64)


func test_adicionar_item_invalido_nao_quebra() -> void:
	var inv := InventoryModel.new(8)
	var sobra := inv.adicionar("item_que_nao_existe", 5)
	assert_eq(sobra, 5)


func test_remover_com_quantidade_suficiente() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("pedra", 10)
	var removeu := inv.remover("pedra", 4)
	assert_true(removeu)
	assert_eq(inv.contar("pedra"), 6)


func test_remover_sem_quantidade_suficiente_nao_remove_nada() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("pedra", 3)
	var removeu := inv.remover("pedra", 10)
	assert_false(removeu)
	assert_eq(inv.contar("pedra"), 3, "não deve remover parcialmente")


func test_remover_zera_e_limpa_o_slot() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("pedra", 5)
	inv.remover("pedra", 5)
	assert_eq(inv.contar("pedra"), 0)
	assert_true(inv.slot_vazio(0))


func test_mover_para_slot_vazio() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("pedra", 5)
	inv.mover(0, 3)
	assert_true(inv.slot_vazio(0))
	assert_eq(inv.get_item_id(3), "pedra")
	assert_eq(inv.get_quantidade(3), 5)


func test_mover_mesmo_item_empilha() -> void:
	var inv := InventoryModel.new(8)
	inv._slots[0] = {"item_id": "pedra", "quantidade": 10}
	inv._slots[1] = {"item_id": "pedra", "quantidade": 5}
	inv.mover(1, 0)
	assert_eq(inv.get_quantidade(0), 15)
	assert_true(inv.slot_vazio(1))


func test_mover_itens_diferentes_troca() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("pedra", 5)
	inv.adicionar("tronco", 3)
	inv.mover(0, 1)
	assert_eq(inv.get_item_id(0), "tronco")
	assert_eq(inv.get_item_id(1), "pedra")
