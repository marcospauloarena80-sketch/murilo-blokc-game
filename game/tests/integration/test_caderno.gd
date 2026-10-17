extends GutTest
## Caderno de Cubelins (Ciclo 9, 9D): registro de espécies e tela.

const CadernoScreenScene := preload("res://ui/caderno_screen/caderno_screen.tscn")


func before_each() -> void:
	GameState.especies_vistas = []
	GameState.especies_capturadas = []
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []


func after_each() -> void:
	GameState.especies_vistas = []
	GameState.especies_capturadas = []
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []
	GameState.mudar_estado(GameState.State.PLAYING)


func test_acao_caderno_existe_com_tecla_j() -> void:
	var tem_j := false
	for evento in InputMap.action_get_events("caderno"):
		if evento is InputEventKey and evento.physical_keycode == KEY_J:
			tem_j = true
	assert_true(tem_j)


func test_todas_as_18_formas_tem_descricao() -> void:
	var ids := CreatureRegistry.todos_os_ids()
	assert_eq(ids.size(), 18)
	for especie_id: String in ids:
		assert_ne(CreatureRegistry.get_creature(especie_id).descricao, "", especie_id)


func test_batalha_iniciada_registra_vista() -> void:
	var criatura := Creature.new()
	criatura.especie = CreatureRegistry.get_creature("pedrolim")
	EventBus.battle_started.emit(criatura)
	criatura.free()
	assert_true(GameState.especies_vistas.has("pedrolim"))
	assert_false(GameState.especies_capturadas.has("pedrolim"))


func test_batalha_com_null_nao_quebra() -> void:
	EventBus.battle_started.emit(null)
	assert_eq(GameState.especies_vistas.size(), 0)


func test_captura_registra_vista_e_capturada_sem_duplicar() -> void:
	EventBus.creature_captured.emit("brotinho")
	EventBus.creature_captured.emit("brotinho")
	assert_eq(GameState.especies_vistas, ["brotinho"])
	assert_eq(GameState.especies_capturadas, ["brotinho"])


func test_presente_de_missao_registra_capturada() -> void:
	GameState.adicionar_cubelin(CreatureInstance.new("brasita", 4))
	assert_true(GameState.especies_capturadas.has("brasita"))
	assert_true(GameState.especies_vistas.has("brasita"))


func test_abrir_tela_entra_na_pilha_como_caderno() -> void:
	var tela := CadernoScreenScene.instantiate() as CadernoScreen
	add_child_autofree(tela)
	tela._abrir()
	assert_true(tela.visible)
	assert_eq(GameState.telas_abertas, ["caderno"])
	tela._fechar()
	assert_eq(GameState.current_state, GameState.State.PLAYING)


func test_grade_mostra_silhueta_vista_e_capturada() -> void:
	CadernoRegistro.registrar_vista("ventim")
	CadernoRegistro.registrar_capturada("brotinho")
	var tela := CadernoScreenScene.instantiate() as CadernoScreen
	add_child_autofree(tela)
	tela._abrir()
	var grade: GridContainer = tela.get_node("Control/Painel/Margem/VBox/Grade")
	assert_eq(grade.get_child_count(), 18)
	assert_eq((grade.get_node("pedrolim") as Button).text, "???")
	assert_eq((grade.get_node("ventim") as Button).text, "Ventim")
	assert_string_contains((grade.get_node("brotinho") as Button).text, "Capturado")


func test_detalhe_mostra_descricao_e_evolucao_so_para_vista() -> void:
	assert_eq(CadernoScreen.texto_detalhe("pedrolim"), "Ainda não visto.")
	CadernoRegistro.registrar_vista("pedrolim")
	var texto := CadernoScreen.texto_detalhe("pedrolim")
	assert_string_contains(texto, CreatureRegistry.get_creature("pedrolim").descricao)
	assert_string_contains(texto, "Pedrargo")


func test_migracao_save_sem_campos_novos_usa_padrao() -> void:
	var dados: Dictionary = {"especie_id": "brotinho", "nivel": 3}
	var instancia := CreatureInstance.carregar_serializado(dados)
	assert_eq(instancia.apelido, "")
	assert_eq(instancia.nome_exibido(), "Brotinho")
	assert_false(instancia.serializar().has("apelido"))
