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
}


static func get_npc(npc_id: String) -> NpcDef:
	return _npcs.get(npc_id, null)


static func todos_os_ids() -> Array:
	return _npcs.keys()
