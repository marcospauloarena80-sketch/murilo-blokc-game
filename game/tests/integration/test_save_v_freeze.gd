extends GutTest
## Ver docs/07-DECISOES.md ADR-006 (F5) e ADR-025 (F12) — "v-freeze": a partir
## da 1.0, o schema v1 é o compromisso de compatibilidade. Este teste prova
## que um save mínimo da própria F5 (só os campos que existiam antes de
## qualquer conteúdo de F6-F11) ainda carrega sem quebrar, com defaults
## sãos pra tudo que foi adicionado depois — sem precisar de migração
## numerada de verdade, porque nunca houve remoção/reestruturação de campo,
## só adição (cada leitura em menu.gd usa .get(chave, default)).
## Mesma proteção de SAVE_PATH/BACKUP_PATH do test_main_save_flow.gd.

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
	GameState.reiniciar_para_novo_jogo()


func _remover_se_existir(caminho: String) -> void:
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)


func _escrever_save_minimo_da_f5() -> void:
	var dados := {
		"schema_version": 1,
		"seed": 777,
		"hotbar": [],
		"mochila": [],
		"delta_blocos": {},
		"jogador_posicao": [64.0, 45.0, 64.0],
	}
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE).store_string(JSON.stringify(dados))


func test_save_minimo_da_f5_carrega_sem_quebrar() -> void:
	_escrever_save_minimo_da_f5()
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)

	menu._ao_continuar()

	assert_eq(GameState.seed_atual, 777)
	assert_true(GameState.veio_de_continuar)


func test_save_minimo_da_f5_preenche_defaults_de_conteudo_novo() -> void:
	_escrever_save_minimo_da_f5()
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)

	menu._ao_continuar()

	assert_eq(GameState.equipe_cubelins.size(), 0)
	assert_eq(GameState.deposito_cubelins.size(), 0)
	assert_eq(GameState.quest_atual_id, "")
	assert_eq(GameState.quests_concluidas.size(), 0)
	assert_eq(GameState.insignias_conquistadas.size(), 0)
	assert_eq(GameState.baus.size(), 0)
