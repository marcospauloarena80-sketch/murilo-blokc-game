extends GutTest
## Ver docs/01-GDD.md §11 e docs/07-DECISOES.md ADR-021.
## Construção/troca de ativo, ordem de turno e ataques (parte 2/3 dos testes
## de BattleService, separados por causa do limite do gdlint).


func _equipe_um(especie: String, nivel: int = 5) -> Array[CreatureInstance]:
	var equipe: Array[CreatureInstance] = [CreatureInstance.new(especie, nivel)]
	return equipe


func test_construtor_escolhe_primeiro_nao_desmaiado_como_ativo() -> void:
	var equipe: Array[CreatureInstance] = [
		CreatureInstance.new("brotinho", 1), CreatureInstance.new("ventim", 1)
	]
	equipe[0].vida_atual = 0
	var batalha := BattleService.new(equipe, CreatureInstance.new("pedrolim", 1))
	assert_eq(batalha.indice_ativo, 1)
	assert_eq(batalha.jogador_ativo(), equipe[1])


func test_trocar_ativo_funciona_para_indice_valido() -> void:
	var equipe: Array[CreatureInstance] = [
		CreatureInstance.new("brotinho", 1), CreatureInstance.new("ventim", 1)
	]
	var batalha := BattleService.new(equipe, CreatureInstance.new("pedrolim", 1))
	assert_true(batalha.trocar_ativo(1))
	assert_eq(batalha.indice_ativo, 1)


func test_trocar_ativo_falha_pra_indice_fora_do_alcance() -> void:
	var batalha := BattleService.new(_equipe_um("brotinho"), CreatureInstance.new("pedrolim", 1))
	assert_false(batalha.trocar_ativo(5))
	assert_false(batalha.trocar_ativo(-1))


func test_trocar_ativo_falha_pra_membro_desmaiado() -> void:
	var equipe: Array[CreatureInstance] = [
		CreatureInstance.new("brotinho", 1), CreatureInstance.new("ventim", 1)
	]
	equipe[1].vida_atual = 0
	var batalha := BattleService.new(equipe, CreatureInstance.new("pedrolim", 1))
	assert_false(batalha.trocar_ativo(1))


func test_trocar_ativo_falha_apos_batalha_resolvida() -> void:
	var equipe: Array[CreatureInstance] = [CreatureInstance.new("pedrolim", 30)]
	var selvagem := CreatureInstance.new("brotinho", 1)
	var batalha := BattleService.new(equipe, selvagem)
	batalha.jogador_ataca("pedra_investida", 1.1)
	assert_eq(batalha.resultado, BattleService.Resultado.VITORIA)
	assert_false(batalha.trocar_ativo(0))


func test_maior_agilidade_age_primeiro() -> void:
	var equipe := _equipe_um("ventim", 5)  # agilidade 9
	var selvagem := CreatureInstance.new("pedrolim", 5)  # agilidade 3
	var batalha := BattleService.new(equipe, selvagem)
	assert_eq(batalha.quem_age_primeiro(), "jogador")


func test_selvagem_mais_agil_age_primeiro() -> void:
	var equipe := _equipe_um("pedrolim", 5)  # agilidade 3
	var selvagem := CreatureInstance.new("ventim", 5)  # agilidade 9
	var batalha := BattleService.new(equipe, selvagem)
	assert_eq(batalha.quem_age_primeiro(), "selvagem")


func test_empate_de_agilidade_favorece_o_jogador() -> void:
	var equipe := _equipe_um("brotinho", 5)
	var selvagem := CreatureInstance.new("brotinho", 5)
	var batalha := BattleService.new(equipe, selvagem)
	assert_eq(batalha.quem_age_primeiro(), "jogador")


func test_jogador_ataca_reduz_vida_do_selvagem_e_gasta_energia() -> void:
	var equipe := _equipe_um("pedrolim", 5)
	var selvagem := CreatureInstance.new("faiscolt", 5)
	var vida_antes := selvagem.vida_atual
	var energia_antes := equipe[0].energia_atual
	var batalha := BattleService.new(equipe, selvagem)

	var dano := batalha.jogador_ataca("pedra_investida", 1.0)

	assert_eq(selvagem.vida_atual, max(0, vida_antes - dano))
	assert_eq(equipe[0].energia_atual, energia_antes)  # ataque básico custa 0


func test_jogador_ataca_com_ataque_pesado_gasta_energia() -> void:
	var equipe := _equipe_um("pedrolim", 12)  # já conhece avalanche
	var selvagem := CreatureInstance.new("faiscolt", 5)
	var energia_antes := equipe[0].energia_atual
	var batalha := BattleService.new(equipe, selvagem)

	batalha.jogador_ataca("pedra_avalanche", 1.0)

	assert_eq(equipe[0].energia_atual, energia_antes - 3)


func test_jogador_ataca_ate_vencer_muda_resultado_pra_vitoria() -> void:
	var equipe := _equipe_um("pedrolim", 30)
	var selvagem := CreatureInstance.new("brotinho", 1)
	var batalha := BattleService.new(equipe, selvagem)

	batalha.jogador_ataca("pedra_investida", 1.1)

	assert_eq(batalha.resultado, BattleService.Resultado.VITORIA)
	assert_true(selvagem.esta_desmaiado())


func test_jogador_ataca_com_ataque_desconhecido_nao_faz_nada() -> void:
	var equipe := _equipe_um("pedrolim", 1)  # ainda não conhece pedra_avalanche (nível 12)
	var selvagem := CreatureInstance.new("brotinho", 1)
	var vida_antes := selvagem.vida_atual
	var batalha := BattleService.new(equipe, selvagem)

	var dano := batalha.jogador_ataca("pedra_avalanche", 1.0)

	assert_eq(dano, 0)
	assert_eq(selvagem.vida_atual, vida_antes)


func test_selvagem_ataca_com_ataque_desconhecido_nao_faz_nada() -> void:
	var equipe := _equipe_um("brotinho", 1)
	var selvagem := CreatureInstance.new("pedrolim", 1)  # ainda não conhece avalanche
	var vida_antes := equipe[0].vida_atual
	var batalha := BattleService.new(equipe, selvagem)

	var dano := batalha.selvagem_ataca("pedra_avalanche", 1.0)

	assert_eq(dano, 0)
	assert_eq(equipe[0].vida_atual, vida_antes)


func test_selvagem_ataca_reduz_vida_do_ativo() -> void:
	var equipe := _equipe_um("brotinho", 5)
	var selvagem := CreatureInstance.new("pedrolim", 5)
	var vida_antes := equipe[0].vida_atual
	var batalha := BattleService.new(equipe, selvagem)

	var dano := batalha.selvagem_ataca("pedra_investida", 1.0)

	assert_eq(equipe[0].vida_atual, max(0, vida_antes - dano))


func test_selvagem_derrota_time_inteiro_muda_resultado_pra_derrota() -> void:
	var equipe := _equipe_um("brotinho", 1)
	var selvagem := CreatureInstance.new("pedrolim", 30)
	var batalha := BattleService.new(equipe, selvagem)

	batalha.selvagem_ataca("pedra_avalanche", 1.1)

	assert_eq(batalha.resultado, BattleService.Resultado.DERROTA)


func test_selvagem_derrota_um_membro_mas_time_continua_se_outro_sobrevive() -> void:
	var equipe: Array[CreatureInstance] = [
		CreatureInstance.new("brotinho", 1), CreatureInstance.new("ventim", 30)
	]
	var selvagem := CreatureInstance.new("pedrolim", 30)
	var batalha := BattleService.new(equipe, selvagem)

	batalha.selvagem_ataca("pedra_avalanche", 1.1)

	assert_true(equipe[0].esta_desmaiado())
	assert_eq(batalha.resultado, BattleService.Resultado.EM_ANDAMENTO)
	assert_true(batalha.trocar_ativo(1), "deveria poder trocar pro sobrevivente")


func test_acao_nao_faz_nada_apos_batalha_resolvida() -> void:
	var equipe := _equipe_um("pedrolim", 30)
	var selvagem := CreatureInstance.new("brotinho", 1)
	var batalha := BattleService.new(equipe, selvagem)
	batalha.jogador_ataca("pedra_investida", 1.1)
	assert_eq(batalha.resultado, BattleService.Resultado.VITORIA)

	var vida_antes := equipe[0].vida_atual
	batalha.selvagem_ataca("pedra_investida", 1.1)

	assert_eq(
		equipe[0].vida_atual, vida_antes, "batalha já resolvida não deveria processar mais ações"
	)
