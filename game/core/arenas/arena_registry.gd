class_name ArenaRegistry
extends RefCounted
## Registro estático das ArenaDef por arena_id (String). Ver docs/02-ARQUITETURA.md §4.2.
## Não é autoload (ADR: máximo 5) — acesso via métodos estáticos.

static var _arenas: Dictionary = {
	"pedra": preload("res://data/arenas/pedra.tres"),
	"brasa": preload("res://data/arenas/brasa.tres"),
	"gota": preload("res://data/arenas/gota.tres"),
	"faisca": preload("res://data/arenas/faisca.tres"),
	"coracao_dourado": preload("res://data/arenas/coracao_dourado.tres"),
}


static func get_arena(arena_id: String) -> ArenaDef:
	return _arenas.get(arena_id, null)


static func todos_os_ids() -> Array:
	return _arenas.keys()
