class_name OptionsScreen
extends CanvasLayer
## Tela de opções (Frente 6D): sensibilidade do mouse e volumes de Música/SFX.
## Cada slider grava em Opcoes, aplica nos buses e salva na hora. Aberta de
## dentro do jogo (pausa) entra na pilha de telas do GameState; no menu só
## aparece e some, sem mexer no estado.

const ID_TELA: String = "opcoes"

## Arquivo onde as opções são gravadas; os testes apontam pra um arquivo próprio.
var caminho_cfg: String = Opcoes.CAMINHO_PADRAO

var _aberta: bool = false
var _dentro_do_jogo: bool = false

@onready var _slider_sensibilidade: HSlider = $Control/Painel/Margem/VBox/SliderSensibilidade
@onready var _slider_musica: HSlider = $Control/Painel/Margem/VBox/SliderMusica
@onready var _slider_sfx: HSlider = $Control/Painel/Margem/VBox/SliderSFX
@onready var _botao_voltar: Button = $Control/Painel/Margem/VBox/BotaoVoltar


func _ready() -> void:
	visible = false
	_slider_sensibilidade.value_changed.connect(_ao_mudar_sensibilidade)
	_slider_musica.value_changed.connect(_ao_mudar_musica)
	_slider_sfx.value_changed.connect(_ao_mudar_sfx)
	_botao_voltar.pressed.connect(fechar)


func _unhandled_input(event: InputEvent) -> void:
	## Esc fecha só esta tela: marca o evento como tratado pra pausa (que vem
	## depois na ordem de input) não fechar junto.
	if _aberta and event.is_action_pressed("pausar"):
		fechar()
		get_viewport().set_input_as_handled()


func abrir() -> void:
	_aberta = true
	_dentro_do_jogo = GameState.current_state != GameState.State.MENU
	## Refletir o valor atual não é "mudar": sem sinal, não grava nada.
	_slider_sensibilidade.set_value_no_signal(Opcoes.sensibilidade)
	_slider_musica.set_value_no_signal(Opcoes.volume_musica_db)
	_slider_sfx.set_value_no_signal(Opcoes.volume_sfx_db)
	visible = true
	if _dentro_do_jogo:
		GameState.abrir_tela(ID_TELA)


func fechar() -> void:
	if not _aberta:
		return
	_aberta = false
	visible = false
	if _dentro_do_jogo:
		GameState.fechar_tela(ID_TELA)


func _ao_mudar_sensibilidade(valor: float) -> void:
	Opcoes.sensibilidade = valor
	_aplicar_e_salvar()


func _ao_mudar_musica(valor: float) -> void:
	Opcoes.volume_musica_db = valor
	_aplicar_e_salvar()


func _ao_mudar_sfx(valor: float) -> void:
	Opcoes.volume_sfx_db = valor
	_aplicar_e_salvar()


func _aplicar_e_salvar() -> void:
	Opcoes.aplicar()
	Opcoes.salvar(caminho_cfg)
