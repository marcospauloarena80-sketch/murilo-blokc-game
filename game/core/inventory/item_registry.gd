class_name ItemRegistry
extends RefCounted
## Registro estático dos ItemDef por id (String). Ver docs/02-ARQUITETURA.md §4.4.
## Não é autoload (ADR: máximo 5) — acesso via métodos estáticos.

static var _itens: Dictionary = {
	"terra": preload("res://data/items/terra.tres"),
	"pedra": preload("res://data/items/pedra.tres"),
	"tronco": preload("res://data/items/tronco.tres"),
	"areia": preload("res://data/items/areia.tres"),
	"tabua": preload("res://data/items/tabua.tres"),
	"graveto": preload("res://data/items/graveto.tres"),
	"bancada": preload("res://data/items/bancada.tres"),
	"picareta_madeira": preload("res://data/items/picareta_madeira.tres"),
	"machado_madeira": preload("res://data/items/machado_madeira.tres"),
	"picareta_pedra": preload("res://data/items/picareta_pedra.tres"),
}


static func get_item(id: String) -> ItemDef:
	return _itens.get(id, null)


static func todos_os_ids() -> Array:
	return _itens.keys()
