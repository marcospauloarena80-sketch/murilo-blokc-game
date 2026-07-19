class_name AttackRegistry
extends RefCounted
## Registro estático dos AttackDef por ataque_id (String). Ver docs/02-ARQUITETURA.md §4.2.
## Não é autoload (ADR: máximo 5) — acesso via métodos estáticos.

static var _ataques: Dictionary = {
	"pedra_investida": preload("res://data/attacks/pedra_investida.tres"),
	"pedra_avalanche": preload("res://data/attacks/pedra_avalanche.tres"),
	"mato_investida": preload("res://data/attacks/mato_investida.tres"),
	"mato_raizes": preload("res://data/attacks/mato_raizes.tres"),
	"brasa_labareda": preload("res://data/attacks/brasa_labareda.tres"),
	"brasa_combustao": preload("res://data/attacks/brasa_combustao.tres"),
	"gota_respingo": preload("res://data/attacks/gota_respingo.tres"),
	"gota_mare": preload("res://data/attacks/gota_mare.tres"),
	"vento_rajada": preload("res://data/attacks/vento_rajada.tres"),
	"vento_vendaval": preload("res://data/attacks/vento_vendaval.tres"),
	"faisca_choque": preload("res://data/attacks/faisca_choque.tres"),
	"faisca_sobrecarga": preload("res://data/attacks/faisca_sobrecarga.tres"),
}


static func get_ataque(ataque_id: String) -> AttackDef:
	return _ataques.get(ataque_id, null)


static func todos_os_ids() -> Array:
	return _ataques.keys()
