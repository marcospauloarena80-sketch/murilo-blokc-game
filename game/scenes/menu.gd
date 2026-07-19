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
	GameState.ciclo_dia_noite_seg = float(
		dados.get("ciclo_dia_noite_seg", GameState.DURACAO_CICLO_SEG * 0.25)
	)
	GameState.vida_atual = int(dados.get("vida_atual", GameState.vida_maxima))
	GameState.fome_atual = int(dados.get("fome_atual", GameState.fome_maxima))
	GameState.energia_atual = int(dados.get("energia_atual", GameState.energia_maxima))
	GameState.hotbar_selecionado = int(dados.get("hotbar_selecionado", 0))

	GameState.aparencia_atual = CharacterAppearance.new()
	GameState.aparencia_atual.carregar_serializado(dados.get("aparencia", {}))

	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_hotbar.carregar_serializado(dados.get("hotbar", []))
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.inventario_mochila.carregar_serializado(dados.get("mochila", []))

	GameState.delta_blocos_carregado = dados.get("delta_blocos", {})
	GameState.posicao_salva = _array_para_vector3(dados.get("jogador_posicao", []))
	GameState.ponto_respawn = _array_para_vector3(dados.get("ponto_respawn", []))
	GameState.baus = _dicionario_para_baus(dados.get("baus", {}))
	GameState.equipe_cubelins = _array_para_cubelins(dados.get("equipe_cubelins", []))
	GameState.deposito_cubelins = _array_para_cubelins(dados.get("deposito_cubelins", []))
	GameState.veio_de_continuar = true

	get_tree().change_scene_to_file("res://scenes/main.tscn")


static func _array_para_vector3(dados: Array) -> Vector3:
	if dados.size() < 3:
		return Vector3(64, 45, 64)
	return Vector3(dados[0], dados[1], dados[2])


static func _dicionario_para_baus(dados: Dictionary) -> Dictionary:
	var resultado: Dictionary = {}
	for chave: String in dados:
		var inventario := InventoryModel.new(24)
		inventario.carregar_serializado(dados[chave])
		resultado[chave] = inventario
	return resultado


static func _array_para_cubelins(dados: Array) -> Array[CreatureInstance]:
	var resultado: Array[CreatureInstance] = []
	for item: Dictionary in dados:
		resultado.append(CreatureInstance.carregar_serializado(item))
	return resultado
