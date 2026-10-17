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
	"treinador_tico": preload("res://data/arenas/treinador_tico.tres"),
	"treinador_bia": preload("res://data/arenas/treinador_bia.tres"),
}


static func get_arena(arena_id: String) -> ArenaDef:
	return _arenas.get(arena_id, null)


static func ids_com_insignia() -> Array[String]:
	## Arenas que dão insígnia e não são o desafio final: as que o Coração Dourado exige.
	var ids: Array[String] = []
	for id: String in _arenas:
		var arena: ArenaDef = _arenas[id]
		if arena.da_insignia and not arena.requer_todas_insignias:
			ids.append(id)
	return ids


static func todos_os_ids() -> Array:
	return _arenas.keys()
