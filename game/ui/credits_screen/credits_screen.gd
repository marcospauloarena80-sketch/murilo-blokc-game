class_name CreditsScreen
extends CanvasLayer
## Tela final ao vencer o Guardião do Coração Dourado (F10, texto fechado na
## F12/ADR-025). Ver docs/01-GDD.md §13 e docs/07-DECISOES.md ADR-023 — fecha
## o critério "campanha completável do zero ao desafio final" do roadmap F10.
## Créditos são curtos porque não há asset externo no jogo: modelos são
## primitivas da própria Godot (ADR-015) e o áudio é sintetizado em código
## (ADR-024) — nada de pack CC0 pra atribuir.

const TEXTO_VITORIA := "Você derrotou o Guardião do Coração Dourado e completou o Vale Dourado!"
const TEXTO_CREDITOS := (
	"Murilo Blocks Game\n"
	+ "Feito com Godot Engine (godotengine.org)\n"
	+ "Um jogo pessoal de Marcos Paulo, pro Murilo\n\n"
	+ "Obrigado por jogar!"
)

@onready var _label_texto: Label = $Control/Painel/Margem/VBox/LabelTexto
@onready var _botao_voltar: Button = $Control/Painel/Margem/VBox/BotaoVoltar


func _ready() -> void:
	visible = false
	_botao_voltar.pressed.connect(_ao_voltar)
	EventBus.game_completed.connect(_abrir)


func _abrir() -> void:
	visible = true
	GameState.mudar_estado(GameState.State.PAUSED)
	_label_texto.text = TEXTO_VITORIA + "\n\n" + TEXTO_CREDITOS


func _ao_voltar() -> void:
	visible = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
