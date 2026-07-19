extends CanvasLayer
## Tela de criação de personagem (ADR-015): escolha de cor por categoria,
## preview ao vivo no próprio Murilo já no mundo. Ver docs/01-GDD.md.

var _player: Player = null

@onready var _linha_pele: HBoxContainer = $Control/Painel/Margem/VBox/LinhaPele/Swatches
@onready var _linha_cabelo: HBoxContainer = $Control/Painel/Margem/VBox/LinhaCabelo/Swatches
@onready var _linha_camisa: HBoxContainer = $Control/Painel/Margem/VBox/LinhaCamisa/Swatches
@onready var _linha_calca: HBoxContainer = $Control/Painel/Margem/VBox/LinhaCalca/Swatches
@onready var _botao_jogar: Button = $Control/Painel/Margem/VBox/BotaoJogar


func _ready() -> void:
	if GameState.veio_de_continuar:
		# Aparência já vem do save; a tela de criação não faz sentido aqui.
		GameState.mudar_estado(GameState.State.PLAYING)
		queue_free()
		return

	GameState.mudar_estado(GameState.State.CHARACTER_CREATION)
	_player = get_tree().get_first_node_in_group("player") as Player

	_popular_linha(_linha_pele, CharacterAppearance.PALETA_PELE, _ao_escolher_pele)
	_popular_linha(_linha_cabelo, CharacterAppearance.PALETA_CABELO, _ao_escolher_cabelo)
	_popular_linha(_linha_camisa, CharacterAppearance.PALETA_CAMISA, _ao_escolher_camisa)
	_popular_linha(_linha_calca, CharacterAppearance.PALETA_CALCA, _ao_escolher_calca)
	_botao_jogar.pressed.connect(_ao_confirmar)


func _popular_linha(linha: HBoxContainer, paleta: Array[Color], callback: Callable) -> void:
	for cor: Color in paleta:
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(36, 36)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = cor
		estilo.set_corner_radius_all(6)
		botao.add_theme_stylebox_override("normal", estilo)
		botao.add_theme_stylebox_override("hover", estilo)
		botao.add_theme_stylebox_override("pressed", estilo)
		botao.pressed.connect(callback.bind(cor))
		linha.add_child(botao)


func _ao_escolher_pele(cor: Color) -> void:
	GameState.aparencia_atual.cor_pele = cor
	_atualizar_preview()


func _ao_escolher_cabelo(cor: Color) -> void:
	GameState.aparencia_atual.cor_cabelo = cor
	_atualizar_preview()


func _ao_escolher_camisa(cor: Color) -> void:
	GameState.aparencia_atual.cor_camisa = cor
	_atualizar_preview()


func _ao_escolher_calca(cor: Color) -> void:
	GameState.aparencia_atual.cor_calca = cor
	_atualizar_preview()


func _atualizar_preview() -> void:
	if _player != null:
		_player.aplicar_aparencia(GameState.aparencia_atual)


func _ao_confirmar() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)
	queue_free()
