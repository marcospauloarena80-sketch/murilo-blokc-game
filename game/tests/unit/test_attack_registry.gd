extends GutTest
## Ver docs/01-GDD.md §9/§11 e docs/04-ROADMAP.md F8 ("12+ ataques").

const ELEMENTOS := ["pedra", "mato", "brasa", "gota", "vento", "faisca"]


func test_existem_12_ataques() -> void:
	assert_eq(AttackRegistry.todos_os_ids().size(), 12)


func test_cada_elemento_tem_2_ataques() -> void:
	for elemento: String in ELEMENTOS:
		var contagem := 0
		for id: String in AttackRegistry.todos_os_ids():
			if AttackRegistry.get_ataque(id).elemento == elemento:
				contagem += 1
		assert_eq(contagem, 2, "elemento %s deveria ter 2 ataques" % elemento)


func test_ataque_inexistente_retorna_null() -> void:
	assert_null(AttackRegistry.get_ataque("nao_existe"))


func test_ataque_pesado_custa_mais_energia_que_o_basico() -> void:
	var basico := AttackRegistry.get_ataque("pedra_investida")
	var pesado := AttackRegistry.get_ataque("pedra_avalanche")
	assert_gt(pesado.custo_energia, basico.custo_energia)
	assert_gt(pesado.poder, basico.poder)
