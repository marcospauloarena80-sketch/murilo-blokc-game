extends GutTest
## Ver docs/01-GDD.md §10/§11 e docs/07-DECISOES.md ADR-021.
## Fuga, item (poção), captura e cenário completo (parte 3/3 dos testes de
## BattleService, separados por causa do limite do gdlint).


func _equipe_um(especie: String, nivel: int = 5) -> Array[CreatureInstance]:
	var equipe: Array[CreatureInstance] = [CreatureInstance.new(especie, nivel)]
	return equipe


func test_chance_de_fuga_e_50_por_cento_com_agilidade_igual() -> void:
	var batalha := BattleService.new(_equipe_um("brotinho", 5), CreatureInstance.new("brotinho", 5))
	assert_almost_eq(batalha.chance_de_fuga(), 0.5, 0.001)


func test_chance_de_fuga_maior_com_mais_agilidade() -> void:
	var batalha := BattleService.new(_equipe_um("ventim", 5), CreatureInstance.new("pedrolim", 5))
	assert_gt(batalha.chance_de_fuga(), 0.5)


func test_chance_de_fuga_e_limitada_entre_0_1_e_0_95() -> void:
	var batalha := BattleService.new(_equipe_um("ventim", 30), CreatureInstance.new("pedrolim", 1))
	assert_lte(batalha.chance_de_fuga(), 0.95)


func test_tentar_fugir_sucesso_muda_resultado() -> void:
	var batalha := BattleService.new(_equipe_um("brotinho", 5), CreatureInstance.new("brotinho", 5))
	var sucesso := batalha.tentar_fugir(0.1)  # bem abaixo da chance de 0.5
	assert_true(sucesso)
	assert_eq(batalha.resultado, BattleService.Resultado.FUGIU)


func test_tentar_fugir_falha_mantem_batalha_em_andamento() -> void:
	var batalha := BattleService.new(_equipe_um("brotinho", 5), CreatureInstance.new("brotinho", 5))
	var sucesso := batalha.tentar_fugir(0.9)  # bem acima da chance de 0.5
	assert_false(sucesso)
	assert_eq(batalha.resultado, BattleService.Resultado.EM_ANDAMENTO)


func test_tentar_fugir_falha_apos_batalha_resolvida() -> void:
	var equipe := _equipe_um("pedrolim", 30)
	var selvagem := CreatureInstance.new("brotinho", 1)
	var batalha := BattleService.new(equipe, selvagem)
	batalha.jogador_ataca("pedra_investida", 1.1)

	assert_false(batalha.tentar_fugir(0.0))


func test_usar_pocao_cura_ate_o_maximo() -> void:
	var alvo := CreatureInstance.new("brotinho", 5)
	alvo.vida_atual = 1
	var batalha := BattleService.new(_equipe_um("ventim"), CreatureInstance.new("pedrolim", 1))

	batalha.usar_pocao(alvo, 999)

	assert_eq(alvo.vida_atual, alvo.vida_maxima_efetiva())


func test_usar_pocao_nao_ultrapassa_o_maximo_com_cura_pequena() -> void:
	var alvo := CreatureInstance.new("brotinho", 5)
	var vida_maxima := alvo.vida_maxima_efetiva()
	alvo.vida_atual = vida_maxima - 2
	var batalha := BattleService.new(_equipe_um("ventim"), CreatureInstance.new("pedrolim", 1))

	batalha.usar_pocao(alvo, 1)

	assert_eq(alvo.vida_atual, vida_maxima - 1)


func test_capturar_muda_resultado() -> void:
	var batalha := BattleService.new(_equipe_um("brotinho"), CreatureInstance.new("pedrolim", 1))
	batalha.capturar()
	assert_eq(batalha.resultado, BattleService.Resultado.CAPTUROU)


func test_batalha_completa_ate_vitoria() -> void:
	var equipe := _equipe_um("pedrolim", 10)
	var selvagem := CreatureInstance.new("brotinho", 1)
	var batalha := BattleService.new(equipe, selvagem)

	var guarda := 0
	while batalha.resultado == BattleService.Resultado.EM_ANDAMENTO and guarda < 50:
		batalha.jogador_ataca("pedra_investida", 1.0)
		guarda += 1

	assert_eq(batalha.resultado, BattleService.Resultado.VITORIA)
	assert_lt(guarda, 50, "não deveria travar em loop infinito")
