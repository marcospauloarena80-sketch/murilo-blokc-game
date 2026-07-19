extends GutTest
## Ver docs/01-GDD.md §13 e docs/07-DECISOES.md ADR-023.


func _equipe_forte(nivel: int, tamanho: int = 1) -> Array[CreatureInstance]:
	var resultado: Array[CreatureInstance] = []
	for i in range(tamanho):
		resultado.append(CreatureInstance.new("pedrolim", nivel))
	return resultado


func test_comeca_contra_o_primeiro_membro_do_guardiao() -> void:
	var jogador := _equipe_forte(20)
	var guardiao: Array[CreatureInstance] = [
		CreatureInstance.new("brotinho", 1), CreatureInstance.new("ventim", 1)
	]
	var batalha := GuardianBattle.new(jogador, guardiao)

	assert_eq(batalha.batalha_atual.selvagem.especie_id, "brotinho")
	assert_eq(batalha.indice_guardiao, 0)


func test_tem_proximo_adversario_quando_ha_mais_de_um_membro() -> void:
	var jogador := _equipe_forte(20)
	var guardiao: Array[CreatureInstance] = [
		CreatureInstance.new("brotinho", 1), CreatureInstance.new("ventim", 1)
	]
	var batalha := GuardianBattle.new(jogador, guardiao)

	assert_true(batalha.tem_proximo_adversario())


func test_sem_proximo_adversario_com_um_unico_membro() -> void:
	var jogador := _equipe_forte(20)
	var guardiao: Array[CreatureInstance] = [CreatureInstance.new("brotinho", 1)]
	var batalha := GuardianBattle.new(jogador, guardiao)

	assert_false(batalha.tem_proximo_adversario())


func test_avancar_troca_pro_proximo_membro_mantendo_a_equipe_do_jogador() -> void:
	var jogador := _equipe_forte(20)
	var guardiao: Array[CreatureInstance] = [
		CreatureInstance.new("brotinho", 1), CreatureInstance.new("ventim", 1)
	]
	var batalha := GuardianBattle.new(jogador, guardiao)

	batalha.avancar_para_proximo()

	assert_eq(batalha.indice_guardiao, 1)
	assert_eq(batalha.batalha_atual.selvagem.especie_id, "ventim")
	assert_eq(batalha.batalha_atual.equipe, jogador, "equipe do jogador deve continuar a mesma")


func test_vida_do_jogador_continua_entre_batalhas_do_mesmo_guardiao() -> void:
	var jogador := _equipe_forte(20)
	jogador[0].vida_atual = 3
	var guardiao: Array[CreatureInstance] = [
		CreatureInstance.new("brotinho", 1), CreatureInstance.new("ventim", 1)
	]
	var batalha := GuardianBattle.new(jogador, guardiao)

	batalha.avancar_para_proximo()

	assert_eq(batalha.batalha_atual.jogador_ativo().vida_atual, 3)


func test_guardiao_nao_totalmente_derrotado_enquanto_ha_proximo() -> void:
	var jogador := _equipe_forte(20)
	var guardiao: Array[CreatureInstance] = [
		CreatureInstance.new("brotinho", 1), CreatureInstance.new("ventim", 1)
	]
	var batalha := GuardianBattle.new(jogador, guardiao)
	while batalha.batalha_atual.resultado == BattleService.Resultado.EM_ANDAMENTO:
		batalha.batalha_atual.jogador_ataca("pedra_investida", 1.0)

	assert_eq(batalha.batalha_atual.resultado, BattleService.Resultado.VITORIA)
	assert_false(batalha.guardiao_totalmente_derrotado())


func test_guardiao_totalmente_derrotado_quando_ultimo_membro_cai() -> void:
	var jogador := _equipe_forte(20)
	var guardiao: Array[CreatureInstance] = [CreatureInstance.new("brotinho", 1)]
	var batalha := GuardianBattle.new(jogador, guardiao)
	while batalha.batalha_atual.resultado == BattleService.Resultado.EM_ANDAMENTO:
		batalha.batalha_atual.jogador_ataca("pedra_investida", 1.0)

	assert_eq(batalha.batalha_atual.resultado, BattleService.Resultado.VITORIA)
	assert_true(batalha.guardiao_totalmente_derrotado())
