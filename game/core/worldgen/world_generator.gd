class_name WorldGenerator
extends RefCounted
## Geração procedural determinística por seed (ADR-005, docs/02-ARQUITETURA.md §4.2).
## Puro: mesma seed + mesmas coordenadas de chunk sempre produzem o mesmo ChunkData,
## chamado em qualquer ordem, sem estado compartilhado entre chunks.

const ALTURA_BASE: int = 30
const ALTURA_AMPLITUDE: float = 8.0
const CHANCE_ARVORE: float = 0.04
const MARGEM_ARVORE: int = 2
const CHANCE_FERRITE: float = 0.018
const CHANCE_CARVAO: float = 0.035
const SEMENTE_MINERIO: int = 7919  ## offset pra descorrelacionar do hash de árvores

var _seed: int
var _ruido: FastNoiseLite


func _init(mundo_seed: int) -> void:
	_seed = mundo_seed
	_ruido = FastNoiseLite.new()
	_ruido.seed = mundo_seed
	_ruido.frequency = 0.02


func _altura_em(world_x: int, world_z: int) -> int:
	var n := _ruido.get_noise_2d(float(world_x), float(world_z))
	return ALTURA_BASE + int(round(n * ALTURA_AMPLITUDE))


func _bloco_de_subsolo(world_x: int, y: int, world_z: int) -> int:
	## Minérios em clusters determinísticos dentro da pedra (sem cavernas
	## de verdade — "strip mining" cavando reto pra baixo já funciona; F6).
	var h := _hash01(_seed + SEMENTE_MINERIO, world_x, world_z * 10007 + y)
	if h < CHANCE_FERRITE:
		return 11  # ferrite
	if h < CHANCE_FERRITE + CHANCE_CARVAO:
		return 10  # carvao
	return 3  # pedra


static func _hash01(seed: int, x: int, z: int) -> float:
	var h: int = seed
	h = (h * 374761393 + x * 668265263) & 0x7fffffff
	h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff
	h = (h ^ (z * 2246822519)) & 0x7fffffff
	h = (h ^ (h >> 16)) & 0x7fffffff
	return float(h) / float(0x7fffffff)


func gerar_chunk(cx: int, cz: int) -> ChunkData:
	var chunk := ChunkData.new()
	var alturas: Dictionary = {}

	for lx in range(ChunkData.SIZE_H):
		for lz in range(ChunkData.SIZE_H):
			var world_x := cx * ChunkData.SIZE_H + lx
			var world_z := cz * ChunkData.SIZE_H + lz
			var altura := _altura_em(world_x, world_z)
			alturas[Vector2i(lx, lz)] = altura
			for y in range(0, altura - 2):
				chunk.set_block(lx, y, lz, _bloco_de_subsolo(world_x, y, world_z))
			for y in range(max(altura - 2, 0), altura):
				chunk.set_block(lx, y, lz, 2)  # terra
			chunk.set_block(lx, altura, lz, 1)  # grama

	for lx in range(MARGEM_ARVORE, ChunkData.SIZE_H - MARGEM_ARVORE):
		for lz in range(MARGEM_ARVORE, ChunkData.SIZE_H - MARGEM_ARVORE):
			var world_x := cx * ChunkData.SIZE_H + lx
			var world_z := cz * ChunkData.SIZE_H + lz
			if _hash01(_seed, world_x, world_z) < CHANCE_ARVORE:
				_plantar_arvore(chunk, lx, alturas[Vector2i(lx, lz)], lz)

	return chunk


func _plantar_arvore(chunk: ChunkData, lx: int, altura_solo: int, lz: int) -> void:
	var base_tronco := altura_solo + 1
	for i in range(4):
		chunk.set_block(lx, base_tronco + i, lz, 4)  # tronco
	var topo := base_tronco + 3
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for dy in range(0, 2):
				if dx == 0 and dz == 0 and dy == 0:
					continue
				chunk.set_block(lx + dx, topo + dy, lz + dz, 5)  # folhas
	chunk.set_block(lx, topo + 2, lz, 5)
