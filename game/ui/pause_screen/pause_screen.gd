class_name PauseScreen
extends CanvasLayer
## Pausa (tecla "pausar"): Continuar/Salvar/Opções/Sair. Reaproveita GameState.PAUSED
## (mesmo estado usado pela tela de inventário). Ver docs/04-ROADMAP.md F5.
## Opções abre a OptionsScreen por cima (entra na pilha de telas, Frente 6D).

const DURACAO_CONFIRMACAO_SEG: float = 1.5
const COR_SALVO: Color = Color(0.6, 1.0, 0.6)
const COR_ERRO: Color = Color(1.0, 0.45, 0.45)

## Persiste o jogo (devolve true se gravou). Vazio = `salvar_jogo` da cena atual;
## os testes injetam o próprio.
var salvador: Callable = Callable()

var _aberto: bool = false

@onready var _botao_continuar: Button = $Control/Painel/Margem/VBox/BotaoContinuar
@onready var _botao_salvar: Button = $Control/Painel/Margem/VBox/BotaoSalvar
@onready var _botao_opcoes: Button = $Control/Painel/Margem/VBox/BotaoOpcoes
@onready var _botao_sair: Button = $Control/Painel/Margem/VBox/BotaoSair
@onready var _rotulo_status: Label = $Control/Painel/Margem/VBox/RotuloStatus
@onready var _opcoes: OptionsScreen = $OptionsScreen


func _ready() -> void:
	visible = false
	_botao_continuar.pressed.connect(_fechar)
	_botao_salvar.pressed.connect(_ao_salvar)
	_botao_opcoes.pressed.connect(_opcoes.abrir)
	_botao_sair.pressed.connect(_ao_sair)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausar"):
		if _aberto:
			_fechar()
		elif GameState.current_state == GameState.State.PLAYING:
			_abrir()


func _abrir() -> void:
	_aberto = true
	visible = true
	_rotulo_status.text = ""
	GameState.abrir_tela("pausa")


func _fechar() -> void:
	_aberto = false
	visible = false
	GameState.fechar_tela("pausa")


func _ao_salvar() -> void:
	if _salvar():
		_rotulo_status.text = "Jogo salvo!"
		_rotulo_status.add_theme_color_override("font_color", COR_SALVO)
		_botao_salvar.text = "Salvo!"
	else:
		_mostrar_falha("Não foi possível salvar o jogo!")
		_botao_salvar.text = "Falhou!"
	## Callable ligado a este nó: se a tela for liberada antes, a conexão cai junto.
	get_tree().create_timer(DURACAO_CONFIRMACAO_SEG).timeout.connect(_restaurar_botao_salvar)


func _salvar() -> bool:
	if salvador.is_valid():
		return bool(salvador.call())
	return SaveManager.salvar_pela_cena(get_tree().current_scene)


func _mostrar_falha(texto: String) -> void:
	_rotulo_status.text = texto
	_rotulo_status.add_theme_color_override("font_color", COR_ERRO)


func _restaurar_botao_salvar() -> void:
	_botao_salvar.text = "Salvar"


func _ao_sair() -> void:
	## Salva antes de voltar pro menu (mesma rotina do botão Salvar). Se a gravação
	## falhar, fica na pausa com o erro à vista em vez de perder o progresso em
	## silêncio. Nos testes a cena atual pode não ter salvar_jogo: aí só troca de cena.
	var cena_atual: Node = get_tree().current_scene
	var pode_salvar: bool = (
		salvador.is_valid() or (cena_atual != null and cena_atual.has_method("salvar_jogo"))
	)
	if pode_salvar and not _salvar():
		_mostrar_falha("Não foi possível salvar. Você continua no jogo.")
		return
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
