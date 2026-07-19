extends GutTest
## Ver docs/04-ROADMAP.md F5 — critério "fechar e voltar: mundo/posição/
## inventário intactos". Exercita o código real do menu.gd (não atalhos),
## ponta a ponta: Novo Jogo -> joga -> Salva -> Sair -> Continuar.

const MainScene := preload("res://scenes/main.tscn")
const MenuScene := preload("res://scenes/menu.tscn")

var _tinha_save: bool = false
var _conteudo_save: String = ""
var _tinha_backup: bool = false
var _conteudo_backup: String = ""


func before_each() -> void:
	_tinha_save = FileAccess.file_exists(SaveManager.SAVE_PATH)
	if _tinha_save:
		_conteudo_save = FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ).get_as_text()
	_tinha_backup = FileAccess.file_exists(SaveManager.BACKUP_PATH)
	if _tinha_backup:
		_conteudo_backup = FileAccess.open(SaveManager.BACKUP_PATH, FileAccess.READ).get_as_text()
	_remover_se_existir(SaveManager.SAVE_PATH)
	_remover_se_existir(SaveManager.BACKUP_PATH)


func after_each() -> void:
	_remover_se_existir(SaveManager.SAVE_PATH)
	_remover_se_existir(SaveManager.BACKUP_PATH)
	if _tinha_save:
		FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE).store_string(_conteudo_save)
	if _tinha_backup:
		FileAccess.open(SaveManager.BACKUP_PATH, FileAccess.WRITE).store_string(_conteudo_backup)
	GameState.veio_de_continuar = false
	GameState.delta_blocos_carregado = {}


func _remover_se_existir(caminho: String) -> void:
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)


func _drenar_fila(main_instance: Node3D) -> void:
	var cm: ChunkManager = main_instance.get_node("ChunkManager")
	while cm.tem_chunks_pendentes():
		cm._process(0.0)


func test_ciclo_completo_novo_jogo_salvar_sair_continuar() -> void:
	# 1) Menu real: "Novo Jogo" (código de verdade do menu.gd)
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)
	assert_true(
		menu.get_node("VBox/BotaoContinuar").disabled, "sem save, Continuar começa desabilitado"
	)
	menu._ao_novo_jogo()
	remove_child(menu)
	menu.free()

	var seed_da_partida: int = GameState.seed_atual

	# 2) Joga: mundo instanciado de verdade, edita bloco, ganha item
	var main1 := MainScene.instantiate()
	add_child_autofree(main1)
	_drenar_fila(main1)
	var cm1: ChunkManager = main1.get_node("ChunkManager")
	cm1.set_block(Vector3i(7, 40, 7), 3)
	GameState.inventario_mochila.adicionar("tronco", 5)
	var posicao_jogador := Vector3(70.0, 35.0, 70.0)
	main1.get_node("Player").global_position = posicao_jogador

	# 3) Salva de verdade (SaveManager real)
	main1.call("salvar_jogo")
	remove_child(main1)
	main1.free()

	# 4) "Sai pro menu": zera tudo em memória (simula reiniciar o processo)
	GameState.reiniciar_para_novo_jogo()
	assert_ne(
		GameState.seed_atual, seed_da_partida, "seed deveria ter mudado (simulando estado limpo)"
	)

	# 5) Menu de novo: agora "Continuar" deve estar disponível e usar o código real
	var menu2 := MenuScene.instantiate()
	add_child_autofree(menu2)
	assert_false(
		menu2.get_node("VBox/BotaoContinuar").disabled, "com save, Continuar deveria habilitar"
	)
	menu2._ao_continuar()
	remove_child(menu2)
	menu2.free()

	assert_eq(GameState.seed_atual, seed_da_partida, "seed deveria voltar a ser a da partida salva")
	assert_true(GameState.veio_de_continuar)

	# 6) Novo main.tscn "reaberto": delta e posição devem vir do save
	var main2 := MainScene.instantiate()
	add_child_autofree(main2)
	var cm2: ChunkManager = main2.get_node("ChunkManager")
	assert_eq(cm2.get_block(Vector3i(7, 40, 7)), 3, "edição salva deveria estar de volta")
	assert_eq(GameState.inventario_mochila.contar("tronco"), 5, "inventário deveria estar intacto")

	# drenar a fila também dispara mundo_gerado -> Player._ao_mundo_pronto()
	# reposiciona sozinho pra GameState.posicao_salva.
	_drenar_fila(main2)
	var player2: Player = main2.get_node("Player")
	assert_eq(player2.global_position, posicao_jogador, "player deveria voltar pra posição salva")


func test_bau_com_itens_sobrevive_a_salvar_sair_continuar() -> void:
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)
	menu._ao_novo_jogo()
	remove_child(menu)
	menu.free()

	var main1 := MainScene.instantiate()
	add_child_autofree(main1)
	_drenar_fila(main1)
	var chave := GameState.chave_posicao(Vector3i(9, 40, 9))
	GameState.obter_bau(chave).adicionar("carvao", 6)

	main1.call("salvar_jogo")
	remove_child(main1)
	main1.free()

	GameState.reiniciar_para_novo_jogo()

	var menu2 := MenuScene.instantiate()
	add_child_autofree(menu2)
	menu2._ao_continuar()
	remove_child(menu2)
	menu2.free()

	assert_eq(
		GameState.obter_bau(chave).contar("carvao"),
		6,
		"conteúdo do baú deveria sobreviver ao save/continue"
	)


func test_tocha_colocada_reacende_ao_continuar() -> void:
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)
	menu._ao_novo_jogo()
	remove_child(menu)
	menu.free()

	var main1 := MainScene.instantiate()
	add_child_autofree(main1)
	_drenar_fila(main1)
	var cm1: ChunkManager = main1.get_node("ChunkManager")
	cm1.set_block(Vector3i(8, 40, 8), 9)  # tocha

	main1.call("salvar_jogo")
	remove_child(main1)
	main1.free()

	GameState.reiniciar_para_novo_jogo()

	var menu2 := MenuScene.instantiate()
	add_child_autofree(menu2)
	menu2._ao_continuar()
	remove_child(menu2)
	menu2.free()

	var main2 := MainScene.instantiate()
	add_child_autofree(main2)
	_drenar_fila(main2)

	var gerenciador: TorchLightManager = main2.get_node("TorchLightManager")
	assert_eq(gerenciador.get_child_count(), 1, "tocha salva deveria reacender ao continuar")
