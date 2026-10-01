extends GutTest
## Regressão da dependência circular achada na auditoria (ADR-027): batalha
## exige ter Cubelin, e Cubelin só vinha de captura em batalha, então nenhum
## jogador conseguia o primeiro. Usa as missões reais (sem injetar Cubelin)
## e chama o handler do QuestTracker direto, como o resto dos testes de
## missão (emitir no EventBus duplica handlers entre arquivos de teste).


func before_each() -> void:
	GameState.reiniciar_para_novo_jogo()


func after_each() -> void:
	GameState.reiniciar_para_novo_jogo()


func test_jogo_novo_comeca_sem_cubelin() -> void:
	assert_eq(GameState.equipe_cubelins.size(), 0)


func test_missao_de_mineracao_da_o_primeiro_cubelin_e_cubos() -> void:
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("quest_04_mineracao")

	tracker._ao_coletar_item("pedra", 5)

	assert_eq(GameState.equipe_cubelins.size(), 1, "recompensa entrega o primeiro Cubelin")
	assert_true(GameState.tem_cubelin_disponivel(), "agora dá pra iniciar batalha")
	assert_eq(GameState.inventario_mochila.contar("cubo_captura"), 3)


func test_depois_da_mineracao_vem_a_captura_e_depois_o_combate_noturno() -> void:
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("quest_04_mineracao")

	tracker._ao_coletar_item("pedra", 5)
	assert_eq(GameState.quest_atual_id, "quest_06_primeira_captura", "captura de dia vem antes")

	tracker._ao_capturar_criatura("brotinho")
	assert_eq(GameState.quest_atual_id, "quest_05_tutorial_de_combate")


func test_objetivo_no_hud_guia_o_primeiro_passo_e_mostra_progresso() -> void:
	assert_string_contains(Hud.texto_objetivo(), "Lina")

	GameState.iniciar_quest("quest_01_boas_vindas")
	GameState.progresso_quest_atual = 2

	assert_string_contains(Hud.texto_objetivo(), "(2/5)")
