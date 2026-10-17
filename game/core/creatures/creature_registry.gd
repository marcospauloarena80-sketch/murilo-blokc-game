class_name CreatureRegistry
extends RefCounted
## Registro estático dos CreatureDef por especie_id (String). Ver docs/02-ARQUITETURA.md §4.2.
## Não é autoload (ADR: máximo 5) — acesso via métodos estáticos.

static var _criaturas: Dictionary = {
	"brotinho": preload("res://data/creatures/brotinho.tres"),
	"ventim": preload("res://data/creatures/ventim.tres"),
	"pedrolim": preload("res://data/creatures/pedrolim.tres"),
	"faiscolt": preload("res://data/creatures/faiscolt.tres"),
	"pedrargo": preload("res://data/creatures/pedrargo.tres"),
	"faiscozap": preload("res://data/creatures/faiscozap.tres"),
	"brasita": preload("res://data/creatures/brasita.tres"),
	"gotelo": preload("res://data/creatures/gotelo.tres"),
	"rochedo": preload("res://data/creatures/rochedo.tres"),
	"centelha": preload("res://data/creatures/centelha.tres"),
	"folhaz": preload("res://data/creatures/folhaz.tres"),
	"folharaiz": preload("res://data/creatures/folharaiz.tres"),
	"brisim": preload("res://data/creatures/brisim.tres"),
	"brisura": preload("res://data/creatures/brisura.tres"),
	"chamote": preload("res://data/creatures/chamote.tres"),
	"chamarao": preload("res://data/creatures/chamarao.tres"),
	"maruja": preload("res://data/creatures/maruja.tres"),
	"marejao": preload("res://data/creatures/marejao.tres"),
}

## Animais (Ciclo 8, 8B) ficam à parte: não são Cubelins (sem batalha nem
## captura), então não entram em todos_os_ids().
static var _animais: Dictionary = {
	"lanugo": preload("res://data/creatures/lanugo.tres"),
	"saltitao": preload("res://data/creatures/saltitao.tres"),
}


static func get_creature(especie_id: String) -> CreatureDef:
	if _criaturas.has(especie_id):
		return _criaturas[especie_id]
	return _animais.get(especie_id, null)


static func ids_animais() -> Array:
	return _animais.keys()


static func todos_os_ids() -> Array:
	return _criaturas.keys()
