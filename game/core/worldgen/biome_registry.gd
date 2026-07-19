class_name BiomeRegistry
extends RefCounted
## Registro estático dos BiomeDef por bioma_id (String). Ver docs/02-ARQUITETURA.md §4.2.
## Não é autoload (ADR: máximo 5) — acesso via métodos estáticos.

static var _biomas: Dictionary = {
	"campos_dourados": preload("res://data/biomes/campos_dourados.tres"),
	"floresta_cubica": preload("res://data/biomes/floresta_cubica.tres"),
	"colinas_de_pedra": preload("res://data/biomes/colinas_de_pedra.tres"),
	"deserto_de_ambar": preload("res://data/biomes/deserto_de_ambar.tres"),
	"picos_gelados": preload("res://data/biomes/picos_gelados.tres"),
}


static func get_bioma(bioma_id: String) -> BiomeDef:
	return _biomas.get(bioma_id, null)


static func todos_os_ids() -> Array:
	return _biomas.keys()
