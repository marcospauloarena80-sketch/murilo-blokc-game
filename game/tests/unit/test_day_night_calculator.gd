extends GutTest
## Ver docs/01-GDD.md §3 (dia 10min/noite 5min) e docs/04-ROADMAP.md F6.

const FRACAO_DIA: float = 600.0 / 900.0


func test_meio_do_dia_e_dia_com_energia_maxima() -> void:
	var r := DayNightCalculator.calcular(FRACAO_DIA * 0.5, FRACAO_DIA)
	assert_true(r["eh_dia"])
	assert_almost_eq(r["energia_sol"], 1.0, 0.01)


func test_meio_da_noite_nao_e_dia_e_energia_baixa() -> void:
	var fase_meio_noite := FRACAO_DIA + (1.0 - FRACAO_DIA) * 0.5
	var r := DayNightCalculator.calcular(fase_meio_noite, FRACAO_DIA)
	assert_false(r["eh_dia"])
	assert_true(r["energia_sol"] < 0.2)


func test_noite_e_mais_escura_que_dia() -> void:
	var dia := DayNightCalculator.calcular(FRACAO_DIA * 0.5, FRACAO_DIA)
	var noite := DayNightCalculator.calcular(FRACAO_DIA + (1.0 - FRACAO_DIA) * 0.5, FRACAO_DIA)
	assert_true(noite["energia_ambiente"] < dia["energia_ambiente"])
	assert_true(noite["energia_sol"] < dia["energia_sol"])


func test_fase_fora_do_intervalo_0_1_e_normalizada() -> void:
	var r1 := DayNightCalculator.calcular(1.25, FRACAO_DIA)
	var r2 := DayNightCalculator.calcular(0.25, FRACAO_DIA)
	assert_eq(r1["eh_dia"], r2["eh_dia"])
	assert_almost_eq(float(r1["angulo_x_graus"]), float(r2["angulo_x_graus"]), 0.01)


func test_transicao_dia_para_noite_no_limite_exato() -> void:
	var r := DayNightCalculator.calcular(FRACAO_DIA, FRACAO_DIA)
	assert_false(r["eh_dia"], "no limite exato já deveria ser noite (dia é [0, fracao_dia))")


func test_sol_do_meio_dia_vem_do_alto() -> void:
	## Antes do Ciclo 4 a luz do meio-dia era horizontal e a do fim da tarde
	## vinha de baixo do chão (ADR-027).
	var meio_dia := DayNightCalculator.calcular(FRACAO_DIA * 0.5, FRACAO_DIA)
	assert_lt(float(meio_dia["angulo_x_graus"]), -45.0, "luz inclinada pra baixo")
	for fase: float in [0.01, FRACAO_DIA * 0.25, FRACAO_DIA * 0.99, 0.8, 0.99]:
		var r := DayNightCalculator.calcular(fase, FRACAO_DIA)
		assert_lt(float(r["angulo_x_graus"]), 0.0, "luz nunca vem de baixo (fase %.2f)" % fase)


func test_sol_nasce_a_leste_e_se_poe_a_oeste() -> void:
	var manha := DayNightCalculator.calcular(0.02, FRACAO_DIA)
	var tarde := DayNightCalculator.calcular(FRACAO_DIA - 0.02, FRACAO_DIA)
	assert_gt(float(manha["angulo_y_graus"]), 60.0)
	assert_lt(float(tarde["angulo_y_graus"]), -60.0)


func test_ceu_muda_de_cor_ao_longo_do_dia() -> void:
	var dia := DayNightCalculator.calcular(FRACAO_DIA * 0.5, FRACAO_DIA)
	var por_do_sol := DayNightCalculator.calcular(0.645, FRACAO_DIA)
	var noite := DayNightCalculator.calcular(0.85, FRACAO_DIA)
	var horizonte_tarde: Color = por_do_sol["cor_ceu_horizonte"]
	assert_gt(horizonte_tarde.r, horizonte_tarde.b, "pôr do sol alaranjado")
	var topo_dia: Color = dia["cor_ceu_topo"]
	var topo_noite: Color = noite["cor_ceu_topo"]
	assert_lt(topo_noite.get_luminance(), topo_dia.get_luminance() * 0.3)
	assert_eq(float(dia["noite"]), 0.0)
	assert_almost_eq(float(noite["noite"]), 1.0, 0.01)
