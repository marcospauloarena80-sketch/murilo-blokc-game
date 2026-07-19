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
