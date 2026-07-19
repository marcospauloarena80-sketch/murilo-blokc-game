class_name RecipeRegistry
extends RefCounted
## Registro estático das RecipeDef. Ver docs/02-ARQUITETURA.md §4.5.
## Não é autoload (ADR: máximo 5) — acesso via métodos estáticos.

static var _receitas: Array[RecipeDef] = [
	preload("res://data/recipes/tabua.tres"),
	preload("res://data/recipes/graveto.tres"),
	preload("res://data/recipes/bancada.tres"),
	preload("res://data/recipes/picareta_madeira.tres"),
	preload("res://data/recipes/machado_madeira.tres"),
	preload("res://data/recipes/picareta_pedra.tres"),
	preload("res://data/recipes/cama.tres"),
	preload("res://data/recipes/bau.tres"),
	preload("res://data/recipes/tocha.tres"),
	preload("res://data/recipes/fornalha.tres"),
	preload("res://data/recipes/picareta_ferrite.tres"),
	preload("res://data/recipes/machado_ferrite.tres"),
	preload("res://data/recipes/maca_assada.tres"),
	preload("res://data/recipes/espada_pedra.tres"),
	preload("res://data/recipes/cubo_captura.tres"),
	preload("res://data/recipes/pocao_cura.tres"),
]


static func todas() -> Array[RecipeDef]:
	return _receitas


static func get_receita(id: String) -> RecipeDef:
	for receita: RecipeDef in _receitas:
		if receita.id == id:
			return receita
	return null
