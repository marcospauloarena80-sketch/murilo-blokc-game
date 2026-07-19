extends GutTest
## Ver docs/07-DECISOES.md ADR-006 (F5) — scenes/main.gd orquestra o save real.
## Cuidado: mesma proteção de SAVE_PATH/BACKUP_PATH do test_save_manager.gd
## pra não apagar um save de playtest real nem deixar lixo entre execuções.

const MainScene := preload("res://scenes/main.tscn")

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

	GameState.reiniciar_para_novo_jogo()
	GameState.seed_atual = 555


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


func test_salvar_jogo_grava_estado_real_da_cena() -> void:
	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)
	_drenar_fila(main_instance)

	GameState.inventario_mochila.adicionar("pedra", 7)
	var cm: ChunkManager = main_instance.get_node("ChunkManager")
	cm.set_block(Vector3i(3, 40, 3), 3)

	main_instance.salvar_jogo()

	var dados := SaveManager.carregar()
	assert_eq(int(dados["seed"]), 555)
	assert_true(dados["delta_blocos"].has("3,40,3"))

	var mochila := InventoryModel.new(24)
	mochila.carregar_serializado(dados["mochila"])
	assert_eq(mochila.contar("pedra"), 7)


func test_continuar_aplica_delta_salvo_num_chunk_manager_novo() -> void:
	GameState.veio_de_continuar = true
	GameState.delta_blocos_carregado = {"4,40,4": 3}

	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)

	var cm: ChunkManager = main_instance.get_node("ChunkManager")
	assert_eq(cm.get_block(Vector3i(4, 40, 4)), 3, "delta do save deveria ter sido aplicado")
