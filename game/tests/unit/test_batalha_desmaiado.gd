extends GutTest
## ADR-033: cobertura determinística de "desmaiado não age, não ganha XP e não
## reaparece vivo por level-up", sem hook de depuração no jogo ou na sonda.


func _batalha_com_ativo_desmaiado() -> BattleService:
	var equipe: Array[CreatureInstance] = [
		CreatureInstance.new("brotinho", 1), CreatureInstance.new("ventim", 1)
	]
	var oponente := CreatureInstance.new("pedrolim", 1)
	oponente.vida_atual = 1
	var batalha := BattleService.new(equipe, oponente)
	equipe[0].vida_atual = 0  ## derrubado pelo golpe do oponente, ainda marcado como ativo
	return batalha


func test_desmaiado_com_xp_a_um_ponto_do_proximo_nivel_nao_sobe_nem_revive() -> void:
	var batalha := _batalha_com_ativo_desmaiado()
	var desmaiado := batalha.jogador_ativo()
	desmaiado.xp = desmaiado.xp_para_proximo_nivel() - 1
	var nivel_antes := desmaiado.nivel

	var dano := batalha.jogador_ataca(desmaiado.ataques_conhecidos[0], 1.0)

	assert_eq(dano, 0)
	assert_eq(desmaiado.nivel, nivel_antes, "sem golpe não há XP, logo não há level-up")
	assert_eq(desmaiado.vida_atual, 0, "o level-up não pode reviver")
	assert_true(desmaiado.esta_desmaiado())
	assert_eq(batalha.resultado, BattleService.Resultado.EM_ANDAMENTO)


func test_desmaiado_nao_gasta_energia_nem_machuca_o_oponente() -> void:
	var batalha := _batalha_com_ativo_desmaiado()
	var desmaiado := batalha.jogador_ativo()
	var energia := desmaiado.energia_atual

	batalha.jogador_ataca(desmaiado.ataques_conhecidos[0], 1.0)

	assert_eq(desmaiado.energia_atual, energia)
	assert_eq(batalha.selvagem.vida_atual, 1)


func test_ataque_com_ataque_desconhecido_de_desmaiado_tambem_e_ignorado() -> void:
	var batalha := _batalha_com_ativo_desmaiado()

	assert_eq(batalha.jogador_ataca("ataque_que_nao_existe", 1.0), 0)


func test_troca_para_um_vivo_volta_a_permitir_atacar_e_dar_xp() -> void:
	var batalha := _batalha_com_ativo_desmaiado()
	assert_true(batalha.trocar_ativo(1))
	var vivo := batalha.jogador_ativo()
	var xp_antes := vivo.xp
	var nivel_antes := vivo.nivel

	var dano := batalha.jogador_ataca(vivo.ataques_conhecidos[0], 1.0)

	assert_gt(dano, 0)
	assert_eq(batalha.resultado, BattleService.Resultado.VITORIA)
	assert_true(vivo.xp > xp_antes or vivo.nivel > nivel_antes, "quem lutou ganha o XP")


func test_ganhar_xp_direto_continua_sendo_o_unico_caminho_que_cura_no_level_up() -> void:
	## Documenta o comportamento de CreatureInstance (não alterado): a cura vem
	## de ganhar_xp. A proteção está em quem concede o XP, o BattleService.
	var instancia := CreatureInstance.new("brotinho", 1)
	instancia.vida_atual = 0

	instancia.ganhar_xp(instancia.xp_para_proximo_nivel())

	assert_eq(instancia.nivel, 2)
	assert_gt(instancia.vida_atual, 0)
