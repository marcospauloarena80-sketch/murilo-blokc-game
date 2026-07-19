class_name CreditsScreen
extends CanvasLayer
## Tela final ao vencer o Guardião do Coração Dourado (F10). Ver docs/01-GDD.md
## §13 e docs/07-DECISOES.md ADR-023 — fecha o critério "campanha completável
## do zero ao desafio final" do roadmap F10, sem antecipar o balanceamento/
## polish geral que é da F12.

@onready var _label_texto: Label = $Control/Painel/Margem/VBox/LabelTexto
@onready var _botao_voltar: Button = $Control/Painel/Margem/VBox/BotaoVoltar


func _ready() -> void:
	visible = false
	_botao_voltar.pressed.connect(_ao_voltar)
	EventBus.game_completed.connect(_abrir)


func _abrir() -> void:
	visible = true
	GameState.mudar_estado(GameState.State.PAUSED)
	_label_texto.text = (
		"Você derrotou o Guardião do Coração Dourado e completou o Vale Dourado!\n\n"
		+ "Obrigado por jogar."
	)


func _ao_voltar() -> void:
	visible = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
