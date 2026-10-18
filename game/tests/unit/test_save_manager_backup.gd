extends GutTest
## ADR-037: um principal inválido nunca substitui um backup válido, e uma falha na
## troca do arquivo principal sempre deixa pelo menos uma cópia recuperável.
## A falha de `rename_absolute` é injetada por `SaveManager.renomear_para_teste`
## (ponto só para testes; vazio em produção). Pasta própria em user://.

var _raiz: String = ""
var _save: String = ""
var _backup: String = ""


func before_each() -> void:
	_raiz = "user://_teste_backup_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_raiz)
	_save = _raiz + "/saves/slot.json"
	_backup = _raiz + "/saves/slot.bak.json"
	SaveManager.renomear_para_teste = Callable()


func after_each() -> void:
	SaveManager.renomear_para_teste = Callable()
	_apagar_recursivo(_raiz)


func _apagar_recursivo(caminho: String) -> void:
	var dir := DirAccess.open(caminho)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_apagar_recursivo(caminho + "/" + sub)
	for arq: String in dir.get_files():
		DirAccess.remove_absolute(caminho + "/" + arq)
	DirAccess.remove_absolute(caminho)


func _ler(caminho: String) -> String:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	return "" if arquivo == null else arquivo.get_as_text()


func _escrever(caminho: String, texto: String) -> void:
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	FileAccess.open(caminho, FileAccess.WRITE).store_string(texto)


func _preparar_principal_corrompido_com_backup_valido() -> String:
	SaveManager._gravar({"seed": 1}, _save, _backup)
	SaveManager._gravar({"seed": 2}, _save, _backup)  ## backup = seed 1
	_escrever(_save, "{queda no meio da escrita")
	return _ler(_backup)


func _falhar_a_troca(_origem: String, _destino: String) -> Error:
	return ERR_FILE_CANT_WRITE


func test_principal_corrompido_com_backup_valido_e_recuperavel() -> void:
	_preparar_principal_corrompido_com_backup_valido()

	assert_false(SaveManager._e_valido(_save))
	assert_true(SaveManager._e_valido(_backup))
	assert_eq(int(SaveManager._carregar_de(_save, _backup)["seed"]), 1)


func test_salvar_apos_recuperar_pelo_backup_nao_copia_o_corrompido_por_cima_do_backup() -> void:
	var backup_antes := _preparar_principal_corrompido_com_backup_valido()
	var recuperado := SaveManager._carregar_de(_save, _backup)
	recuperado["seed"] = 10  ## o jogo continua e salva de novo

	assert_true(SaveManager._gravar(recuperado, _save, _backup))

	assert_eq(_ler(_backup), backup_antes, "o backup válido não foi sobrescrito")
	assert_eq(int(JSON.parse_string(_ler(_save))["seed"]), 10)
	assert_true(SaveManager._e_valido(_save))


func test_falha_na_troca_com_principal_corrompido_preserva_o_backup_e_os_dados() -> void:
	var backup_antes := _preparar_principal_corrompido_com_backup_valido()
	SaveManager.renomear_para_teste = _falhar_a_troca

	var gravou := SaveManager._gravar({"seed": 99}, _save, _backup)
	SaveManager.renomear_para_teste = Callable()

	assert_false(gravou, "a falha é declarada, nunca um falso sucesso")
	assert_eq(_ler(_backup), backup_antes, "backup válido intacto, byte a byte")
	assert_eq(int(SaveManager._carregar_de(_save, _backup)["seed"]), 1, "dados recuperáveis")
	assert_false(FileAccess.file_exists(_save + ".tmp"), "nenhum temporário órfão")


func test_falha_destrutiva_na_troca_com_principal_valido_ainda_recupera_pelo_backup() -> void:
	## Pior caso: a troca falha depois de o principal já ter sumido.
	SaveManager._gravar({"seed": 1}, _save, _backup)
	var apagar_e_falhar := func(_origem: String, destino: String) -> Error:
		DirAccess.remove_absolute(destino)
		return ERR_FILE_CANT_WRITE
	SaveManager.renomear_para_teste = apagar_e_falhar

	var gravou := SaveManager._gravar({"seed": 2}, _save, _backup)
	SaveManager.renomear_para_teste = Callable()

	assert_false(gravou)
	assert_false(FileAccess.file_exists(_save), "o principal de fato se perdeu nesse cenário")
	assert_eq(int(SaveManager._carregar_de(_save, _backup)["seed"]), 1, "o backup guarda a versão")
	assert_false(FileAccess.file_exists(_save + ".tmp"))


func test_salvamento_posterior_apos_a_falha_funciona_sem_temporarios_orfaos() -> void:
	var backup_antes := _preparar_principal_corrompido_com_backup_valido()
	SaveManager.renomear_para_teste = _falhar_a_troca
	SaveManager._gravar({"seed": 99}, _save, _backup)
	SaveManager.renomear_para_teste = Callable()

	assert_true(SaveManager._gravar({"seed": 5}, _save, _backup))

	assert_eq(int(JSON.parse_string(_ler(_save))["seed"]), 5)
	assert_true(SaveManager._e_valido(_save))
	assert_eq(_ler(_backup), backup_antes, "o backup continua sendo o último estado bom conhecido")
	assert_false(FileAccess.file_exists(_save + ".tmp"))
	var arquivos := DirAccess.get_files_at(_save.get_base_dir())
	for nome: String in arquivos:
		assert_false(nome.ends_with(".tmp"), "órfão: " + nome)


func test_principal_corrompido_sem_backup_grava_sem_criar_backup_do_lixo() -> void:
	_escrever(_save, "{lixo")

	assert_true(SaveManager._gravar({"seed": 4}, _save, _backup))

	assert_false(FileAccess.file_exists(_backup), "não copia um principal inválido para o backup")
	assert_eq(int(JSON.parse_string(_ler(_save))["seed"]), 4)


func test_principal_valido_continua_indo_para_o_backup_como_antes() -> void:
	SaveManager._gravar({"seed": 1}, _save, _backup)

	SaveManager._gravar({"seed": 2}, _save, _backup)

	assert_eq(int(JSON.parse_string(_ler(_backup))["seed"]), 1)
	assert_eq(int(JSON.parse_string(_ler(_save))["seed"]), 2)


func test_o_ponto_de_injecao_fica_vazio_por_padrao_em_producao() -> void:
	assert_false(SaveManager.renomear_para_teste.is_valid())
