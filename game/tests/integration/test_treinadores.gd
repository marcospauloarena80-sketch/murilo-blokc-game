extends GutTest
## Ciclo 9, Frente 9E: treinadores pelo mundo (Tico e Bia), arenas sem insígnia,
## recompensa uma vez por dia de jogo, diálogo "Volte amanhã" e quest opcional.

const BattleScreenScene := preload("res://ui/battle_screen/battle_screen.tscn")
const DialogueScreenScene := preload("res://ui/dialogue_screen/dialogue_screen.tscn")
const NpcScene := preload("res://entities/npcs/npc.tscn")


func before_each() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrargo", 30)]
	GameState.deposito_cubelins = []
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
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
	GameState.tempo_de_jogo_seg = 0.0
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []
	GameState.mudar_estado(GameState.State.PLAYING)


func _vencer(tela: BattleScreen, arena_id: String) -> void:
	tela._abrir_arena(arena_id)
	var total := ArenaRegistry.get_arena(arena_id).equipe.size()
	for i in range(total):
		tela._batalha.selvagem.vida_atual = 1
		tela._ao_atacar(0)


func _dialogo(npc_id: String) -> DialogueScreen:
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	var npc := NpcScene.instantiate() as Npc
	add_child_autofree(npc)
	npc.configurar(NpcRegistry.get_npc(npc_id))
	tela._abrir(npc)
	return tela


func test_registros_tem_tico_e_bia() -> void:
	for id: String in ["treinador_tico", "treinador_bia"]:
		var npc := NpcRegistry.get_npc(id)
		assert_not_null(npc, id)
		assert_eq(npc.papel, "treinador")
		assert_eq(npc.abre_arena, id)
		var arena := ArenaRegistry.get_arena(id)
		assert_not_null(arena)
		assert_false(arena.da_insignia)
		assert_false(arena.recompensa_itens.is_empty())


func test_equipes_e_recompensas_do_plano() -> void:
	var tico := ArenaRegistry.get_arena("treinador_tico")
	assert_eq(tico.equipe.size(), 2)
	assert_eq(tico.recompensa_itens, {"pocao_cura": 2})
	var bia := ArenaRegistry.get_arena("treinador_bia")
	assert_eq(bia.equipe.size(), 3)
	assert_eq(bia.recompensa_itens, {"cubo_captura": 3})


func test_arenas_antigas_continuam_dando_insignia() -> void:
	for id: String in ["pedra", "brasa", "gota", "faisca"]:
		assert_true(ArenaRegistry.get_arena(id).da_insignia, id)
	assert_false(ArenaRegistry.get_arena("coracao_dourado").da_insignia, "desafio final (E0-3)")
	assert_eq(ArenaRegistry.ids_com_insignia().size(), 4)


func test_posicoes_dos_treinadores() -> void:
	assert_eq(Vilarejo.POSICOES_TREINADORES["treinador_tico"], Vector2i(40, 64))
	assert_eq(Vilarejo.POSICOES_TREINADORES["treinador_bia"], Vector2i(88, 64))
	var cena := (load("res://scenes/main.tscn") as PackedScene).get_state()
	var achados: Dictionary = {}
	for i in range(cena.get_node_count()):
		for p in range(cena.get_node_property_count(i)):
			if cena.get_node_property_name(i, p) == "npc_id_inicial":
				achados[cena.get_node_property_value(i, p)] = true
	assert_true(achados.has("treinador_tico"))
	assert_true(achados.has("treinador_bia"))


func test_vitoria_sem_insignia_entrega_recompensa_e_nao_da_insignia() -> void:
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)

	_vencer(tela, "treinador_tico")

	assert_eq(GameState.inventario_mochila.contar("pocao_cura"), 2)
	assert_false(GameState.tem_insignia("treinador_tico"))
	assert_true(GameState.treinadores_vencidos.has("treinador_tico"))


func test_recompensa_so_uma_vez_por_dia_de_jogo() -> void:
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	_vencer(tela, "treinador_tico")
	tela._fechar()

	_vencer(tela, "treinador_tico")
	assert_eq(GameState.inventario_mochila.contar("pocao_cura"), 2, "mesmo dia: sem repetir")
	tela._fechar()

	GameState.tempo_de_jogo_seg = GameState.DURACAO_CICLO_SEG * 1.1
	_vencer(tela, "treinador_tico")
	assert_eq(GameState.inventario_mochila.contar("pocao_cura"), 4, "dia seguinte: recompensa")


func test_revanche_liberada_depois_de_um_dia() -> void:
	assert_true(Treinadores.revanche_liberada("treinador_bia"))
	Treinadores.registrar_vitoria("treinador_bia")
	assert_false(Treinadores.revanche_liberada("treinador_bia"))
	GameState.tempo_de_jogo_seg = GameState.DURACAO_CICLO_SEG + 1.0
	assert_true(Treinadores.revanche_liberada("treinador_bia"))


func test_dialogo_mostra_desafiar_se_liberado() -> void:
	var tela := _dialogo("treinador_bia")
	tela._ao_avancar()
	tela._ao_avancar()

	assert_true(tela._botao_desafiar.visible)


func test_dialogo_fala_volte_amanha_se_ja_venceu_hoje() -> void:
	Treinadores.registrar_vitoria("treinador_bia")
	var tela := _dialogo("treinador_bia")
	tela._ao_avancar()
	tela._ao_avancar()

	assert_false(tela._botao_desafiar.visible)
	assert_eq(tela._label_texto.text, "Volte amanhã.")


func test_final_continua_exigindo_so_as_quatro_insignias() -> void:
	GameState.insignias_conquistadas = ["pedra", "brasa", "gota", "faisca"]
	var tela := _dialogo("guardiao_final")
	for i in range(3):
		tela._ao_avancar()
	assert_true(tela._arena_disponivel())


func test_quest_do_primeiro_treinador_so_depois_da_r1() -> void:
	assert_false(QuestRegistry.liberada("quest_07_primeiro_treinador"))
	GameState.quests_concluidas = ["quest_r1_coleta_diaria"]
	assert_true(QuestRegistry.liberada("quest_07_primeiro_treinador"))


func test_vencer_tico_conclui_a_quest() -> void:
	var tracker := QuestTracker.new()
	add_child_autofree(tracker)
	GameState.iniciar_quest("quest_07_primeiro_treinador")
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)

	_vencer(tela, "treinador_tico")

	assert_true(GameState.quests_concluidas.has("quest_07_primeiro_treinador"))
	assert_eq(GameState.inventario_mochila.contar("cubo_captura"), 2)


func test_dialogo_do_tico_nao_oferece_quest_antes_da_r1() -> void:
	var tela := _dialogo("treinador_tico")
	tela._ao_avancar()
	tela._ao_avancar()

	assert_false(tela._botao_aceitar.visible)
	GameState.quests_concluidas = ["quest_r1_coleta_diaria"]
	tela._atualizar()
	assert_true(tela._botao_aceitar.visible)
