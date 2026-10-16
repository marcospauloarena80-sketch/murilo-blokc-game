extends GutTest
## Ver docs/01-GDD.md §11 e docs/07-DECISOES.md ADR-021. Balanço da missão
## quest_05_tutorial_de_combate (derrotar um Pedrolim): o primeiro Cubelin do
## jogador (Brasita no nível do presente) precisa vencer um Pedrolim selvagem
## no nível padrão mesmo com a sorte toda contra — variação mínima pra ele,
## máxima pro selvagem.


func test_missao_5_e_vencivel_no_pior_caso() -> void:
	var equipe: Array[CreatureInstance] = [
		CreatureInstance.new("brasita", QuestTracker.NIVEL_CUBELIN_PRESENTE)
	]
	var selvagem := CreatureInstance.new("pedrolim", BattleScreen.NIVEL_SELVAGEM_PADRAO)
	var batalha := BattleService.new(equipe, selvagem)
	var ataque_jogador: String = equipe[0].ataques_conhecidos[0]
	var ataque_selvagem: String = selvagem.ataques_conhecidos[0]

	var guarda := 0
	while batalha.resultado == BattleService.Resultado.EM_ANDAMENTO and guarda < 50:
		if batalha.quem_age_primeiro() == "jogador":
			batalha.jogador_ataca(ataque_jogador, BattleScreen.VARIACAO_MIN)
			batalha.selvagem_ataca(ataque_selvagem, BattleScreen.VARIACAO_MAX)
		else:
			batalha.selvagem_ataca(ataque_selvagem, BattleScreen.VARIACAO_MAX)
			batalha.jogador_ataca(ataque_jogador, BattleScreen.VARIACAO_MIN)
		guarda += 1

	assert_eq(batalha.resultado, BattleService.Resultado.VITORIA, "missão 5 precisa ser vencível")
	assert_gt(equipe[0].vida_atual, 0, "a Brasita deveria sobreviver no pior caso")
