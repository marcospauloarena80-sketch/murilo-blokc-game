extends GutTest
## Ver docs/01-GDD.md §12 e docs/07-DECISOES.md ADR-022. Mesmo padrão de
## chest/battle screen: chama a orquestração direto.

const DialogueScreenScene := preload("res://ui/dialogue_screen/dialogue_screen.tscn")
const NpcScene := preload("res://entities/npcs/npc.tscn")


func _npc_com_def(def: NpcDef) -> Npc:
	var npc := NpcScene.instantiate() as Npc
	add_child_autofree(npc)
	npc.configurar(def)
	return npc


func before_each() -> void:
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)


func after_each() -> void:
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []
	GameState.mudar_estado(GameState.State.PLAYING)


func test_abrir_pausa_o_jogo_e_mostra_a_primeira_linha() -> void:
	var def := NpcDef.new()
	def.nome = "Lina"
	def.linhas_dialogo = ["Olá!", "Tudo bem?"]
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)

	tela._abrir(_npc_com_def(def))

	assert_true(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PAUSED)
	assert_eq(tela._indice_linha, 0)


func test_fechar_despausa_e_esconde() -> void:
	var def := NpcDef.new()
	def.linhas_dialogo = ["Oi"]
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	tela._fechar()

	assert_false(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PLAYING)


func test_avancar_percorre_as_linhas() -> void:
	var def := NpcDef.new()
	def.linhas_dialogo = ["Um", "Dois", "Três"]
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	tela._ao_avancar()
	assert_eq(tela._indice_linha, 1)
	tela._ao_avancar()
	assert_eq(tela._indice_linha, 2)


func test_sem_missao_oferecida_mostra_so_fechar_apos_as_linhas() -> void:
	var def := NpcDef.new()
	def.linhas_dialogo = ["Só isso"]
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	tela._ao_avancar()

	assert_false(tela._oferece_quest_pendente())
	assert_true(tela._botao_fechar.visible)
	assert_false(tela._botao_aceitar.visible)


func test_missao_oferecida_e_pendente_mostra_aceitar_e_recusar() -> void:
	var def := NpcDef.new()
	def.linhas_dialogo = ["Preciso de ajuda"]
	def.oferece_quest_id = "quest_teste"
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	tela._ao_avancar()

	assert_true(tela._oferece_quest_pendente())
	assert_true(tela._botao_aceitar.visible)
	assert_true(tela._botao_recusar.visible)
	assert_false(tela._botao_fechar.visible)


func test_aceitar_inicia_a_quest_e_fecha() -> void:
	var def := NpcDef.new()
	def.linhas_dialogo = []
	def.oferece_quest_id = "quest_teste"
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	tela._ao_aceitar_quest()

	assert_eq(GameState.quest_atual_id, "quest_teste")
	assert_false(tela.visible)


func test_recusar_nao_inicia_a_quest_mas_fecha() -> void:
	var def := NpcDef.new()
	def.linhas_dialogo = []
	def.oferece_quest_id = "quest_teste"
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	tela._ao_recusar_quest()

	assert_eq(GameState.quest_atual_id, "")
	assert_false(tela.visible)


func test_missao_ja_concluida_nao_e_oferecida_de_novo() -> void:
	GameState.quests_concluidas = ["quest_teste"]
	var def := NpcDef.new()
	def.linhas_dialogo = []
	def.oferece_quest_id = "quest_teste"
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	assert_false(tela._oferece_quest_pendente())


func test_missao_ja_ativa_nao_e_oferecida_de_novo() -> void:
	GameState.quest_atual_id = "quest_teste"
	var def := NpcDef.new()
	def.linhas_dialogo = []
	def.oferece_quest_id = "quest_teste"
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	assert_false(tela._oferece_quest_pendente())


func test_abrir_npc_com_laboratorio_e_com_cura_dispara_a_cura() -> void:
	GameState.vida_atual = 1
	var def := NpcDef.new()
	def.linhas_dialogo = []
	def.cura_ao_interagir = true
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)

	tela._abrir(_npc_com_def(def))

	assert_eq(GameState.vida_atual, GameState.vida_maxima)


func test_npc_com_laboratorio_mostra_o_botao_apos_as_linhas() -> void:
	var def := NpcDef.new()
	def.linhas_dialogo = ["Oi"]
	def.abre_laboratorio = true
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	tela._ao_avancar()

	assert_true(tela._botao_laboratorio.visible)


func test_abrir_laboratorio_emite_o_sinal_e_fecha() -> void:
	var def := NpcDef.new()
	def.linhas_dialogo = []
	def.abre_laboratorio = true
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	var recebido: Array = [false]
	var callback := func() -> void: recebido[0] = true
	EventBus.laboratorio_requested.connect(callback)

	tela._ao_abrir_laboratorio()

	EventBus.laboratorio_requested.disconnect(callback)
	assert_true(recebido[0])
	assert_false(tela.visible)


func test_troca_consome_o_item_pedido_e_da_o_oferecido() -> void:
	GameState.inventario_mochila.adicionar("pedra", 5)
	var def := NpcDef.new()
	def.linhas_dialogo = []
	def.troca_pede_item = "pedra"
	def.troca_pede_quantidade = 5
	def.troca_oferece_item = "ferrite"
	def.troca_oferece_quantidade = 1
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	tela._ao_trocar()

	assert_eq(GameState.inventario_mochila.contar("pedra"), 0)
	assert_eq(GameState.inventario_mochila.contar("ferrite"), 1)


func test_troca_sem_item_suficiente_nao_faz_nada() -> void:
	GameState.inventario_mochila.adicionar("pedra", 2)
	var def := NpcDef.new()
	def.linhas_dialogo = []
	def.troca_pede_item = "pedra"
	def.troca_pede_quantidade = 5
	def.troca_oferece_item = "ferrite"
	def.troca_oferece_quantidade = 1
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(_npc_com_def(def))

	tela._ao_trocar()

	assert_eq(GameState.inventario_mochila.contar("pedra"), 2)
	assert_eq(GameState.inventario_mochila.contar("ferrite"), 0)
