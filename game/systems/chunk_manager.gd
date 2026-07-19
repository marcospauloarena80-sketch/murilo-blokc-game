class_name ChunkManager
extends Node3D
## Orquestra os chunks do mundo: geração, malha e colisão. Mundo finito 8x8 chunks
## (ADR-005). API pública: get_block/set_block em coordenadas de mundo.
## Re-mesh incremental é time-sliced (docs/09-PERFORMANCE.md) — no máximo
## CHUNKS_POR_FRAME chunks processados por frame, nunca o mundo inteiro de uma vez.

signal mundo_gerado

const WORLD_CHUNKS_X: int = 8
const WORLD_CHUNKS_Z: int = 8
const CHUNKS_POR_FRAME: int = 2

@export var world_seed: int = 12345

var _worldgen: WorldGenerator
var _mesher: ChunkMesher
var _material: StandardMaterial3D
var _chunks: Dictionary = {}
var _chunk_nodes: Dictionary = {}
var _fila_sujos: Array[Vector2i] = []
var _edicoes: Dictionary = {}


func _ready() -> void:
	add_to_group("chunk_manager")
	if GameState.seed_atual != 0:
		world_seed = GameState.seed_atual
	_worldgen = WorldGenerator.new(world_seed)
	_mesher = ChunkMesher.new()
	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_gerar_mundo()


func _gerar_mundo() -> void:
	for cx in range(WORLD_CHUNKS_X):
		for cz in range(WORLD_CHUNKS_Z):
			var coord := Vector2i(cx, cz)
			_chunks[coord] = _worldgen.gerar_chunk(cx, cz)
			_fila_sujos.append(coord)


func _process(_delta: float) -> void:
	var processados := 0
	while not _fila_sujos.is_empty() and processados < CHUNKS_POR_FRAME:
		var coord: Vector2i = _fila_sujos.pop_front()
		_remesh_chunk(coord)
		processados += 1
	if _fila_sujos.is_empty() and processados > 0:
		mundo_gerado.emit()


func _world_para_chunk_local(world_pos: Vector3i) -> Dictionary:
	var cx: int = int(floor(float(world_pos.x) / ChunkData.SIZE_H))
	var cz: int = int(floor(float(world_pos.z) / ChunkData.SIZE_H))
	var lx: int = world_pos.x - cx * ChunkData.SIZE_H
	var lz: int = world_pos.z - cz * ChunkData.SIZE_H
	return {"chunk": Vector2i(cx, cz), "local": Vector3i(lx, world_pos.y, lz)}


func get_block(world_pos: Vector3i) -> int:
	if world_pos.y < 0 or world_pos.y >= ChunkData.SIZE_V:
		return BlockRegistry.AR_ID
	var info := _world_para_chunk_local(world_pos)
	var coord: Vector2i = info["chunk"]
	if not _chunks.has(coord):
		return BlockRegistry.AR_ID
	var local: Vector3i = info["local"]
	var chunk: ChunkData = _chunks[coord]
	return chunk.get_block(local.x, local.y, local.z)


func set_block(world_pos: Vector3i, id: int) -> void:
	if world_pos.y < 0 or world_pos.y >= ChunkData.SIZE_V:
		return
	var info := _world_para_chunk_local(world_pos)
	var coord: Vector2i = info["chunk"]
	if not _chunks.has(coord):
		return
	var local: Vector3i = info["local"]
	var chunk: ChunkData = _chunks[coord]
	var id_anterior := chunk.get_block(local.x, local.y, local.z)
	chunk.set_block(local.x, local.y, local.z, id)
	_edicoes[world_pos] = id
	if id == BlockRegistry.AR_ID:
		EventBus.block_broken.emit(world_pos, id_anterior)
	else:
		EventBus.block_placed.emit(world_pos, id)
	_marcar_sujo(coord)
	if local.x == 0:
		_marcar_sujo(coord + Vector2i(-1, 0))
	if local.x == ChunkData.SIZE_H - 1:
		_marcar_sujo(coord + Vector2i(1, 0))
	if local.z == 0:
		_marcar_sujo(coord + Vector2i(0, -1))
	if local.z == ChunkData.SIZE_H - 1:
		_marcar_sujo(coord + Vector2i(0, 1))


func exportar_delta() -> Dictionary:
	## Chaves viram String pra caber em JSON (ADR-006).
	var resultado: Dictionary = {}
	for pos: Vector3i in _edicoes:
		resultado["%d,%d,%d" % [pos.x, pos.y, pos.z]] = _edicoes[pos]
	return resultado


func aplicar_delta(delta: Dictionary) -> void:
	for chave: String in delta:
		var partes: PackedStringArray = chave.split(",")
		var pos := Vector3i(int(partes[0]), int(partes[1]), int(partes[2]))
		set_block(pos, int(delta[chave]))


func tem_chunks_pendentes() -> bool:
	return not _fila_sujos.is_empty()


func fila_pendente_tamanho() -> int:
	return _fila_sujos.size()


func _marcar_sujo(coord: Vector2i) -> void:
	if _chunks.has(coord) and not _fila_sujos.has(coord):
		_fila_sujos.append(coord)


func _remesh_chunk(coord: Vector2i) -> void:
	var chunk: ChunkData = _chunks[coord]
	var vizinho_solido := func(lx: int, ly: int, lz: int) -> bool:
		var wx: int = coord.x * ChunkData.SIZE_H + lx
		var wz: int = coord.y * ChunkData.SIZE_H + lz
		return BlockRegistry.e_solido(get_block(Vector3i(wx, ly, wz)))
	var malha := _mesher.construir_malha(chunk, vizinho_solido)
	_atualizar_no_chunk(coord, malha)


func _atualizar_no_chunk(coord: Vector2i, malha: ArrayMesh) -> void:
	if _chunk_nodes.has(coord):
		var antigo: Node3D = _chunk_nodes[coord]
		antigo.queue_free()
		_chunk_nodes.erase(coord)
	if malha == null:
		return
	var no := StaticBody3D.new()
	no.position = Vector3(coord.x * ChunkData.SIZE_H, 0, coord.y * ChunkData.SIZE_H)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = malha
	mesh_instance.material_override = _material
	no.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	collision.shape = malha.create_trimesh_shape()
	no.add_child(collision)
	add_child(no)
	_chunk_nodes[coord] = no
