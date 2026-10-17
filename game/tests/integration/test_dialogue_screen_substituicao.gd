extends GutTest
## ADR-034: aceitar uma missão não descarta mais, em silêncio, o progresso da
## missão atual. O mesmo par de botões vira Substituir/Cancelar só quando há
## o que perder (missão atual não repetível e com progresso).

const DialogueScreenScene := preload("res://ui/dialogue_screen/dialogue_screen.tscn")
const NpcScene := preload("res://entities/npcs/npc.tscn")
const NOVA := "quest_r4_capturador"  ## oferecida pelo Renato (guardiao_pedra)
const NAO_REPETIVEL := "quest_01_boas_vindas"
const REPETIVEL := "quest_r3_cacador"


func before_each() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrargo", 20)]
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []
	GameState.mudar_estado(GameState.State.PLAYING)


func _dialogo_do_renato() -> DialogueScreen:
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	var npc := NpcScene.instantiate() as Npc
	add_child_autofree(npc)
	npc.configurar(NpcRegistry.get_npc("guardiao_pedra"))
	tela._abrir(npc)
	while not tela._botao_aceitar.visible and tela._botao_avancar.visible:
		tela._ao_avancar()
	assert_true(tela._oferece_quest_pendente(), "pré-condição: oferta pendente")
	return tela


func _ativar(quest_id: String, progresso: int) -> void:
	GameState.iniciar_quest(quest_id)
	GameState.progresso_quest_atual = progresso


func test_sem_missao_ativa_aceita_direto() -> void:
	var tela := _dialogo_do_renato()

	tela._ao_aceitar_quest()

	assert_eq(GameState.quest_atual_id, NOVA)
	assert_false(tela.visible)


func test_missao_atual_repetivel_com_progresso_e_substituida_direto() -> void:
	_ativar(REPETIVEL, 1)
	var tela := _dialogo_do_renato()

	tela._ao_aceitar_quest()

	assert_eq(GameState.quest_atual_id, NOVA)
	assert_false(tela.visible)


func test_missao_atual_nao_repetivel_sem_progresso_e_substituida_direto() -> void:
	_ativar(NAO_REPETIVEL, 0)
	var tela := _dialogo_do_renato()

	tela._ao_aceitar_quest()

	assert_eq(GameState.quest_atual_id, NOVA)


func test_missao_atual_nao_repetivel_com_progresso_pede_confirmacao_e_nada_muda() -> void:
	_ativar(NAO_REPETIVEL, 2)
	var tela := _dialogo_do_renato()

	tela._ao_aceitar_quest()

	assert_eq(GameState.quest_atual_id, NAO_REPETIVEL, "1º toque não substitui")
	assert_eq(GameState.progresso_quest_atual, 2)
	assert_true(tela.visible, "o diálogo segue aberto, esperando a resposta")
	var atual := QuestRegistry.get_quest(NAO_REPETIVEL)
	assert_string_contains(tela._label_texto.text, atual.nome)
	assert_string_contains(tela._label_texto.text, "2/%d" % atual.quantidade_alvo)
	assert_eq(tela._botao_aceitar.text, "Substituir")
	assert_eq(tela._botao_recusar.text, "Cancelar")
	assert_false(tela._botao_desafiar.visible, "durante a pergunta só há as duas respostas")


func test_cancelar_preserva_a_missao_atual_e_o_progresso() -> void:
	_ativar(NAO_REPETIVEL, 2)
	var tela := _dialogo_do_renato()
	tela._ao_aceitar_quest()

	tela._ao_recusar_quest()

	assert_eq(GameState.quest_atual_id, NAO_REPETIVEL)
	assert_eq(GameState.progresso_quest_atual, 2)
	assert_true(tela.visible, "cancelar volta à oferta, não fecha")
	assert_eq(tela._botao_aceitar.text, "Aceitar")
	assert_eq(tela._botao_recusar.text, "Recusar")
	assert_true(tela._botao_desafiar.visible)


func test_confirmar_substitui_e_zera_o_progresso() -> void:
	_ativar(NAO_REPETIVEL, 2)
	var tela := _dialogo_do_renato()
	tela._ao_aceitar_quest()

	tela._ao_aceitar_quest()

	assert_eq(GameState.quest_atual_id, NOVA)
	assert_eq(GameState.progresso_quest_atual, 0)
	assert_false(tela.visible)


func test_reabrir_o_dialogo_nao_herda_a_confirmacao_pendente() -> void:
	_ativar(NAO_REPETIVEL, 2)
	var tela := _dialogo_do_renato()
	tela._ao_aceitar_quest()
	tela._fechar()

	var reaberto := _dialogo_do_renato()

	assert_eq(reaberto._botao_aceitar.text, "Aceitar")
	assert_eq(GameState.quest_atual_id, NAO_REPETIVEL)


func test_recusar_sem_conflito_continua_so_fechando() -> void:
	_ativar(NAO_REPETIVEL, 2)
	var tela := _dialogo_do_renato()

	tela._ao_recusar_quest()

	assert_eq(GameState.quest_atual_id, NAO_REPETIVEL)
	assert_eq(GameState.progresso_quest_atual, 2)
	assert_false(tela.visible)
