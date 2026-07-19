class_name CreatureSpawner
extends Node3D
## Spawna Cubelins periodicamente: passivos de dia, agressivos de noite —
## sempre na superfície (sem geração de cavernas ainda; ver docs/07-DECISOES.md
## ADR-020). Limite de população simultânea + despawn de criaturas distantes.

const CreatureScene := preload("res://entities/creatures/creature.tscn")

const INTERVALO_SPAWN_SEG: float = 15.0
const MAX_CRIATURAS: int = 8
const RAIO_SPAWN_MIN: float = 10.0
const RAIO_SPAWN_MAX: float = 24.0
const RAIO_DESPAWN: float = 48.0

var _chunk_manager: ChunkManager
var _jogador: Node3D
var _tempo_desde_spawn: float = 0.0


func _process(delta: float) -> void:
	_garantir_referencias()
	if GameState.current_state != GameState.State.PLAYING:
		return
	_despawnar_distantes()
	_tempo_desde_spawn += delta
	if _tempo_desde_spawn < INTERVALO_SPAWN_SEG:
		return
	_tempo_desde_spawn = 0.0
	_tentar_spawnar()


func _garantir_referencias() -> void:
	if _chunk_manager == null:
		_chunk_manager = get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	if _jogador == null:
		_jogador = get_tree().get_first_node_in_group("player")


func _tentar_spawnar() -> void:
	_garantir_referencias()
	if _jogador == null or _chunk_manager == null:
		return
	if get_tree().get_nodes_in_group("creature").size() >= MAX_CRIATURAS:
		return

	var periodo: String = "noite" if GameState.eh_noite() else "dia"
	var candidatas: Array[CreatureDef] = _especies_do_periodo(periodo)
	if candidatas.is_empty():
		return

	var angulo: float = randf() * TAU
	var raio: float = randf_range(RAIO_SPAWN_MIN, RAIO_SPAWN_MAX)
	var x: int = int(floor(_jogador.global_position.x + cos(angulo) * raio))
	var z: int = int(floor(_jogador.global_position.z + sin(angulo) * raio))
	var y: int = _altura_da_superficie(x, z)
	if y < 0:
		return

	var def: CreatureDef = candidatas[randi() % candidatas.size()]
	var criatura := CreatureScene.instantiate() as Creature
	criatura.configurar(def)
	add_child(criatura)
	criatura.global_position = Vector3(x + 0.5, y + 1.0, z + 0.5)


func _especies_do_periodo(periodo: String) -> Array[CreatureDef]:
	var resultado: Array[CreatureDef] = []
	for id: String in CreatureRegistry.todos_os_ids():
		var def: CreatureDef = CreatureRegistry.get_creature(id)
		if def.periodo_spawn == periodo and def.pode_ser_selvagem:
			resultado.append(def)
	return resultado


func _altura_da_superficie(x: int, z: int) -> int:
	for y in range(ChunkData.SIZE_V - 1, -1, -1):
		if BlockRegistry.e_solido(_chunk_manager.get_block(Vector3i(x, y, z))):
			return y
	return -1


func _despawnar_distantes() -> void:
	if _jogador == null:
		return
	for no: Node in get_tree().get_nodes_in_group("creature"):
		var criatura := no as Node3D
		if criatura.global_position.distance_to(_jogador.global_position) > RAIO_DESPAWN:
			criatura.queue_free()
