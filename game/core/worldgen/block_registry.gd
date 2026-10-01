class_name BlockRegistry
extends RefCounted
## Registro estático dos BlockDef por id. id=0 é sempre "ar" (ausência de bloco).
## Ver docs/02-ARQUITETURA.md §4.2. Não é autoload (ADR: máximo 5) — acesso via métodos estáticos.

const AR_ID: int = 0

static var _blocos: Dictionary = {
	1: preload("res://data/blocks/grama.tres"),
	2: preload("res://data/blocks/terra.tres"),
	3: preload("res://data/blocks/pedra.tres"),
	4: preload("res://data/blocks/tronco.tres"),
	5: preload("res://data/blocks/folhas.tres"),
	6: preload("res://data/blocks/areia.tres"),
	7: preload("res://data/blocks/cama.tres"),
	8: preload("res://data/blocks/bau.tres"),
	9: preload("res://data/blocks/tocha.tres"),
	10: preload("res://data/blocks/carvao.tres"),
	11: preload("res://data/blocks/ferrite.tres"),
	12: preload("res://data/blocks/cristal_dourado.tres"),
	13: preload("res://data/blocks/tronco_raro.tres"),
	14: preload("res://data/blocks/gelo.tres"),
	15: preload("res://data/blocks/ambar_bloco.tres"),
}

static var _tabela_solidos: PackedByteArray = PackedByteArray()
static var _tabela_cores: PackedColorArray = PackedColorArray()


static func get_block(id: int) -> BlockDef:
	return _blocos.get(id, null)


static func tabela_solidos() -> PackedByteArray:
	## 256 entradas (1 byte por id): 1 = sólido. Consulta O(1) sem Dictionary
	## no caminho quente do mesher (ADR-026).
	if _tabela_solidos.is_empty():
		_tabela_solidos.resize(256)
		for id: int in _blocos:
			_tabela_solidos[id] = 1 if e_solido(id) else 0
	return _tabela_solidos


static func tabela_cores() -> PackedColorArray:
	if _tabela_cores.is_empty():
		_tabela_cores.resize(256)
		for id: int in _blocos:
			_tabela_cores[id] = (_blocos[id] as BlockDef).cor
	return _tabela_cores


static func e_solido(id: int) -> bool:
	if id == AR_ID:
		return false
	var bloco := get_block(id)
	return bloco != null and bloco.solido
