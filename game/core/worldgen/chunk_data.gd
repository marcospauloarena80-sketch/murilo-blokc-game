class_name ChunkData
extends RefCounted
## Armazenamento puro de um chunk: 1 byte = 1 id de bloco (ADR-005, docs/02-ARQUITETURA.md §4.2).
## Coordenadas locais: x,z em [0, SIZE_H), y em [0, SIZE_V).

const SIZE_H: int = 16
const SIZE_V: int = 64

var _blocos: PackedByteArray


func _init() -> void:
	_blocos = PackedByteArray()
	_blocos.resize(SIZE_H * SIZE_H * SIZE_V)


static func _dentro_dos_limites(x: int, y: int, z: int) -> bool:
	return x >= 0 and x < SIZE_H and z >= 0 and z < SIZE_H and y >= 0 and y < SIZE_V


static func _indice(x: int, y: int, z: int) -> int:
	return x + z * SIZE_H + y * SIZE_H * SIZE_H


func get_block(x: int, y: int, z: int) -> int:
	if not _dentro_dos_limites(x, y, z):
		return BlockRegistry.AR_ID
	return _blocos[_indice(x, y, z)]


func set_block(x: int, y: int, z: int, id: int) -> void:
	if not _dentro_dos_limites(x, y, z):
		return
	_blocos[_indice(x, y, z)] = id
