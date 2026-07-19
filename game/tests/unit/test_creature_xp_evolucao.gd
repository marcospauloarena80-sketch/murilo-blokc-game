extends GutTest
## Ver docs/01-GDD.md §9 ("XP por batalha vencida... Evolução muda modelo,
## stats e destrava ataques") e docs/07-DECISOES.md ADR-021.


func test_xp_para_proximo_nivel_cresce_com_o_nivel() -> void:
	var nivel_1 := CreatureInstance.new("brotinho", 1)
	var nivel_10 := CreatureInstance.new("brotinho", 10)
	assert_gt(nivel_10.xp_para_proximo_nivel(), nivel_1.xp_para_proximo_nivel())


func test_ganhar_xp_abaixo_do_limiar_nao_sobe_de_nivel() -> void:
	var instancia := CreatureInstance.new("brotinho", 1)
	var limiar := instancia.xp_para_proximo_nivel()
	instancia.ganhar_xp(limiar - 1)
	assert_eq(instancia.nivel, 1)
	assert_eq(instancia.xp, limiar - 1)


func test_ganhar_xp_no_limiar_sobe_exatamente_1_nivel() -> void:
	var instancia := CreatureInstance.new("brotinho", 1)
	var limiar := instancia.xp_para_proximo_nivel()
	instancia.ganhar_xp(limiar)
	assert_eq(instancia.nivel, 2)
	assert_eq(instancia.xp, 0)


func test_subir_de_nivel_cura_vida_e_energia_por_completo() -> void:
	var instancia := CreatureInstance.new("brotinho", 1)
	instancia.vida_atual = 1
	instancia.energia_atual = 0
	instancia.ganhar_xp(instancia.xp_para_proximo_nivel())
	assert_eq(instancia.vida_atual, instancia.vida_maxima_efetiva())
	assert_eq(instancia.energia_atual, instancia.energia_maxima_efetiva())


func test_ganhar_xp_grande_sobe_varios_niveis_de_uma_vez() -> void:
	var instancia := CreatureInstance.new("brotinho", 1)
	instancia.ganhar_xp(1000)
	assert_gt(instancia.nivel, 2)


func test_nivel_nao_ultrapassa_o_maximo() -> void:
	var instancia := CreatureInstance.new("brotinho", 1)
	instancia.ganhar_xp(999999)
	assert_eq(instancia.nivel, CreatureInstance.NIVEL_MAXIMO)


func test_ganhar_xp_no_nivel_maximo_nao_faz_nada() -> void:
	var instancia := CreatureInstance.new("brotinho", CreatureInstance.NIVEL_MAXIMO)
	instancia.ganhar_xp(999999)
	assert_eq(instancia.nivel, CreatureInstance.NIVEL_MAXIMO)
	assert_eq(instancia.xp, 0)


func test_pedrolim_evolui_pra_pedrargo_ao_atingir_nivel_12() -> void:
	var instancia := CreatureInstance.new("pedrolim", 11)
	instancia.ganhar_xp(instancia.xp_para_proximo_nivel())
	assert_eq(instancia.nivel, 12)
	assert_eq(instancia.especie_id, "pedrargo")
	assert_true(instancia.ataques_conhecidos.has("pedra_avalanche"))


func test_faiscolt_evolui_pra_faiscozap_ao_atingir_nivel_10() -> void:
	var instancia := CreatureInstance.new("faiscolt", 9)
	instancia.ganhar_xp(instancia.xp_para_proximo_nivel())
	assert_eq(instancia.nivel, 10)
	assert_eq(instancia.especie_id, "faiscozap")


func test_brotinho_nunca_evolui_mesmo_em_nivel_alto() -> void:
	var instancia := CreatureInstance.new("brotinho", 1)
	instancia.ganhar_xp(999999)
	assert_eq(instancia.especie_id, "brotinho")


func test_batalha_vencida_da_xp_pro_ativo() -> void:
	var equipe: Array[CreatureInstance] = [CreatureInstance.new("pedrolim", 20)]
	var selvagem := CreatureInstance.new("brotinho", 5)
	var batalha := BattleService.new(equipe, selvagem)
	var xp_antes := equipe[0].xp

	batalha.jogador_ataca("pedra_investida", 1.1)

	assert_eq(batalha.resultado, BattleService.Resultado.VITORIA)
	assert_eq(equipe[0].xp, xp_antes + BattleService.calcular_recompensa_xp(selvagem))
