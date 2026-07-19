extends Node3D
## Orquestra save/load/autosave da sessão (F5) + ciclo dia/noite (F6). Cada
## sistema fornece seu próprio snapshot; este script só monta o Dictionary
## final e delega ao SaveManager. Ver docs/02-ARQUITETURA.md §4.6/§4.1.

const ItemDropScene := preload("res://entities/props/item_drop.tscn")

const INTERVALO_AUTOSAVE: float = 60.0
const INTERVALO_FOME_SEG: float = 60.0
const INTERVALO_DANO_FOME_SEG: float = 10.0

var _tempo_desde_autosave: float = 0.0
var _tempo_desde_fome: float = 0.0
var _tempo_desde_dano_fome: float = 0.0
var _era_noite: bool = false

@onready var _chunk_manager: ChunkManager = $ChunkManager
@onready var _player: Player = $Player
@onready var _luz_sol: DirectionalLight3D = $DirectionalLight3D
@onready var _ambiente: WorldEnvironment = $WorldEnvironment
@onready var _loot_spawner: Node3D = $LootSpawner


func _ready() -> void:
	if GameState.veio_de_continuar:
		_chunk_manager.aplicar_delta(GameState.delta_blocos_carregado)
	_era_noite = GameState.eh_noite()
	_atualizar_iluminacao()
	_posicionar_npcs_no_chao()


func _posicionar_npcs_no_chao() -> void:
	## NPCs (F9) são colocados no .tscn com Y aproximado — reajusta pra
	## superfície real do terreno gerado (sem arquitetura de vilarejo, ADR-022).
	for no: Node in get_tree().get_nodes_in_group("npc"):
		var npc := no as Node3D
		var x: int = int(floor(npc.global_position.x))
		var z: int = int(floor(npc.global_position.z))
		var y := _altura_da_superficie_em(x, z)
		if y >= 0:
			npc.global_position.y = float(y) + 1.0


func _altura_da_superficie_em(x: int, z: int) -> int:
	for y in range(ChunkData.SIZE_V - 1, -1, -1):
		if BlockRegistry.e_solido(_chunk_manager.get_block(Vector3i(x, y, z))):
			return y
	return -1


func _process(delta: float) -> void:
	if GameState.current_state != GameState.State.PLAYING:
		return
	GameState.tempo_de_jogo_seg += delta
	GameState.ciclo_dia_noite_seg += delta
	_atualizar_iluminacao()
	_verificar_transicao_dia_noite()

	_atualizar_fome(delta)
	_verificar_morte()

	_tempo_desde_autosave += delta
	if _tempo_desde_autosave >= INTERVALO_AUTOSAVE:
		_tempo_desde_autosave = 0.0
		salvar_jogo()


func _atualizar_fome(delta: float) -> void:
	_tempo_desde_fome += delta
	if _tempo_desde_fome >= INTERVALO_FOME_SEG:
		_tempo_desde_fome = 0.0
		GameState.fome_atual = max(0, GameState.fome_atual - 1)

	if GameState.fome_atual <= 0:
		_tempo_desde_dano_fome += delta
		if _tempo_desde_dano_fome >= INTERVALO_DANO_FOME_SEG and GameState.vida_atual > 1:
			_tempo_desde_dano_fome = 0.0
			GameState.vida_atual -= 1
	else:
		_tempo_desde_dano_fome = 0.0


func _verificar_morte() -> void:
	if GameState.vida_atual > 0:
		return
	_processar_morte()


func _processar_morte() -> void:
	var pos: Vector3 = _player.global_position
	for i in range(GameState.inventario_mochila.tamanho):
		var item_id := GameState.inventario_mochila.get_item_id(i)
		if item_id == "":
			continue
		var drop: ItemDrop = ItemDropScene.instantiate()
		drop.item_id = item_id
		drop.quantidade = GameState.inventario_mochila.get_quantidade(i)
		drop.position = pos + Vector3(randf_range(-0.5, 0.5), 0.2, randf_range(-0.5, 0.5))
		_loot_spawner.add_child(drop)

	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.vida_atual = GameState.vida_maxima
	_player.global_position = GameState.ponto_respawn
	_player.velocity = Vector3.ZERO
	EventBus.player_died.emit()


func _atualizar_iluminacao() -> void:
	var fase: float = GameState.ciclo_dia_noite_seg / GameState.DURACAO_CICLO_SEG
	var r: Dictionary = DayNightCalculator.calcular(fase, GameState.FRACAO_DIA)
	_luz_sol.rotation_degrees.x = r["angulo_x_graus"]
	_luz_sol.light_energy = r["energia_sol"]
	_ambiente.environment.ambient_light_energy = r["energia_ambiente"]
	_atualizar_cor_ambiente()


func _atualizar_cor_ambiente() -> void:
	## Cada bioma tinge a luz ambiente (BiomeDef.cor_ambiente); clima escurece
	## um pouco por cima disso — polimento visual da F11 (ADR-024).
	var bioma_id := WorldGenerator.bioma_em(
		int(_player.global_position.x), int(_player.global_position.z)
	)
	var bioma := BiomeRegistry.get_bioma(bioma_id)
	var cor: Color = bioma.cor_ambiente if bioma != null else Color.WHITE
	var clima := get_tree().get_first_node_in_group("weather_system") as WeatherSystem
	if clima != null and clima.estado_atual != WeatherService.Estado.NENHUM:
		cor = cor.darkened(0.25 if clima.eh_tempestade() else 0.12)
	_ambiente.environment.ambient_light_color = cor


func _verificar_transicao_dia_noite() -> void:
	var agora_noite: bool = GameState.eh_noite()
	if agora_noite == _era_noite:
		return
	_era_noite = agora_noite
	if agora_noite:
		EventBus.night_started.emit()
	else:
		EventBus.day_started.emit()


func salvar_jogo() -> void:
	var dados: Dictionary = {
		"seed": GameState.seed_atual,
		"tempo_de_jogo_seg": GameState.tempo_de_jogo_seg,
		"ciclo_dia_noite_seg": GameState.ciclo_dia_noite_seg,
		"vida_atual": GameState.vida_atual,
		"fome_atual": GameState.fome_atual,
		"energia_atual": GameState.energia_atual,
		"hotbar_selecionado": GameState.hotbar_selecionado,
		"aparencia": GameState.aparencia_atual.serializar(),
		"hotbar": GameState.inventario_hotbar.serializar(),
		"mochila": GameState.inventario_mochila.serializar(),
		"delta_blocos": _chunk_manager.exportar_delta(),
		"jogador_posicao": _vector3_para_array(_player.global_position),
		"ponto_respawn": _vector3_para_array(GameState.ponto_respawn),
		"baus": _serializar_baus(),
		"equipe_cubelins": _serializar_cubelins(GameState.equipe_cubelins),
		"deposito_cubelins": _serializar_cubelins(GameState.deposito_cubelins),
		"quest_atual_id": GameState.quest_atual_id,
		"progresso_quest_atual": GameState.progresso_quest_atual,
		"quests_concluidas": GameState.quests_concluidas,
		"insignias_conquistadas": GameState.insignias_conquistadas,
	}
	SaveManager.salvar(dados)
	EventBus.game_saved.emit()


func _serializar_baus() -> Dictionary:
	var resultado: Dictionary = {}
	for chave: String in GameState.baus:
		resultado[chave] = GameState.baus[chave].serializar()
	return resultado


func _serializar_cubelins(lista: Array[CreatureInstance]) -> Array:
	var resultado: Array = []
	for instancia: CreatureInstance in lista:
		resultado.append(instancia.serializar())
	return resultado


static func _vector3_para_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]
