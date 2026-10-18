extends GutTest
## ADR-036: gravação do save com cada falha tratada e conferência por releitura.
## Usa uma pasta própria em user://, nunca o save real (SAVE_PATH/BACKUP_PATH).

var _raiz: String = ""
var _save: String = ""
var _backup: String = ""


func before_each() -> void:
	_raiz = "user://_teste_save_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_raiz)
	_save = _raiz + "/saves/slot.json"
	_backup = _raiz + "/saves/slot.bak.json"


func after_each() -> void:
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


func test_gravacao_boa_devolve_true_cria_a_pasta_e_nao_deixa_temporario() -> void:
	assert_true(SaveManager._gravar({"seed": 7}, _save, _backup))

	var dados: Dictionary = JSON.parse_string(_ler(_save))
	assert_eq(int(dados["seed"]), 7)
	assert_eq(int(dados["schema_version"]), SaveManager.SCHEMA_VERSION)
	assert_false(FileAccess.file_exists(_save + ".tmp"))
	assert_false(FileAccess.file_exists(_backup), "primeira gravação não tem o que copiar")


func test_segunda_gravacao_guarda_a_primeira_no_backup() -> void:
	SaveManager._gravar({"seed": 1}, _save, _backup)

	assert_true(SaveManager._gravar({"seed": 2}, _save, _backup))

	assert_eq(int(JSON.parse_string(_ler(_save))["seed"]), 2)
	assert_eq(int(JSON.parse_string(_ler(_backup))["seed"]), 1)


func test_pasta_de_saves_impossivel_de_criar_falha_sem_declarar_sucesso() -> void:
	_escrever(_raiz + "/arquivo_comum", "nao sou pasta")
	var caminho := _raiz + "/arquivo_comum/saves/slot.json"

	assert_false(SaveManager._gravar({"seed": 1}, caminho, caminho + ".bak"))

	assert_false(FileAccess.file_exists(caminho))


func test_falha_ao_abrir_o_temporario_preserva_o_save_anterior() -> void:
	SaveManager._gravar({"seed": 1}, _save, _backup)
	var antes := _ler(_save)
	DirAccess.make_dir_recursive_absolute(_save + ".tmp")  ## ocupa o nome do temporário

	assert_false(SaveManager._gravar({"seed": 2}, _save, _backup))

	assert_eq(_ler(_save), antes, "o save anterior continua intacto")
	assert_eq(int(SaveManager._carregar_de(_save, _backup)["seed"]), 1)


func test_falha_na_copia_do_backup_nao_troca_o_save_e_limpa_o_temporario() -> void:
	SaveManager._gravar({"seed": 1}, _save, _backup)
	var antes := _ler(_save)
	DirAccess.make_dir_recursive_absolute(_backup)  ## backup é uma pasta: cópia falha

	assert_false(SaveManager._gravar({"seed": 2}, _save, _backup))

	assert_eq(_ler(_save), antes)
	assert_false(FileAccess.file_exists(_save + ".tmp"), "nenhum temporário sobra")


func test_conferir_recusa_arquivo_truncado_vazio_ou_diferente() -> void:
	var esperado := JSON.stringify({"seed": 1, "lista": [1, 2, 3]})
	var caminho := _raiz + "/c.json"

	_escrever(caminho, esperado.substr(0, esperado.length() - 3))
	assert_false(SaveManager._conferir(caminho, esperado), "truncado")
	_escrever(caminho, "")
	assert_false(SaveManager._conferir(caminho, esperado), "vazio")
	_escrever(caminho, JSON.stringify({"seed": 2}))
	assert_false(SaveManager._conferir(caminho, esperado), "diferente")
	assert_false(SaveManager._conferir(_raiz + "/nao_existe.json", esperado), "ausente")
	_escrever(caminho, esperado)
	assert_true(SaveManager._conferir(caminho, esperado))


func test_conferir_recusa_texto_igual_que_nao_e_objeto_json() -> void:
	var caminho := _raiz + "/c.json"
	_escrever(caminho, "[1, 2, 3]")

	assert_false(SaveManager._conferir(caminho, "[1, 2, 3]"))


func test_recuperacao_pelo_backup_quando_o_principal_esta_corrompido() -> void:
	SaveManager._gravar({"seed": 1}, _save, _backup)
	SaveManager._gravar({"seed": 2}, _save, _backup)
	_escrever(_save, "{corrompido")  ## queda de energia no meio de uma escrita

	var dados := SaveManager._carregar_de(_save, _backup)

	assert_eq(int(dados["seed"]), 1, "volta ao save anterior, que está no backup")


func test_recuperacao_pelo_backup_quando_o_principal_sumiu() -> void:
	SaveManager._gravar({"seed": 1}, _save, _backup)
	SaveManager._gravar({"seed": 2}, _save, _backup)
	DirAccess.remove_absolute(_save)

	assert_eq(int(SaveManager._carregar_de(_save, _backup)["seed"]), 1)


func test_sem_principal_nem_backup_carregar_devolve_vazio() -> void:
	assert_eq(SaveManager._carregar_de(_save, _backup), {})


func test_temporario_esquecido_de_uma_queda_nao_atrapalha_carregar_nem_a_proxima_gravacao() -> void:
	SaveManager._gravar({"seed": 1}, _save, _backup)
	_escrever(_save + ".tmp", "{lixo pela metade")

	assert_eq(int(SaveManager._carregar_de(_save, _backup)["seed"]), 1)
	assert_true(SaveManager._gravar({"seed": 3}, _save, _backup))
	assert_eq(int(JSON.parse_string(_ler(_save))["seed"]), 3)
	assert_false(FileAccess.file_exists(_save + ".tmp"))
