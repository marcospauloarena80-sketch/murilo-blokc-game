extends GutTest
## ADR-038: integridade dos saves com validação semântica. Pasta própria em user://
## (nunca o save real). As falhas de cópia e de troca vêm dos pontos de injeção
## `copiar_para_teste` e `renomear_para_teste`, que ficam vazios em produção.
## "Reabrir o jogo" = uma instância nova do SaveManager, sem estado em memória.

const SaveManagerScript := preload("res://autoload/save_manager.gd")

var _raiz: String = ""
var _save: String = ""
var _backup: String = ""


func before_each() -> void:
	_raiz = "user://_teste_integridade_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_raiz)
	_save = _raiz + "/saves/slot.json"
	_backup = _raiz + "/saves/slot.bak.json"
	_limpar_injecoes()


func after_each() -> void:
	_limpar_injecoes()
	_apagar_recursivo(_raiz)


func _limpar_injecoes() -> void:
	SaveManager.renomear_para_teste = Callable()
	SaveManager.copiar_para_teste = Callable()


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


func _reabrir_e_carregar() -> Dictionary:
	var novo: Node = SaveManagerScript.new()
	var dados: Dictionary = novo._carregar_de(_save, _backup)
	novo.free()
	return dados


func _orfaos() -> Array[String]:
	var lista: Array[String] = []
	for nome: String in DirAccess.get_files_at(_save.get_base_dir()):
		if nome.ends_with(".tmp"):
			lista.append(nome)
	return lista


func _falha_na_troca(_o: String, _d: String) -> Error:
	return ERR_FILE_CANT_WRITE


func _falha_na_copia(_o: String, _d: String) -> Error:
	return ERR_FILE_CANT_WRITE


## --- classificação do arquivo ---


func test_estados_do_arquivo_sao_distinguidos() -> void:
	var estado := SaveManager.EstadoArquivo
	assert_eq(SaveManager._avaliar_arquivo(_save), estado.INEXISTENTE)
	_escrever(_save, "{truncado")
	assert_eq(SaveManager._avaliar_arquivo(_save), estado.MALFORMADO)
	_escrever(_save, "{}")
	assert_eq(SaveManager._avaliar_arquivo(_save), estado.VAZIO)
	_escrever(_save, '{"hotbar": []}')
	assert_eq(SaveManager._avaliar_arquivo(_save), estado.ESTRUTURA_INVALIDA, "JSON ok, sem seed")
	_escrever(_save, '{"seed": "x"}')
	assert_eq(
		SaveManager._avaliar_arquivo(_save), estado.ESTRUTURA_INVALIDA, "seed com tipo errado"
	)
	_escrever(_save, '{"seed": 1, "schema_version": 7}')
	assert_eq(SaveManager._avaliar_arquivo(_save), estado.VERSAO_FUTURA)
	_escrever(_save, '{"seed": 1, "schema_version": 1}')
	assert_eq(SaveManager._avaliar_arquivo(_save), estado.VALIDO)


func test_erro_de_leitura_nunca_autoriza_sobrescrever() -> void:
	var estado := SaveManager.EstadoArquivo

	assert_false(SaveManager._pode_gravar_sobre(estado.ERRO_DE_LEITURA, _backup))
	assert_false(SaveManager._pode_gravar_sobre(estado.VERSAO_FUTURA, _backup))
	assert_true(SaveManager._pode_gravar_sobre(estado.VALIDO, _backup))
	assert_true(SaveManager._pode_gravar_sobre(estado.MALFORMADO, _backup))
	assert_true(SaveManager._pode_gravar_sobre(estado.INEXISTENTE, _backup))


## --- dados novos e versões ---


func test_dados_semanticamente_invalidos_nao_sao_gravados() -> void:
	assert_false(SaveManager._gravar({}, _save, _backup))
	assert_false(SaveManager._gravar({"hotbar": []}, _save, _backup), "sem seed")
	assert_false(SaveManager._gravar({"seed": "abc"}, _save, _backup), "seed com tipo errado")
	assert_false(FileAccess.file_exists(_save))
	assert_true(_orfaos().is_empty())


func test_principal_de_versao_futura_nao_e_sobrescrito() -> void:
	var futuro := '{"seed": 9, "schema_version": 5, "novo_campo": [1, 2]}'
	_escrever(_save, futuro)

	assert_false(SaveManager._gravar({"seed": 1}, _save, _backup))

	assert_eq(_ler(_save), futuro, "bytes idênticos")
	assert_false(FileAccess.file_exists(_backup))
	assert_true(_orfaos().is_empty())


func test_backup_de_versao_futura_nao_e_sobrescrito_pela_copia_do_principal() -> void:
	SaveManager._gravar({"seed": 1}, _save, _backup)
	var futuro := '{"seed": 9, "schema_version": 5}'
	_escrever(_backup, futuro)

	assert_false(SaveManager._gravar({"seed": 2}, _save, _backup))

	assert_eq(_ler(_backup), futuro)
	assert_eq(int(JSON.parse_string(_ler(_save))["seed"]), 1, "principal também intacto")


## --- principal semanticamente inválido + backup válido ---


func _principal_invalido_backup_valido() -> String:
	SaveManager._gravar({"seed": 1}, _save, _backup)
	SaveManager._gravar({"seed": 2}, _save, _backup)  ## backup = seed 1
	_escrever(_save, '{"hotbar": [], "schema_version": 1}')  ## JSON válido, sem seed
	return _ler(_backup)


func test_principal_semanticamente_invalido_e_recuperado_pelo_backup_inclusive_ao_reabrir() -> void:
	_principal_invalido_backup_valido()

	assert_eq(int(SaveManager._carregar_de(_save, _backup)["seed"]), 1)
	assert_eq(int(_reabrir_e_carregar()["seed"]), 1)


func test_recuperar_pelo_backup_e_salvar_de_novo_preserva_o_backup_e_grava_o_principal() -> void:
	var backup_antes := _principal_invalido_backup_valido()
	var recuperado := _reabrir_e_carregar()
	recuperado["seed"] = 11

	assert_true(SaveManager._gravar(recuperado, _save, _backup))

	assert_eq(_ler(_backup), backup_antes, "o principal inválido não foi copiado por cima")
	assert_eq(int(JSON.parse_string(_ler(_save))["seed"]), 11)
	assert_true(_orfaos().is_empty())


func test_falha_na_troca_com_principal_invalido_preserva_backup_e_principal_e_recupera() -> void:
	var backup_antes := _principal_invalido_backup_valido()
	var principal_antes := _ler(_save)
	SaveManager.renomear_para_teste = _falha_na_troca

	var gravou := SaveManager._gravar({"seed": 77}, _save, _backup)

	assert_false(gravou, "falha comunicada, nenhum sucesso silencioso")
	assert_eq(_ler(_backup), backup_antes, "backup válido: bytes idênticos")
	assert_eq(_ler(_save), principal_antes, "principal não foi trocado por dados novos")
	assert_true(_orfaos().is_empty())
	assert_eq(int(_reabrir_e_carregar()["seed"]), 1, "reabrir recupera o progresso")


func test_falha_na_copia_com_principal_invalido_nao_precisa_copiar_nada() -> void:
	## Principal inválido nunca é copiado; logo a falha de cópia nem é exercida.
	var backup_antes := _principal_invalido_backup_valido()
	SaveManager.copiar_para_teste = _falha_na_copia

	assert_true(SaveManager._gravar({"seed": 8}, _save, _backup))

	assert_eq(_ler(_backup), backup_antes)
