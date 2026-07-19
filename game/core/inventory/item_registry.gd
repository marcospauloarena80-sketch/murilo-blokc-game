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
	"cama": preload("res://data/items/cama.tres"),
	"bau": preload("res://data/items/bau.tres"),
	"tocha": preload("res://data/items/tocha.tres"),
	"carvao": preload("res://data/items/carvao.tres"),
	"ferrite": preload("res://data/items/ferrite.tres"),
	"picareta_ferrite": preload("res://data/items/picareta_ferrite.tres"),
	"machado_ferrite": preload("res://data/items/machado_ferrite.tres"),
	"maca": preload("res://data/items/maca.tres"),
	"maca_assada": preload("res://data/items/maca_assada.tres"),
	"fornalha": preload("res://data/items/fornalha.tres"),
	"espada_pedra": preload("res://data/items/espada_pedra.tres"),
	"cubo_captura": preload("res://data/items/cubo_captura.tres"),
	"pocao_cura": preload("res://data/items/pocao_cura.tres"),
}


static func get_item(id: String) -> ItemDef:
	return _itens.get(id, null)


static func todos_os_ids() -> Array:
	return _itens.keys()
