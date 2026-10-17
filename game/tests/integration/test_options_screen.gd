extends GutTest
## Frente 6D — tela de opções: cada slider mexe em Opcoes, aplica no bus e
## salva; aberta de dentro do jogo entra na pilha de telas do GameState, no
## menu não mexe no estado.

const OptionsScreenScene := preload("res://ui/options_screen/options_screen.tscn")
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
	GameState.mudar_estado(GameState.State.MENU)


func after_each() -> void:
	Opcoes.sensibilidade = _sensibilidade_antes
	Opcoes.volume_musica_db = _musica_antes
	Opcoes.volume_sfx_db = _sfx_antes
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Música"), _bus_musica_antes)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _bus_sfx_antes)
	_remover_se_existir(CAMINHO_TESTE)
	GameState.mudar_estado(GameState.State.MENU)


func _volume_do_bus(nome: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(nome))


func _remover_se_existir(caminho: String) -> void:
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)


func _instanciar() -> OptionsScreen:
	var tela: OptionsScreen = OptionsScreenScene.instantiate()
	tela.caminho_cfg = CAMINHO_TESTE
	add_child_autofree(tela)
	return tela


func test_comeca_invisivel_e_abrir_mostra() -> void:
	var tela := _instanciar()
	assert_false(tela.visible)

	tela.abrir()

	assert_true(tela.visible)


func test_sliders_tem_as_faixas_da_especificacao() -> void:
	var tela := _instanciar()
	assert_almost_eq(tela._slider_sensibilidade.min_value, 0.001, 0.000001)
	assert_almost_eq(tela._slider_sensibilidade.max_value, 0.008, 0.000001)
	assert_almost_eq(tela._slider_sensibilidade.step, 0.0005, 0.000001)
	assert_almost_eq(tela._slider_musica.min_value, -40.0, 0.000001)
	assert_almost_eq(tela._slider_musica.max_value, 0.0, 0.000001)
	assert_almost_eq(tela._slider_sfx.min_value, -40.0, 0.000001)
	assert_almost_eq(tela._slider_sfx.max_value, 0.0, 0.000001)


func test_abrir_reflete_os_valores_atuais_sem_salvar() -> void:
	Opcoes.sensibilidade = 0.005
	Opcoes.volume_musica_db = -30.0
	Opcoes.volume_sfx_db = -15.0
	var tela := _instanciar()

	tela.abrir()

	assert_almost_eq(tela._slider_sensibilidade.value, 0.005, 0.000001)
	assert_almost_eq(tela._slider_musica.value, -30.0, 0.000001)
	assert_almost_eq(tela._slider_sfx.value, -15.0, 0.000001)
	assert_false(FileAccess.file_exists(CAMINHO_TESTE), "só abrir não grava nada")


func test_slider_de_musica_altera_opcoes_e_o_bus() -> void:
	var tela := _instanciar()
	tela.abrir()

	tela._slider_musica.value = -20.0

	assert_almost_eq(Opcoes.volume_musica_db, -20.0, 0.01)
	assert_almost_eq(_volume_do_bus("Música"), -20.0, 0.01)


func test_slider_de_sfx_altera_opcoes_e_o_bus() -> void:
	var tela := _instanciar()
	tela.abrir()

	tela._slider_sfx.value = -8.0

	assert_almost_eq(Opcoes.volume_sfx_db, -8.0, 0.01)
	assert_almost_eq(_volume_do_bus("SFX"), -8.0, 0.01)


func test_slider_de_sensibilidade_altera_opcoes() -> void:
	var tela := _instanciar()
	tela.abrir()

	tela._slider_sensibilidade.value = 0.006

	assert_almost_eq(Opcoes.sensibilidade, 0.006, 0.000001)


func test_mudar_um_slider_salva_no_arquivo() -> void:
	var tela := _instanciar()
	tela.abrir()

	tela._slider_musica.value = -20.0

	assert_true(FileAccess.file_exists(CAMINHO_TESTE), "mudar o slider deveria salvar")
	Opcoes.volume_musica_db = 0.0
	Opcoes.carregar(CAMINHO_TESTE)
	assert_almost_eq(Opcoes.volume_musica_db, -20.0, 0.01)


func test_botao_voltar_fecha_a_tela() -> void:
	var tela := _instanciar()
	tela.abrir()

	tela._botao_voltar.pressed.emit()

	assert_false(tela.visible)


func test_no_menu_nao_mexe_na_pilha_de_telas() -> void:
	GameState.mudar_estado(GameState.State.MENU)
	var tela := _instanciar()

	tela.abrir()
	assert_eq(GameState.current_state, GameState.State.MENU)
	assert_true(GameState.telas_abertas.is_empty())

	tela.fechar()
	assert_eq(GameState.current_state, GameState.State.MENU)


func test_de_dentro_do_jogo_entra_na_pilha_e_volta_pra_pausa() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)
	GameState.abrir_tela("pausa")
	var tela := _instanciar()

	tela.abrir()
	assert_true(GameState.telas_abertas.has("opcoes"))
	assert_eq(GameState.current_state, GameState.State.PAUSED)

	tela.fechar()
	assert_false(GameState.telas_abertas.has("opcoes"))
	assert_eq(GameState.current_state, GameState.State.PAUSED, "a pausa continua aberta por baixo")

	GameState.fechar_tela("pausa")
	assert_eq(GameState.current_state, GameState.State.PLAYING)
