extends GutTest
## Pilha de telas do GameState: cada tela de UI entra com abrir_tela(id) e sai
## com fechar_tela(id); o jogo só volta a PLAYING quando a última fecha. Cobre
## as transições encadeadas (diálogo -> batalha, diálogo -> laboratório,
## batalha -> créditos) que antes deixavam o jogo correndo por baixo da tela.

const DialogueScreenScene := preload("res://ui/dialogue_screen/dialogue_screen.tscn")
const BattleScreenScene := preload("res://ui/battle_screen/battle_screen.tscn")
const LaboratorioScreenScene := preload("res://ui/laboratorio_screen/laboratorio_screen.tscn")
const CreditsScreenScene := preload("res://ui/credits_screen/credits_screen.tscn")
const NpcScene := preload("res://entities/npcs/npc.tscn")


func before_each() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrolim", 20)]
	GameState.deposito_cubelins = []
	GameState.insignias_conquistadas = []
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.mudar_estado(GameState.State.PLAYING)


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []
	GameState.insignias_conquistadas = []
	GameState.mudar_estado(GameState.State.PLAYING)


func _npc(npc_id: String) -> Npc:
	var npc := NpcScene.instantiate() as Npc
	add_child_autofree(npc)
	npc.configurar(NpcRegistry.get_npc(npc_id))
	return npc


# --- unidade: GameState ---


func test_abrir_tela_pausa_e_registra_na_pilha() -> void:
	GameState.abrir_tela("a")

	assert_eq(GameState.current_state, GameState.State.PAUSED)
	assert_eq(GameState.telas_abertas, ["a"])


func test_fechar_uma_tela_com_outra_aberta_continua_pausado() -> void:
	GameState.abrir_tela("a")
	GameState.abrir_tela("b")

	GameState.fechar_tela("a")

	assert_eq(GameState.current_state, GameState.State.PAUSED)
	assert_eq(GameState.telas_abertas, ["b"])


func test_fechar_a_ultima_tela_volta_a_jogar() -> void:
	GameState.abrir_tela("a")
	GameState.abrir_tela("b")
	GameState.fechar_tela("a")

	GameState.fechar_tela("b")

	assert_eq(GameState.current_state, GameState.State.PLAYING)
	assert_true(GameState.telas_abertas.is_empty())


func test_abrir_a_mesma_tela_duas_vezes_nao_duplica() -> void:
	GameState.abrir_tela("a")
	GameState.abrir_tela("a")

	GameState.fechar_tela("a")

	assert_eq(GameState.current_state, GameState.State.PLAYING)


func test_mudar_para_estado_nao_pausado_limpa_a_pilha() -> void:
	GameState.abrir_tela("a")
	GameState.abrir_tela("b")

	GameState.mudar_estado(GameState.State.MENU)

	assert_true(GameState.telas_abertas.is_empty())
	assert_eq(GameState.current_state, GameState.State.MENU)


func test_fechar_tela_fora_de_pausa_nao_mexe_no_estado() -> void:
	GameState.mudar_estado(GameState.State.MENU)

	GameState.fechar_tela("a")

	assert_eq(GameState.current_state, GameState.State.MENU)


# --- integração: diálogo -> batalha ---


func test_desafiar_abre_a_batalha_e_o_jogo_continua_pausado() -> void:
	var dialogo := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(dialogo)
	var batalha := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(batalha)
	dialogo._abrir(_npc("guardiao_pedra"))

	dialogo._ao_desafiar()

	assert_false(dialogo.visible, "diálogo deveria fechar")
	assert_true(batalha.visible, "batalha deveria abrir")
	assert_eq(GameState.current_state, GameState.State.PAUSED)


func test_fechar_a_batalha_vinda_do_dialogo_volta_a_jogar() -> void:
	var dialogo := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(dialogo)
	var batalha := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(batalha)
	dialogo._abrir(_npc("guardiao_pedra"))
	dialogo._ao_desafiar()

	batalha._fechar()

	assert_false(batalha.visible)
	assert_eq(GameState.current_state, GameState.State.PLAYING)


# --- integração: diálogo -> laboratório ---


func test_abrir_laboratorio_pela_lina_mantem_o_jogo_pausado() -> void:
	var dialogo := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(dialogo)
	var laboratorio := LaboratorioScreenScene.instantiate() as LaboratorioScreen
	add_child_autofree(laboratorio)
	dialogo._abrir(_npc("lina"))

	dialogo._ao_abrir_laboratorio()

	assert_false(dialogo.visible, "diálogo deveria fechar")
	assert_true(laboratorio.visible, "laboratório deveria abrir")
	assert_eq(GameState.current_state, GameState.State.PAUSED)


func test_fechar_o_laboratorio_vindo_do_dialogo_volta_a_jogar() -> void:
	var dialogo := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(dialogo)
	var laboratorio := LaboratorioScreenScene.instantiate() as LaboratorioScreen
	add_child_autofree(laboratorio)
	dialogo._abrir(_npc("lina"))
	dialogo._ao_abrir_laboratorio()

	laboratorio._fechar()

	assert_false(laboratorio.visible)
	assert_eq(GameState.current_state, GameState.State.PLAYING)


# --- integração: batalha final -> créditos ---


func test_vencer_o_coracao_dourado_abre_os_creditos_com_o_jogo_pausado() -> void:
	## Pedrargo nível 30 (o Pedrolim ficou fraco demais no Ciclo 4b e o teste
	## oscilava quando o guardião agia primeiro e o derrubava).
	GameState.equipe_cubelins = [CreatureInstance.new("pedrargo", 30)]
	var batalha := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(batalha)
	batalha.salvador = func() -> bool: return true
	var creditos := CreditsScreenScene.instantiate() as CreditsScreen
	add_child_autofree(creditos)
	GameState.treinadores_vencidos.erase("coracao_dourado")  ## 1ª vitória nesta partida (E0-3)
	batalha._abrir_arena("coracao_dourado")
	# Mesmo truque de test_battle_screen_guardiao: 1 HP garante hit-kill nos 3,
	# e a vida do ativo é restaurada a cada turno pra nenhum revide decidir o teste.
	for i in range(3):
		batalha._batalha.selvagem.vida_atual = 1
		var ativo := batalha._batalha.jogador_ativo()
		ativo.vida_atual = ativo.vida_maxima_efetiva()
		batalha._ao_atacar(0)
	assert_eq(batalha._batalha.resultado, BattleService.Resultado.VITORIA)

	batalha._fechar()

	assert_false(batalha.visible, "batalha deveria fechar")
	assert_true(creditos.visible, "créditos deveriam abrir")
	assert_eq(GameState.current_state, GameState.State.PAUSED)
