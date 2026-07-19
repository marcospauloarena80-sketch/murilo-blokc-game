extends GutTest
## Ver docs/07-DECISOES.md ADR-006. Cuidado: SAVE_PATH/BACKUP_PATH são os
## mesmos arquivos que o jogo de verdade usaria nesta máquina — cada teste
## faz backup dos dois e restaura no fim, pra não apagar um save de playtest
## real nem deixar lixo pro próximo teste (carregar() cai no backup se o
## save principal não existir).

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


func _remover_se_existir(caminho: String) -> void:
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)


func test_salvar_e_carregar_ida_e_volta() -> void:
	SaveManager.salvar({"seed": 12345, "tempo_de_jogo_seg": 42.0})
	var dados := SaveManager.carregar()
	assert_eq(int(dados["seed"]), 12345)
	assert_eq(int(dados["schema_version"]), SaveManager.SCHEMA_VERSION)


func test_existe_save_reflete_o_arquivo() -> void:
	assert_false(SaveManager.existe_save())
	SaveManager.salvar({"seed": 1})
	assert_true(SaveManager.existe_save())


func test_carregar_sem_save_retorna_vazio() -> void:
	assert_eq(SaveManager.carregar(), {})


func test_salvar_faz_backup_do_anterior() -> void:
	SaveManager.salvar({"seed": 1})
	SaveManager.salvar({"seed": 2})
	assert_true(FileAccess.file_exists(SaveManager.BACKUP_PATH))
	var arquivo := FileAccess.open(SaveManager.BACKUP_PATH, FileAccess.READ)
	var backup: Dictionary = JSON.parse_string(arquivo.get_as_text())
	assert_eq(int(backup["seed"]), 1, "backup deveria ter o save anterior, não o atual")


func test_migrar_marca_versao_futura_sem_quebrar() -> void:
	var dados := {"seed": 1, "schema_version": 999}
	var migrado := SaveManager.migrar(dados)
	assert_eq(migrado["seed"], 1)
