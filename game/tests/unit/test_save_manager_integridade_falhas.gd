extends GutTest
## ADR-038 (parte 2): ambos válidos com falha intermediária, e depois da falha.
## (nunca o save real). As falhas de cópia e de troca vêm dos pontos de injeção
## `copiar_para_teste` e `renomear_para_teste`, que ficam vazios em produção.
## "Reabrir o jogo" = uma instância nova do SaveManager, sem estado em memória.

const SaveManagerScript := preload("res://autoload/save_manager.gd")

var _raiz: String = ""
var _save: String = ""
var _backup: String = ""


func before_each() -> void:
	_raiz = "user://_teste_integ2_%d" % Time.get_ticks_usec()
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


## --- principal e backup válidos, falha intermediária ---


func _ambos_validos() -> Array[String]:
	SaveManager._gravar({"seed": 1}, _save, _backup)
	SaveManager._gravar({"seed": 2}, _save, _backup)  ## backup = seed 1; principal = seed 2
	return [_ler(_save), _ler(_backup)]


func test_falha_na_copia_do_backup_preserva_o_principal_valido() -> void:
	var antes := _ambos_validos()
	SaveManager.copiar_para_teste = _falha_na_copia

	assert_false(SaveManager._gravar({"seed": 3}, _save, _backup))

	assert_eq(_ler(_save), antes[0], "principal intacto, byte a byte")
	assert_true(_orfaos().is_empty())
	assert_eq(int(_reabrir_e_carregar()["seed"]), 2)


func test_copia_destrutiva_que_trunca_o_backup_ainda_deixa_o_principal_recuperavel() -> void:
	var antes := _ambos_validos()
	SaveManager.copiar_para_teste = func(_o: String, d: String) -> Error:
		_escrever(d, "{truncado")  ## estraga o backup e relata erro
		return ERR_FILE_CANT_WRITE

	assert_false(SaveManager._gravar({"seed": 3}, _save, _backup))

	assert_eq(_ler(_save), antes[0])
	assert_eq(int(_reabrir_e_carregar()["seed"]), 2, "o principal válido sobrevive")
	assert_true(_orfaos().is_empty())


func test_copia_que_diz_ok_mas_gera_backup_invalido_e_detectada() -> void:
	var antes := _ambos_validos()
	SaveManager.copiar_para_teste = func(_o: String, d: String) -> Error:
		_escrever(d, "{lixo")
		return OK  ## mente

	assert_false(SaveManager._gravar({"seed": 3}, _save, _backup), "a conferência pega")

	assert_eq(_ler(_save), antes[0], "principal não foi trocado")
	assert_true(_orfaos().is_empty())


func test_copia_que_diz_ok_mas_gera_backup_diferente_do_principal_e_detectada() -> void:
	var antes := _ambos_validos()
	SaveManager.copiar_para_teste = func(_o: String, d: String) -> Error:
		_escrever(d, JSON.stringify({"seed": 424242, "schema_version": 1}))  ## válido, mas outro
		return OK

	assert_false(SaveManager._gravar({"seed": 3}, _save, _backup))

	assert_eq(_ler(_save), antes[0])
	assert_true(_orfaos().is_empty())


func test_falha_na_troca_com_ambos_validos_mantem_principal_e_backup_recuperaveis() -> void:
	var antes := _ambos_validos()
	SaveManager.renomear_para_teste = _falha_na_troca

	assert_false(SaveManager._gravar({"seed": 3}, _save, _backup))

	assert_eq(_ler(_save), antes[0], "principal intacto")
	assert_true(SaveManager._e_valido(_backup), "backup é cópia válida do principal")
	assert_eq(int(_reabrir_e_carregar()["seed"]), 2)
	assert_true(_orfaos().is_empty())


func test_troca_destrutiva_que_apaga_o_principal_recupera_pelo_backup() -> void:
	_ambos_validos()
	SaveManager.renomear_para_teste = func(_o: String, d: String) -> Error:
		DirAccess.remove_absolute(d)  ## pior caso: o principal some e a troca falha
		return ERR_FILE_CANT_WRITE

	assert_false(SaveManager._gravar({"seed": 3}, _save, _backup))

	assert_false(FileAccess.file_exists(_save))
	assert_eq(int(_reabrir_e_carregar()["seed"]), 2, "o backup guarda a cópia do principal")
	assert_true(_orfaos().is_empty())


func test_troca_que_diz_ok_mas_entrega_principal_invalido_e_declarada_falha() -> void:
	_ambos_validos()
	SaveManager.renomear_para_teste = func(o: String, d: String) -> Error:
		DirAccess.remove_absolute(o)
		_escrever(d, "{principal estragado")  ## troca "ok" que corrompe
		return OK

	assert_false(SaveManager._gravar({"seed": 3}, _save, _backup), "conferência final pega")

	assert_eq(int(_reabrir_e_carregar()["seed"]), 2, "backup recupera")


## --- depois da falha ---


func test_salvamento_bem_sucedido_depois_de_cada_falha_sem_orfaos() -> void:
	var injecoes: Array[Callable] = [
		_falha_na_troca,
		func(_o: String, _d: String) -> Error: return ERR_FILE_CANT_WRITE,
	]
	for i in range(injecoes.size()):
		_apagar_recursivo(_raiz + "/saves")
		_ambos_validos()
		SaveManager.renomear_para_teste = injecoes[i]
		assert_false(SaveManager._gravar({"seed": 50}, _save, _backup))
		SaveManager.renomear_para_teste = Callable()

		assert_true(SaveManager._gravar({"seed": 60 + i}, _save, _backup), "tentativa %d" % i)

		assert_eq(int(_reabrir_e_carregar()["seed"]), 60 + i)
		assert_true(_orfaos().is_empty())


func test_sucesso_normal_nao_deixa_temporario_e_o_backup_vira_o_estado_anterior() -> void:
	var antes := _ambos_validos()

	assert_true(SaveManager._gravar({"seed": 3}, _save, _backup))

	assert_eq(_ler(_backup), antes[0], "backup = principal anterior, idêntico")
	assert_eq(int(JSON.parse_string(_ler(_save))["seed"]), 3)
	assert_true(_orfaos().is_empty())


func test_principal_invalido_sem_backup_grava_sem_criar_backup() -> void:
	_escrever(_save, '{"hotbar": []}')

	assert_true(SaveManager._gravar({"seed": 4}, _save, _backup))

	assert_false(FileAccess.file_exists(_backup))
	assert_true(_orfaos().is_empty())


func test_pontos_de_injecao_ficam_vazios_por_padrao() -> void:
	var novo: Node = SaveManagerScript.new()

	assert_false(novo.renomear_para_teste.is_valid())
	assert_false(novo.copiar_para_teste.is_valid())
	novo.free()
