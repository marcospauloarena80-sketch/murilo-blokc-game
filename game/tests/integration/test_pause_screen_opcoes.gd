extends GutTest
## Frente 6D — botão Opções na pausa abre a OptionsScreen por cima: entra na
## pilha de telas e, ao fechar, volta pra pausa (não pro jogo). Esc com as
## opções abertas fecha só as opções.

const PauseScreenScene := preload("res://ui/pause_screen/pause_screen.tscn")
const CAMINHO_TESTE: String = "user://opcoes_teste.cfg"

var _sensibilidade_antes: float = 0.0
var _musica_antes: float = 0.0
var _sfx_antes: float = 0.0


func before_each() -> void:
	## Mesmo cuidado do test_touch_controls: uma troca de cena pendente de
	## testes anteriores deixaria outro PauseScreen recebendo o Esc.
	await get_tree().process_frame
	if get_tree().current_scene != null:
		get_tree().unload_current_scene()
	_sensibilidade_antes = Opcoes.sensibilidade
	_musica_antes = Opcoes.volume_musica_db
	_sfx_antes = Opcoes.volume_sfx_db
	GameState.mudar_estado(GameState.State.PLAYING)


func after_each() -> void:
	Input.action_release("pausar")
	Opcoes.sensibilidade = _sensibilidade_antes
	Opcoes.volume_musica_db = _musica_antes
	Opcoes.volume_sfx_db = _sfx_antes
	if FileAccess.file_exists(CAMINHO_TESTE):
		DirAccess.remove_absolute(CAMINHO_TESTE)
	GameState.mudar_estado(GameState.State.PLAYING)


func _pausa_com_opcoes() -> PauseScreen:
	var tela: PauseScreen = PauseScreenScene.instantiate()
	add_child_autofree(tela)
	var opcoes: OptionsScreen = tela.get_node("OptionsScreen")
	opcoes.caminho_cfg = CAMINHO_TESTE
	return tela


func test_botao_opcoes_abre_a_tela_por_cima_da_pausa() -> void:
	var tela := _pausa_com_opcoes()
	var opcoes: OptionsScreen = tela.get_node("OptionsScreen")
	tela._abrir()

	tela._botao_opcoes.pressed.emit()

	assert_true(opcoes.visible, "Opções deveria abrir")
	assert_true(GameState.telas_abertas.has("opcoes"))
	assert_eq(GameState.current_state, GameState.State.PAUSED)


func test_fechar_opcoes_volta_pra_pausa_e_nao_pro_jogo() -> void:
	var tela := _pausa_com_opcoes()
	var opcoes: OptionsScreen = tela.get_node("OptionsScreen")
	tela._abrir()
	tela._botao_opcoes.pressed.emit()

	opcoes.fechar()

	assert_false(opcoes.visible)
	assert_true(tela.visible, "a pausa continua na tela")
	assert_eq(GameState.current_state, GameState.State.PAUSED)

	tela._fechar()
	assert_eq(GameState.current_state, GameState.State.PLAYING)


func test_esc_com_opcoes_abertas_fecha_so_as_opcoes() -> void:
	var tela := _pausa_com_opcoes()
	var opcoes: OptionsScreen = tela.get_node("OptionsScreen")
	tela._abrir()
	tela._botao_opcoes.pressed.emit()

	var evento := InputEventAction.new()
	evento.action = "pausar"
	evento.pressed = true
	Input.parse_input_event(evento)
	await get_tree().process_frame
	await get_tree().process_frame

	assert_false(opcoes.visible, "Esc fecha as opções")
	assert_true(tela.visible, "a pausa continua aberta")
	assert_eq(GameState.current_state, GameState.State.PAUSED)
