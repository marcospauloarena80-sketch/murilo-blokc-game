extends GutTest
## Ver docs/01-GDD.md §9 ("Stats... Crescem por nível") e docs/07-DECISOES.md ADR-021.


func test_nivel_1_tem_stats_iguais_ao_base_da_especie() -> void:
	var instancia := CreatureInstance.new("pedrolim", 1)
	var def := CreatureRegistry.get_creature("pedrolim")
	assert_eq(instancia.forca_efetiva(), def.forca)
	assert_eq(instancia.guarda_efetiva(), def.guarda)
	assert_eq(instancia.agilidade_efetiva(), def.agilidade)
	assert_eq(instancia.vida_maxima_efetiva(), def.vida_maxima)
	assert_eq(instancia.energia_maxima_efetiva(), def.energia_maxima)


func test_stats_crescem_com_o_nivel() -> void:
	var nivel_1 := CreatureInstance.new("pedrolim", 1)
	var nivel_11 := CreatureInstance.new("pedrolim", 11)
	assert_gt(nivel_11.forca_efetiva(), nivel_1.forca_efetiva())
	assert_gt(nivel_11.guarda_efetiva(), nivel_1.guarda_efetiva())
	assert_gt(nivel_11.vida_maxima_efetiva(), nivel_1.vida_maxima_efetiva())


func test_vida_e_energia_iniciam_no_maximo() -> void:
	var instancia := CreatureInstance.new("faiscolt", 5)
	assert_eq(instancia.vida_atual, instancia.vida_maxima_efetiva())
	assert_eq(instancia.energia_atual, instancia.energia_maxima_efetiva())


func test_esta_desmaiado_reflete_vida_atual() -> void:
	var instancia := CreatureInstance.new("brotinho", 1)
	assert_false(instancia.esta_desmaiado())
	instancia.vida_atual = 0
	assert_true(instancia.esta_desmaiado())


func test_ataques_conhecidos_respeitam_o_nivel() -> void:
	var nivel_1 := CreatureInstance.new("pedrolim", 1)
	assert_eq(nivel_1.ataques_conhecidos, ["pedra_investida"])

	var nivel_12 := CreatureInstance.new("pedrolim", 12)
	assert_true(nivel_12.ataques_conhecidos.has("pedra_investida"))
	assert_true(nivel_12.ataques_conhecidos.has("pedra_avalanche"))
	assert_eq(nivel_12.ataques_conhecidos.size(), 2)


func test_serializar_e_carregar_ida_e_volta() -> void:
	var original := CreatureInstance.new("ventim", 7)
	original.xp = 123
	original.vida_atual = 3
	original.energia_atual = 2

	var dados := original.serializar()
	var restaurado := CreatureInstance.carregar_serializado(dados)

	assert_eq(restaurado.especie_id, "ventim")
	assert_eq(restaurado.nivel, 7)
	assert_eq(restaurado.xp, 123)
	assert_eq(restaurado.vida_atual, 3)
	assert_eq(restaurado.energia_atual, 2)
