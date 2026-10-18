extends GutTest
## ADR-033: a oferta de missão do guardião é opcional. Aceitar, recusar ou
## ignorar a missão não decide se o jogador pode desafiar; só os requisitos
## reais da batalha decidem (Cubelin em condições, insígnias, revanche).

const DialogueScreenScene := preload("res://ui/dialogue_screen/dialogue_screen.tscn")
const NpcScene := preload("res://entities/npcs/npc.tscn")
const QUEST_DO_RENATO := "quest_r4_capturador"


func before_each() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrargo", 20)]
	GameState.insignias_conquistadas = []
	GameState.treinadores_vencidos = {}
	GameState.tempo_de_jogo_seg = 0.0
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.insignias_conquistadas = []
	GameState.treinadores_vencidos = {}
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []
	GameState.mudar_estado(GameState.State.PLAYING)


func _dialogo(npc_id: String) -> DialogueScreen:
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	var npc := NpcScene.instantiate() as Npc
	add_child_autofree(npc)
	npc.configurar(NpcRegistry.get_npc(npc_id))
	tela._abrir(npc)
	while not tela._botao_aceitar.visible and tela._botao_avancar.visible:
		tela._ao_avancar()
	return tela


func _dialogo_do_renato() -> DialogueScreen:
	var tela := _dialogo("guardiao_pedra")
	assert_true(tela._oferece_quest_pendente(), "pré-condição: a oferta está pendente")
	return tela


func test_oferta_pendente_nao_esconde_o_desafiar() -> void:
	var tela := _dialogo_do_renato()

	assert_true(tela._botao_aceitar.visible)
	assert_true(tela._botao_recusar.visible)
	assert_true(tela._botao_desafiar.visible, "Desafiar não depende da missão")


func test_ignorar_a_oferta_e_desafiar_nao_aceita_a_missao() -> void:
	var tela := _dialogo_do_renato()
	var recebido: Array = [""]
	var callback := func(arena_id: String) -> void: recebido[0] = arena_id
	EventBus.arena_challenge_started.connect(callback)

	tela._ao_desafiar()

	EventBus.arena_challenge_started.disconnect(callback)
	assert_eq(recebido[0], "pedra")
	assert_eq(GameState.quest_atual_id, "", "ignorar não aceita a missão")
	assert_eq(GameState.progresso_quest_atual, 0)


func test_recusar_a_oferta_nao_aceita_nem_conclui_e_o_desafio_continua_possivel() -> void:
	var tela := _dialogo_do_renato()

	tela._ao_recusar_quest()

	assert_eq(GameState.quest_atual_id, "")
	assert_eq(GameState.progresso_quest_atual, 0)
	assert_false(GameState.quests_concluidas.has(QUEST_DO_RENATO))
	var reaberto := _dialogo("guardiao_pedra")
	assert_true(reaberto._oferece_quest_pendente(), "a missão continua disponível")
	assert_true(reaberto._botao_desafiar.visible)


func test_aceitar_a_oferta_inicia_a_missao_e_o_desafio_continua_possivel() -> void:
	var tela := _dialogo_do_renato()

	tela._ao_aceitar_quest()

	assert_eq(GameState.quest_atual_id, QUEST_DO_RENATO)
	var reaberto := _dialogo("guardiao_pedra")
	assert_false(reaberto._oferece_quest_pendente())
	assert_true(reaberto._botao_desafiar.visible)


func test_oferta_pendente_sem_cubelin_disponivel_continua_sem_desafiar() -> void:
	GameState.equipe_cubelins[0].vida_atual = 0

	var tela := _dialogo_do_renato()

	assert_true(tela._botao_aceitar.visible, "a missão ainda pode ser aceita")
	assert_false(tela._botao_desafiar.visible, "o bloqueio de batalha não é contornado")
	assert_string_contains(tela._label_texto.text, "descansar")


func test_oferta_pendente_sem_equipe_nao_deixa_desafiar() -> void:
	GameState.equipe_cubelins = []

	var tela := _dialogo_do_renato()

	assert_false(tela._botao_desafiar.visible)


func test_guardiao_sem_oferta_continua_desafiando_como_antes() -> void:
	var tela := _dialogo("guardiao_brasa")

	assert_false(tela._botao_aceitar.visible)
	assert_true(tela._botao_desafiar.visible)


func test_treinador_em_revanche_bloqueada_com_oferta_pendente_nao_desafia() -> void:
	GameState.quests_concluidas = ["quest_r1_coleta_diaria"]
	Treinadores.registrar_vitoria("treinador_tico")

	var tela := _dialogo("treinador_tico")

	assert_true(tela._oferece_quest_pendente())
	assert_false(tela._botao_desafiar.visible, "a regra diária do treinador continua valendo")
	assert_string_contains(tela._label_texto.text, "Volte amanhã")


func test_final_sem_as_4_insignias_explica_as_insignias_e_nao_diz_volte_amanha() -> void:
	## O desafio final deixou de ser "insígnia" (da_insignia = false); o texto de
	## bloqueio não pode cair na mensagem dos treinadores diários.
	var tela := _dialogo("guardiao_final")

	assert_false(tela._botao_desafiar.visible)
	assert_string_contains(tela._label_texto.text, "insígnias")
	assert_false(tela._label_texto.text.contains("amanhã"))
