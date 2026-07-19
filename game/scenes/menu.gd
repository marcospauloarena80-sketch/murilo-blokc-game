extends Control
## Menu principal: Novo Jogo / Continuar. Ver docs/02-ARQUITETURA.md §4.1 (F5).

@onready var _botao_novo_jogo: Button = $VBox/BotaoNovoJogo
@onready var _botao_continuar: Button = $VBox/BotaoContinuar


func _ready() -> void:
	GameState.mudar_estado(GameState.State.MENU)
	_botao_continuar.disabled = not SaveManager.existe_save()
	_botao_novo_jogo.pressed.connect(_ao_novo_jogo)
	_botao_continuar.pressed.connect(_ao_continuar)


func _ao_novo_jogo() -> void:
	GameState.reiniciar_para_novo_jogo()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _ao_continuar() -> void:
	var dados := SaveManager.carregar()
	if dados.is_empty():
		return

	GameState.seed_atual = int(dados.get("seed", 0))
	GameState.tempo_de_jogo_seg = float(dados.get("tempo_de_jogo_seg", 0.0))
	GameState.vida_atual = int(dados.get("vida_atual", GameState.vida_maxima))
	GameState.hotbar_selecionado = int(dados.get("hotbar_selecionado", 0))

	GameState.aparencia_atual = CharacterAppearance.new()
	GameState.aparencia_atual.carregar_serializado(dados.get("aparencia", {}))

	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_hotbar.carregar_serializado(dados.get("hotbar", []))
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.inventario_mochila.carregar_serializado(dados.get("mochila", []))

	GameState.delta_blocos_carregado = dados.get("delta_blocos", {})
	GameState.posicao_salva = _array_para_vector3(dados.get("jogador_posicao", []))
	GameState.veio_de_continuar = true

	get_tree().change_scene_to_file("res://scenes/main.tscn")


static func _array_para_vector3(dados: Array) -> Vector3:
	if dados.size() < 3:
		return Vector3(64, 45, 64)
	return Vector3(dados[0], dados[1], dados[2])
