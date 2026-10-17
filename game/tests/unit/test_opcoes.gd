extends GutTest
## Ver docs/superpowers/plans/2026-10-17-ciclos-5-a-9.md Frente 6D — opções do
## jogador (sensibilidade do mouse e volumes em dB) persistidas em
## user://opcoes.cfg via ConfigFile. Os testes usam um caminho próprio pra não
## mexer no arquivo real de quem roda a suíte.

const CAMINHO_TESTE: String = "user://opcoes_teste.cfg"

var _sensibilidade_antes: float = 0.0
var _musica_antes: float = 0.0
var _sfx_antes: float = 0.0
var _bus_musica_antes: float = 0.0
var _bus_sfx_antes: float = 0.0


func before_each() -> void:
	_sensibilidade_antes = Opcoes.sensibilidade
	_musica_antes = Opcoes.volume_musica_db
	_sfx_antes = Opcoes.volume_sfx_db
	_bus_musica_antes = _volume_do_bus("Música")
	_bus_sfx_antes = _volume_do_bus("SFX")
	_remover_se_existir(CAMINHO_TESTE)


func after_each() -> void:
	Opcoes.sensibilidade = _sensibilidade_antes
	Opcoes.volume_musica_db = _musica_antes
	Opcoes.volume_sfx_db = _sfx_antes
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Música"), _bus_musica_antes)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _bus_sfx_antes)
	_remover_se_existir(CAMINHO_TESTE)


func _volume_do_bus(nome: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(nome))


func _remover_se_existir(caminho: String) -> void:
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)


func test_valores_padrao() -> void:
	assert_almost_eq(Opcoes.SENSIBILIDADE_PADRAO, 0.003, 0.000001)
	assert_almost_eq(Opcoes.VOLUME_PADRAO_DB, 0.0, 0.000001)


func test_carregar_sem_arquivo_volta_aos_padroes() -> void:
	Opcoes.sensibilidade = 0.007
	Opcoes.volume_musica_db = -20.0
	Opcoes.volume_sfx_db = -10.0

	Opcoes.carregar(CAMINHO_TESTE)

	assert_almost_eq(Opcoes.sensibilidade, 0.003, 0.000001)
	assert_almost_eq(Opcoes.volume_musica_db, 0.0, 0.000001)
	assert_almost_eq(Opcoes.volume_sfx_db, 0.0, 0.000001)


func test_salvar_e_carregar_mantem_os_valores() -> void:
	Opcoes.sensibilidade = 0.0055
	Opcoes.volume_musica_db = -18.0
	Opcoes.volume_sfx_db = -6.0

	Opcoes.salvar(CAMINHO_TESTE)
	assert_true(FileAccess.file_exists(CAMINHO_TESTE), "salvar deveria criar o arquivo")

	Opcoes.sensibilidade = 0.003
	Opcoes.volume_musica_db = 0.0
	Opcoes.volume_sfx_db = 0.0
	Opcoes.carregar(CAMINHO_TESTE)

	assert_almost_eq(Opcoes.sensibilidade, 0.0055, 0.000001)
	assert_almost_eq(Opcoes.volume_musica_db, -18.0, 0.000001)
	assert_almost_eq(Opcoes.volume_sfx_db, -6.0, 0.000001)


func test_arquivo_incompleto_completa_com_padroes() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(Opcoes.SECAO, "volume_musica_db", -9.0)
	cfg.save(CAMINHO_TESTE)
	Opcoes.sensibilidade = 0.008

	Opcoes.carregar(CAMINHO_TESTE)

	assert_almost_eq(Opcoes.volume_musica_db, -9.0, 0.000001)
	assert_almost_eq(Opcoes.sensibilidade, 0.003, 0.000001, "chave ausente usa o padrão")


func test_aplicar_muda_o_volume_dos_buses() -> void:
	Opcoes.volume_musica_db = -12.0
	Opcoes.volume_sfx_db = -3.0

	Opcoes.aplicar()

	assert_almost_eq(_volume_do_bus("Música"), -12.0, 0.01)
	assert_almost_eq(_volume_do_bus("SFX"), -3.0, 0.01)
