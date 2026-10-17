class_name CreatureSpawner
extends Node3D
## Spawna Cubelins periodicamente: passivos de dia, agressivos de noite —
## sempre na superfície. Desde a F11 (ADR-024) o spawn também respeita o
## bioma da posição sorteada — Cavernas (Pedra/Faísca) continuam onipresentes
## à noite (mesmo comportamento da F7/ADR-020), os outros elementos exigem o
## anel de bioma certo.

const CreatureScene := preload("res://entities/creatures/creature.tscn")

const INTERVALO_SPAWN_SEG: float = 15.0
const MAX_CRIATURAS: int = 8
## Animais (Ciclo 8, 8B) têm limite próprio, além do de Cubelins.
const MAX_ANIMAIS: int = 6
const CHANCE_ANIMAL: float = 0.5
const RAIO_SPAWN_MIN: float = 10.0
const RAIO_SPAWN_MAX: float = 24.0
const RAIO_DESPAWN: float = 48.0
## Caixa da criatura (0.7) é centrada na origem: nascer com o centro no topo do
## bloco deixava metade dela dentro do chão. Com a malha do avesso a física a
## empurrava pra fora por acaso; com a malha certa ela atravessava (ADR-027).
const ALTURA_ACIMA_DO_CHAO: float = 0.4
const GRAMA_ID: int = 1
const ELEMENTOS_CAVERNA := ["pedra", "faisca"]  ## camada onipresente à noite (F6/F7), não é anel

## Por que a última tentativa não gerou criatura (diagnóstico; "" = gerou).
var ultimo_motivo_sem_spawn: String = ""

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
		ultimo_motivo_sem_spawn = "sem jogador ou chunk_manager"
		return
	var animais: int = get_tree().get_nodes_in_group("animal").size()
	var cubelins: int = get_tree().get_nodes_in_group("creature").size() - animais
	var cheio_de_cubelins: bool = cubelins >= MAX_CRIATURAS
	if cheio_de_cubelins and animais >= MAX_ANIMAIS:
		ultimo_motivo_sem_spawn = "limite de criaturas"
		return

	var angulo: float = randf() * TAU
	var raio: float = randf_range(RAIO_SPAWN_MIN, RAIO_SPAWN_MAX)
	var x: int = int(floor(_jogador.global_position.x + cos(angulo) * raio))
	var z: int = int(floor(_jogador.global_position.z + sin(angulo) * raio))
	if not _chunk_manager.chunk_pronto_em(Vector3(x, 0, z)):
		ultimo_motivo_sem_spawn = "chunk sem colisão"  # cairia pelo mundo (ADR-026)
		return
	var y: int = _altura_da_superficie(x, z)
	if y < 0:
		ultimo_motivo_sem_spawn = "sem superfície em %d,%d" % [x, z]
		return
	if _chunk_manager.get_block(Vector3i(x, y + 1, z)) == BlockRegistry.AGUA_ID:
		ultimo_motivo_sem_spawn = "lago em %d,%d" % [x, z]
		return

	var periodo: String = "noite" if GameState.eh_noite() else "dia"
	var bioma_id := WorldGenerator.bioma_em(x, z)
	if periodo == "dia" and animais < MAX_ANIMAIS and randf() < CHANCE_ANIMAL:
		if _spawnar_animal(x, y, z, bioma_id):
			return
	_spawnar_cubelin(x, y, z, periodo, bioma_id, cheio_de_cubelins)


func _spawnar_cubelin(
	x: int, y: int, z: int, periodo: String, bioma_id: String, cheio_de_cubelins: bool
) -> void:
	if cheio_de_cubelins:
		ultimo_motivo_sem_spawn = "limite de criaturas"
		return
	var candidatas: Array[CreatureDef] = _especies_do_periodo_e_bioma(periodo, bioma_id)
	if candidatas.is_empty():
		ultimo_motivo_sem_spawn = "nenhuma espécie pra %s/%s" % [periodo, bioma_id]
		return
	ultimo_motivo_sem_spawn = ""

	var def: CreatureDef = candidatas[randi() % candidatas.size()]
	var criatura := CreatureScene.instantiate() as Creature
	criatura.configurar(def)
	add_child(criatura)
	criatura.global_position = Vector3(x + 0.5, y + 1.0 + ALTURA_ACIMA_DO_CHAO, z + 0.5)


## Animais nascem de dia, só em grama, no bioma da espécie. true = nasceu.
func _spawnar_animal(x: int, y: int, z: int, bioma_id: String) -> bool:
	if _chunk_manager.get_block(Vector3i(x, y, z)) != GRAMA_ID:
		return false
	var candidatas: Array[CreatureDef] = []
	for id: String in CreatureRegistry.ids_animais():
		var def: CreatureDef = CreatureRegistry.get_creature(id)
		if def.bioma_animal == "" or def.bioma_animal == bioma_id:
			candidatas.append(def)
	if candidatas.is_empty():
		return false
	ultimo_motivo_sem_spawn = ""
	var animal := CreatureScene.instantiate() as Creature
	animal.configurar(candidatas[randi() % candidatas.size()])
	add_child(animal)
	animal.global_position = Vector3(x + 0.5, y + 1.0 + ALTURA_ACIMA_DO_CHAO, z + 0.5)
	return true


func _especies_do_periodo_e_bioma(periodo: String, bioma_id: String) -> Array[CreatureDef]:
	var elementos_permitidos: Array = ELEMENTOS_CAVERNA.duplicate() if periodo == "noite" else []
	var bioma := BiomeRegistry.get_bioma(bioma_id)
	if bioma != null:
		for elemento: String in bioma.elementos_cubelin:
			if not elementos_permitidos.has(elemento):
				elementos_permitidos.append(elemento)

	var tempestade := _tempestade_ativa()
	var resultado: Array[CreatureDef] = []
	for id: String in CreatureRegistry.todos_os_ids():
		var def: CreatureDef = CreatureRegistry.get_creature(id)
		if not def.pode_ser_selvagem or def.periodo_spawn != periodo:
			continue
		if not elementos_permitidos.has(def.elemento):
			continue
		resultado.append(def)
		if tempestade and def.elemento == "faisca":
			resultado.append(def)  # peso dobrado durante tempestade (F11, ADR-024)
	return resultado


func _tempestade_ativa() -> bool:
	var clima := get_tree().get_first_node_in_group("weather_system") as WeatherSystem
	return clima != null and clima.eh_tempestade()


func _altura_da_superficie(x: int, z: int) -> int:
	return _chunk_manager.altura_da_superficie(x, z)


func _despawnar_distantes() -> void:
	if _jogador == null:
		return
	for no: Node in get_tree().get_nodes_in_group("creature"):
		var criatura := no as Node3D
		if criatura.global_position.distance_to(_jogador.global_position) > RAIO_DESPAWN:
			criatura.queue_free()
