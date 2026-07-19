class_name NpcRegistry
extends RefCounted
## Registro estático dos NpcDef por npc_id (String). Ver docs/02-ARQUITETURA.md §4.2.
## Não é autoload (ADR: máximo 5) — acesso via métodos estáticos. Conteúdo
## real (Lina/Refúgio/Comerciante/Construtor) entra na F9 tarefa de NPCs.

static var _npcs: Dictionary = {
	"lina": preload("res://data/npcs/lina.tres"),
	"refugio": preload("res://data/npcs/refugio.tres"),
	"comerciante": preload("res://data/npcs/comerciante.tres"),
	"construtor": preload("res://data/npcs/construtor.tres"),
	"guardiao_pedra": preload("res://data/npcs/guardiao_pedra.tres"),
	"guardiao_brasa": preload("res://data/npcs/guardiao_brasa.tres"),
	"guardiao_gota": preload("res://data/npcs/guardiao_gota.tres"),
	"guardiao_faisca": preload("res://data/npcs/guardiao_faisca.tres"),
	"guardiao_final": preload("res://data/npcs/guardiao_final.tres"),
}


static func get_npc(npc_id: String) -> NpcDef:
	return _npcs.get(npc_id, null)


static func todos_os_ids() -> Array:
	return _npcs.keys()
