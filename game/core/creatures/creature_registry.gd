class_name CreatureRegistry
extends RefCounted
## Registro estático dos CreatureDef por especie_id (String). Ver docs/02-ARQUITETURA.md §4.2.
## Não é autoload (ADR: máximo 5) — acesso via métodos estáticos.

static var _criaturas: Dictionary = {
	"brotinho": preload("res://data/creatures/brotinho.tres"),
	"ventim": preload("res://data/creatures/ventim.tres"),
	"pedrolim": preload("res://data/creatures/pedrolim.tres"),
	"faiscolt": preload("res://data/creatures/faiscolt.tres"),
}


static func get_creature(especie_id: String) -> CreatureDef:
	return _criaturas.get(especie_id, null)


static func todos_os_ids() -> Array:
	return _criaturas.keys()
