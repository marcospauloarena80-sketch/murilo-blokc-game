extends Control
## Menu principal: Novo Jogo / Continuar / Opções. Ver docs/02-ARQUITETURA.md §4.1 (F5).
## Ao fundo, o mundo de verdade (Frente 6D): um ChunkManager pequeno dentro de
## um SubViewport gera só os 3x3 chunks do centro e a câmera orbita devagar.

## Órbita da câmera do cenário: ponto olhado, raio, altura e velocidade angular.
const CENTRO_CENARIO := Vector3(64, 34, 64)
const RAIO_ORBITA: float = 22.0
const ALTURA_ORBITA: float = 42.0
const VELOCIDADE_ORBITA_RAD_S: float = 0.08

var _angulo_orbita: float = 0.0

@onready var _botao_novo_jogo: Button = $VBox/BotaoNovoJogo
@onready var _botao_continuar: Button = $VBox/BotaoContinuar
@onready var _botao_opcoes: Button = $VBox/BotaoOpcoes
@onready var _camera_cenario: Camera3D = $Cenario3D/SubViewport/Cenario/Camera3D
@onready var _opcoes: OptionsScreen = $OptionsScreen


func _ready() -> void:
	GameState.mudar_estado(GameState.State.MENU)
	## O ChunkManager do cenário não tem Player e, com veio_de_continuar ligado
	## (volta da pausa), ordenaria a fila pela posição salva; o menu é estado
	## limpo e a câmera olha pro centro do mundo. Continuar religa a flag.
	GameState.veio_de_continuar = false
	Opcoes.carregar()
	Opcoes.aplicar()
	_botao_continuar.disabled = not SaveManager.existe_save()
	_botao_novo_jogo.pressed.connect(_ao_novo_jogo)
	_botao_continuar.pressed.connect(_ao_continuar)
	_botao_opcoes.pressed.connect(_opcoes.abrir)
	_posicionar_camera()


func _process(delta: float) -> void:
	_angulo_orbita = fmod(_angulo_orbita + VELOCIDADE_ORBITA_RAD_S * delta, TAU)
	_posicionar_camera()


func _posicionar_camera() -> void:
	_camera_cenario.position = Vector3(
		CENTRO_CENARIO.x + cos(_angulo_orbita) * RAIO_ORBITA,
		ALTURA_ORBITA,
		CENTRO_CENARIO.z + sin(_angulo_orbita) * RAIO_ORBITA
	)
	_camera_cenario.look_at(CENTRO_CENARIO)


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
	GameState.quest_atual_id = String(dados.get("quest_atual_id", ""))
	GameState.progresso_quest_atual = int(dados.get("progresso_quest_atual", 0))
	GameState.quests_concluidas = _array_para_strings(dados.get("quests_concluidas", []))
	GameState.insignias_conquistadas = _array_para_strings(dados.get("insignias_conquistadas", []))
	GameState.especies_vistas = _array_para_strings(dados.get("especies_vistas", []))
	GameState.especies_capturadas = _array_para_strings(dados.get("especies_capturadas", []))
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


static func _array_para_strings(dados: Array) -> Array[String]:
	var resultado: Array[String] = []
	for item: String in dados:
		resultado.append(item)
	return resultado
