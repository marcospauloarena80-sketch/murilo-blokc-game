class_name PauseScreen
extends CanvasLayer
## Pausa (tecla "pausar"): Continuar/Salvar/Sair. Reaproveita GameState.PAUSED
## (mesmo estado usado pela tela de inventário). Ver docs/04-ROADMAP.md F5.

var _aberto: bool = false

@onready var _botao_continuar: Button = $Control/Painel/Margem/VBox/BotaoContinuar
@onready var _botao_salvar: Button = $Control/Painel/Margem/VBox/BotaoSalvar
@onready var _botao_sair: Button = $Control/Painel/Margem/VBox/BotaoSair
@onready var _rotulo_status: Label = $Control/Painel/Margem/VBox/RotuloStatus


func _ready() -> void:
	visible = false
	_botao_continuar.pressed.connect(_fechar)
	_botao_salvar.pressed.connect(_ao_salvar)
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
	GameState.mudar_estado(GameState.State.PAUSED)


func _fechar() -> void:
	_aberto = false
	visible = false
	GameState.mudar_estado(GameState.State.PLAYING)


func _ao_salvar() -> void:
	get_tree().current_scene.call("salvar_jogo")
	_rotulo_status.text = "Jogo salvo!"


func _ao_sair() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
