extends GutTest
## ADR-039: a seed e os demais campos declarados `int` no GameState têm de ser
## números de valor inteiro. O JSON devolve todo número como float, então
## 3356247210.0 (seed real) vale e 123.45 não.

const V := 1

var _raiz: String = ""
var _save: String = ""
var _backup: String = ""


func before_each() -> void:
	_raiz = "user://_teste_inteiros_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(_raiz)
	_save = _raiz + "/saves/slot.json"
	_backup = _raiz + "/saves/slot.bak.json"
	SaveManager.renomear_para_teste = Callable()


func after_each() -> void:
	SaveManager.renomear_para_teste = Callable()
	_apagar(_raiz)


func _apagar(caminho: String) -> void:
	var dir := DirAccess.open(caminho)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_apagar(caminho + "/" + sub)
	for arq: String in dir.get_files():
		DirAccess.remove_absolute(caminho + "/" + arq)
	DirAccess.remove_absolute(caminho)


func _ler(caminho: String) -> String:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	return "" if arquivo == null else arquivo.get_as_text()


func _escrever(caminho: String, texto: String) -> void:
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	FileAccess.open(caminho, FileAccess.WRITE).store_string(texto)


func _r(dados: Variant) -> ValidadorSave.Resultado:
	return ValidadorSave.avaliar(dados, V)


func test_seed_inteira_e_valida_inclusive_a_grande_que_o_jogo_gera() -> void:
	assert_eq(_r({"seed": 12345}), ValidadorSave.Resultado.VALIDO)
	assert_eq(_r({"seed": 0}), ValidadorSave.Resultado.VALIDO)
	assert_eq(_r({"seed": -7}), ValidadorSave.Resultado.VALIDO)
	assert_eq(_r({"seed": 4294967295}), ValidadorSave.Resultado.VALIDO, "maior randi()")


func test_seed_depois_do_json_vira_float_inteiro_e_continua_valida() -> void:
	var lido: Dictionary = JSON.parse_string(JSON.stringify({"seed": 3356247210}))

	assert_eq(typeof(lido["seed"]), TYPE_FLOAT, "pré-condição: o JSON devolve float")
	assert_eq(_r(lido), ValidadorSave.Resultado.VALIDO)


func test_seed_decimal_e_invalida() -> void:
	for ruim: float in [123.45, 0.5, -1.25, 1.0000001]:
		assert_eq(
			_r({"seed": ruim}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA, "seed=%s" % str(ruim)
		)


func test_seed_string_booleano_nulo_lista_e_objeto_sao_invalidos() -> void:
	for ruim: Variant in ["123", "abc", "", true, false, null, [1], {"a": 1}]:
		assert_eq(
			_r({"seed": ruim}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA, "seed=%s" % str(ruim)
		)


func test_seed_ausente_e_estruturas_invalidas_continuam_rejeitadas() -> void:
	assert_eq(_r({"hotbar": []}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)
	assert_eq(_r({}), ValidadorSave.Resultado.VAZIO)
	assert_eq(_r([123]), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)
	assert_eq(_r(123), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)


func test_seed_infinita_ou_fora_do_int64_e_invalida() -> void:
	assert_eq(_r({"seed": INF}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)
	assert_eq(_r({"seed": -INF}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)
	assert_eq(_r({"seed": NAN}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)
	assert_eq(_r({"seed": 1e300}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)


func test_campos_int_do_game_state_exigem_valor_inteiro() -> void:
	for chave: String in [
		"hotbar_selecionado", "vida_atual", "fome_atual", "energia_atual", "progresso_quest_atual"
	]:
		assert_eq(_r({"seed": 1, chave: 2.0}), ValidadorSave.Resultado.VALIDO, chave + " = 2.0")
		assert_eq(_r({"seed": 1, chave: 2}), ValidadorSave.Resultado.VALIDO, chave + " = 2")
		assert_eq(
			_r({"seed": 1, chave: 2.5}),
			ValidadorSave.Resultado.ESTRUTURA_INVALIDA,
			chave + " = 2.5"
		)
		assert_eq(
			_r({"seed": 1, chave: true}),
			ValidadorSave.Resultado.ESTRUTURA_INVALIDA,
			chave + " bool"
		)


func test_tempos_em_segundos_aceitam_fracao_porque_sao_float_no_game_state() -> void:
	assert_eq(
		_r({"seed": 1, "tempo_de_jogo_seg": 12.75, "ciclo_dia_noite_seg": 301.125}),
		ValidadorSave.Resultado.VALIDO
	)
	assert_eq(
		_r({"seed": 1, "tempo_de_jogo_seg": "12"}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA
	)


func test_schema_version_continua_exigindo_inteiro() -> void:
	assert_eq(_r({"seed": 1, "schema_version": 1.0}), ValidadorSave.Resultado.VALIDO)
	assert_eq(_r({"seed": 1, "schema_version": 1.5}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)
	assert_eq(_r({"seed": 1, "schema_version": true}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)


func test_arquivo_com_seed_decimal_e_classificado_como_estrutura_invalida() -> void:
	_escrever(_save, '{"seed": 123.45, "schema_version": 1}')

	assert_eq(SaveManager._avaliar_arquivo(_save), SaveManager.EstadoArquivo.ESTRUTURA_INVALIDA)


func test_gravar_recusa_seed_decimal_sem_tocar_em_nada() -> void:
	assert_true(SaveManager._gravar({"seed": 1}, _save, _backup))
	var antes := _ler(_save)

	assert_false(SaveManager._gravar({"seed": 99.5}, _save, _backup))
	assert_false(SaveManager._gravar({"seed": "99"}, _save, _backup))
	assert_false(SaveManager._gravar({"seed": true}, _save, _backup))

	assert_eq(_ler(_save), antes)
	assert_false(FileAccess.file_exists(_backup))
	assert_false(FileAccess.file_exists(_save + ".tmp"))


func _principal_com_seed_invalida_e_backup_valido() -> String:
	SaveManager._gravar({"seed": 1}, _save, _backup)
	SaveManager._gravar({"seed": 2}, _save, _backup)  ## backup = seed 1
	_escrever(_save, '{"seed": 123.45, "schema_version": 1}')
	return _ler(_backup)


func test_principal_com_seed_decimal_recupera_pelo_backup() -> void:
	_principal_com_seed_invalida_e_backup_valido()

	assert_eq(int(SaveManager._carregar_de(_save, _backup)["seed"]), 1)


func test_salvar_depois_nao_sobrescreve_nem_danifica_o_backup_valido() -> void:
	var backup_antes := _principal_com_seed_invalida_e_backup_valido()
	var recuperado := SaveManager._carregar_de(_save, _backup)
	recuperado["seed"] = 10

	assert_true(SaveManager._gravar(recuperado, _save, _backup))

	assert_eq(_ler(_backup), backup_antes, "backup byte a byte igual")
	assert_eq(int(JSON.parse_string(_ler(_save))["seed"]), 10)


func test_falha_na_troca_com_principal_de_seed_invalida_preserva_o_backup_e_recupera() -> void:
	var backup_antes := _principal_com_seed_invalida_e_backup_valido()
	var principal_antes := _ler(_save)
	SaveManager.renomear_para_teste = func(_o: String, _d: String) -> Error:
		return ERR_FILE_CANT_WRITE

	assert_false(SaveManager._gravar({"seed": 55}, _save, _backup))

	assert_eq(_ler(_backup), backup_antes)
	assert_eq(_ler(_save), principal_antes, "o principal inválido não foi trocado")
	assert_eq(int(SaveManager._carregar_de(_save, _backup)["seed"]), 1)
	assert_false(FileAccess.file_exists(_save + ".tmp"))
