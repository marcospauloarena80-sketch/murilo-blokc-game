extends GutTest
## ADR-033: os créditos do Coração Dourado saem uma vez só e só depois de a
## conclusão estar gravada no save. Antes, o registro vivia só na memória:
## voltar ao menu e continuar reabria os créditos numa nova vitória.
## Mesma proteção de SAVE_PATH/BACKUP_PATH de test_main_save_flow.gd.

const BattleScreenScene := preload("res://ui/battle_screen/battle_screen.tscn")
const MainScene := preload("res://scenes/main.tscn")
const MenuScript := preload("res://scenes/menu.gd")
const ARENA_FINAL := "coracao_dourado"

var _tinha_save: bool = false
var _conteudo_save: String = ""
var _tinha_backup: bool = false
var _conteudo_backup: String = ""
var _creditos: int = 0
var _avisos: Array[String] = []
var _ordem: Array[String] = []


func before_each() -> void:
	_tinha_save = FileAccess.file_exists(SaveManager.SAVE_PATH)
	if _tinha_save:
		_conteudo_save = FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ).get_as_text()
	_tinha_backup = FileAccess.file_exists(SaveManager.BACKUP_PATH)
	if _tinha_backup:
		_conteudo_backup = FileAccess.open(SaveManager.BACKUP_PATH, FileAccess.READ).get_as_text()
	_remover_se_existir(SaveManager.SAVE_PATH)
	_remover_se_existir(SaveManager.BACKUP_PATH)

	GameState.reiniciar_para_novo_jogo()
	GameState.equipe_cubelins = [CreatureInstance.new("pedrargo", 30)]
	_creditos = 0
	_avisos = []
	_ordem = []
	EventBus.game_completed.connect(_ao_creditos)
	EventBus.aviso.connect(_ao_aviso)


func after_each() -> void:
	EventBus.game_completed.disconnect(_ao_creditos)
	EventBus.aviso.disconnect(_ao_aviso)
	_remover_se_existir(SaveManager.SAVE_PATH)
	_remover_se_existir(SaveManager.BACKUP_PATH)
	if _tinha_save:
		FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE).store_string(_conteudo_save)
	if _tinha_backup:
		FileAccess.open(SaveManager.BACKUP_PATH, FileAccess.WRITE).store_string(_conteudo_backup)
	GameState.equipe_cubelins = []
	GameState.treinadores_vencidos = {}
	GameState.insignias_conquistadas = []
	GameState.veio_de_continuar = false
	GameState.delta_blocos_carregado = {}
	GameState.mudar_estado(GameState.State.PLAYING)


func _ao_creditos() -> void:
	_creditos += 1
	_ordem.append("creditos")


func _ao_aviso(texto: String) -> void:
	_avisos.append(texto)


func _remover_se_existir(caminho: String) -> void:
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)


func _nova_tela(salvador: Callable) -> BattleScreen:
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela.salvador = salvador
	return tela


func _vencer_o_final_e_fechar(tela: BattleScreen) -> void:
	tela._abrir_arena(ARENA_FINAL)
	for i in range(3):
		tela._batalha.selvagem.vida_atual = 1
		var ativo := tela._batalha.jogador_ativo()
		ativo.vida_atual = ativo.vida_maxima_efetiva()
		tela._ao_atacar(0)
	assert_eq(tela._batalha.resultado, BattleService.Resultado.VITORIA, "pré-condição: venceu")
	tela._fechar()


func test_primeira_vitoria_grava_antes_de_abrir_os_creditos() -> void:
	var gravado: Array = [{}]
	var salvador := func() -> bool:
		_ordem.append("salvou")
		gravado[0] = GameState.treinadores_vencidos.duplicate()
		return true
	var tela := _nova_tela(salvador)

	_vencer_o_final_e_fechar(tela)

	assert_eq(_ordem, ["salvou", "creditos"], "gravar vem antes dos créditos")
	assert_true(gravado[0].has(ARENA_FINAL), "a conclusão já estava no que foi gravado")
	assert_eq(_creditos, 1)


func test_revanche_na_mesma_sessao_nao_reabre_os_creditos() -> void:
	var gravacoes: Array = [0]
	var tela := _nova_tela(
		func() -> bool:
			gravacoes[0] += 1
			return true
	)

	_vencer_o_final_e_fechar(tela)
	_vencer_o_final_e_fechar(tela)

	assert_eq(_creditos, 1)
	assert_eq(gravacoes[0], 1, "a conclusão é gravada uma vez só")


func test_nenhuma_insignia_do_coracao_dourado_e_concedida() -> void:
	var tela := _nova_tela(func() -> bool: return true)

	_vencer_o_final_e_fechar(tela)

	assert_false(GameState.tem_insignia(ARENA_FINAL))
	assert_true(GameState.insignias_conquistadas.is_empty())


func _vencer_o_final_sem_fechar(tela: BattleScreen) -> void:
	tela._abrir_arena(ARENA_FINAL)
	for i in range(3):
		tela._batalha.selvagem.vida_atual = 1
		var ativo := tela._batalha.jogador_ativo()
		ativo.vida_atual = ativo.vida_maxima_efetiva()
		tela._ao_atacar(0)
	assert_eq(tela._batalha.resultado, BattleService.Resultado.VITORIA, "pré-condição: venceu")


func _contar_vitorias_de_treinador() -> Array:
	var vezes: Array = [0]
	EventBus.treinador_vencido.connect(func(_id: String) -> void: vezes[0] += 1)
	return vezes


func test_primeira_tentativa_ok_grava_uma_vez_e_abre_os_creditos() -> void:
	var gravacoes: Array = [0]
	var tela := _nova_tela(
		func() -> bool:
			gravacoes[0] += 1
			return true
	)

	_vencer_o_final_e_fechar(tela)

	assert_eq(gravacoes[0], 1)
	assert_eq(_creditos, 1)
	assert_false(tela.visible, "a batalha fecha")
	assert_true(GameState.treinadores_vencidos.has(ARENA_FINAL))


func test_falha_ao_gravar_mantem_a_batalha_aberta_com_as_duas_saidas() -> void:
	var tela := _nova_tela(func() -> bool: return false)

	_vencer_o_final_e_fechar(tela)

	assert_eq(_creditos, 0, "sem gravação confirmada, sem créditos")
	assert_true(tela.visible, "a batalha segue aberta e consistente")
	assert_eq(tela._batalha.resultado, BattleService.Resultado.VITORIA)
	assert_true(tela._botao_tentar_salvar.visible)
	assert_true(tela._botao_sair_sem_creditos.visible)
	assert_false(tela._botao_fechar.visible, "só as duas saídas")
	assert_string_contains(tela._label_status.text, "não foi possível salvar")
	assert_false(GameState.tem_insignia(ARENA_FINAL))


func test_falha_seguida_de_sucesso_na_segunda_tentativa() -> void:
	var sucesso: Array = [false]
	var gravacoes: Array = [0]
	var vitorias := _contar_vitorias_de_treinador()
	var tela := _nova_tela(
		func() -> bool:
			gravacoes[0] += 1
			return sucesso[0]
	)
	var mochila_antes: Array = GameState.inventario_mochila.serializar()
	_vencer_o_final_e_fechar(tela)
	assert_eq(_creditos, 0)

	sucesso[0] = true
	tela._ao_tentar_salvar_de_novo()

	assert_eq(gravacoes[0], 2, "só regravou, uma tentativa por clique")
	assert_eq(_creditos, 1, "créditos abrem uma vez, depois de gravar")
	assert_false(tela.visible)
	assert_true(GameState.treinadores_vencidos.has(ARENA_FINAL))
	assert_eq(vitorias[0], 1, "a vitória foi registrada uma única vez")
	assert_eq(GameState.inventario_mochila.serializar(), mochila_antes, "sem recompensa duplicada")
	assert_false(GameState.tem_insignia(ARENA_FINAL))


func test_falhas_repetidas_nao_duplicam_nada_e_continuam_pendentes() -> void:
	var vitorias := _contar_vitorias_de_treinador()
	var tela := _nova_tela(func() -> bool: return false)
	_vencer_o_final_e_fechar(tela)

	tela._ao_tentar_salvar_de_novo()
	tela._ao_tentar_salvar_de_novo()

	assert_true(tela.visible)
	assert_true(tela._botao_tentar_salvar.visible)
	assert_eq(_creditos, 0)
	assert_eq(vitorias[0], 1)
	assert_true(GameState.treinadores_vencidos.has(ARENA_FINAL))


func test_falha_persistente_e_sair_sem_creditos() -> void:
	var tela := _nova_tela(func() -> bool: return false)
	_vencer_o_final_e_fechar(tela)

	tela._ao_sair_sem_creditos()

	assert_eq(_creditos, 0, "sair não abre créditos")
	assert_false(tela.visible)
	assert_false(
		GameState.treinadores_vencidos.has(ARENA_FINAL), "a conclusão não fica como registrada"
	)
	assert_false(GameState.tem_insignia(ARENA_FINAL), "nenhuma insígnia final")
	assert_eq(_avisos.size(), 1)
	assert_string_contains(_avisos[0], "Conclusão não salva")


func test_depois_de_sair_sem_creditos_uma_vitoria_futura_vale_como_a_primeira() -> void:
	var sucesso: Array = [false]
	var tela := _nova_tela(func() -> bool: return sucesso[0])
	_vencer_o_final_e_fechar(tela)
	tela._ao_sair_sem_creditos()

	sucesso[0] = true
	_vencer_o_final_e_fechar(tela)

	assert_eq(_creditos, 1)
	assert_true(GameState.treinadores_vencidos.has(ARENA_FINAL))


func test_botoes_de_falha_nao_fazem_nada_fora_do_estado_de_falha() -> void:
	var gravacoes: Array = [0]
	var tela := _nova_tela(
		func() -> bool:
			gravacoes[0] += 1
			return true
	)
	_vencer_o_final_sem_fechar(tela)

	tela._ao_tentar_salvar_de_novo()
	tela._ao_sair_sem_creditos()

	assert_eq(gravacoes[0], 0)
	assert_eq(_creditos, 0)
	assert_true(tela.visible)
	assert_false(tela._botao_tentar_salvar.visible)


func test_sem_cena_que_salve_a_falha_e_tratada_como_nao_gravado() -> void:
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)  ## sem `salvador`: usa a cena atual (a do GUT não salva)

	_vencer_o_final_e_fechar(tela)

	assert_eq(_creditos, 0)
	assert_true(tela.visible, "fica aguardando uma das duas saídas")


func test_falha_depois_sucesso_com_save_real_e_revanche_apos_carregar_nao_reabre_creditos() -> void:
	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)
	var cm: ChunkManager = main_instance.get_node("ChunkManager")
	while cm.tem_chunks_pendentes():
		cm._process(0.0)
	var tentativas: Array = [0]
	var tela := _nova_tela(
		func() -> bool:
			tentativas[0] += 1
			return false if tentativas[0] == 1 else main_instance.salvar_jogo()
	)
	_vencer_o_final_e_fechar(tela)
	assert_eq(_creditos, 0)
	assert_false(FileAccess.file_exists(SaveManager.SAVE_PATH), "nada gravado na 1ª tentativa")

	tela._ao_tentar_salvar_de_novo()

	assert_eq(_creditos, 1)
	var dados := SaveManager.carregar()
	assert_true(dados["treinadores_vencidos"].has(ARENA_FINAL), "conclusão persistida")
	GameState.treinadores_vencidos = MenuScript._dicionario_de_dias(dados["treinadores_vencidos"])
	var tela_depois := _nova_tela(Callable(main_instance, "salvar_jogo"))
	_vencer_o_final_e_fechar(tela_depois)
	assert_eq(_creditos, 1, "a revanche depois de carregar não reabre os créditos")


func test_salvar_jogo_devolve_true_e_grava_a_conclusao_no_arquivo() -> void:
	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)
	var cm: ChunkManager = main_instance.get_node("ChunkManager")
	while cm.tem_chunks_pendentes():
		cm._process(0.0)
	GameState.treinadores_vencidos[ARENA_FINAL] = 3

	var gravou: bool = main_instance.salvar_jogo()

	assert_true(gravou)
	var dados := SaveManager.carregar()
	assert_true(dados["treinadores_vencidos"].has(ARENA_FINAL))


func test_voltar_ao_menu_e_continuar_depois_da_primeira_vitoria_nao_reabre_os_creditos() -> void:
	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)
	var cm: ChunkManager = main_instance.get_node("ChunkManager")
	while cm.tem_chunks_pendentes():
		cm._process(0.0)
	var tela := _nova_tela(Callable(main_instance, "salvar_jogo"))

	_vencer_o_final_e_fechar(tela)
	assert_eq(_creditos, 1, "primeira vitória abre os créditos")

	## "Voltar ao menu" + "Continuar": a memória é trocada pelo que o menu lê do save.
	GameState.treinadores_vencidos = {}
	var dados := SaveManager.carregar()
	GameState.treinadores_vencidos = MenuScript._dicionario_de_dias(
		dados.get("treinadores_vencidos", {})
	)
	assert_true(GameState.treinadores_vencidos.has(ARENA_FINAL), "conclusão preservada no save")

	var tela_depois := _nova_tela(Callable(main_instance, "salvar_jogo"))
	_vencer_o_final_e_fechar(tela_depois)

	assert_eq(_creditos, 1, "a revanche depois de continuar não reabre os créditos")
