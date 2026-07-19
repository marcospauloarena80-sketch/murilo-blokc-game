class_name QuestRegistry
extends RefCounted
## Registro estático das QuestDef por quest_id (String). Ver docs/02-ARQUITETURA.md §4.2.
## Não é autoload (ADR: máximo 5) — acesso via métodos estáticos. Conteúdo real
## (cadeia principal + repetíveis) entra na F9 tarefa de conteúdo.

static var _quests: Dictionary = {
	"quest_01_boas_vindas": preload("res://data/quests/quest_01_boas_vindas.tres"),
	"quest_02_madeira_util": preload("res://data/quests/quest_02_madeira_util.tres"),
	"quest_03_primeira_ferramenta": preload("res://data/quests/quest_03_primeira_ferramenta.tres"),
	"quest_04_mineracao": preload("res://data/quests/quest_04_mineracao.tres"),
	"quest_05_tutorial_de_combate": preload("res://data/quests/quest_05_tutorial_de_combate.tres"),
	"quest_06_primeira_captura": preload("res://data/quests/quest_06_primeira_captura.tres"),
	"quest_07_abrigo": preload("res://data/quests/quest_07_abrigo.tres"),
	"quest_08_ferramentas_de_pedra":
	preload("res://data/quests/quest_08_ferramentas_de_pedra.tres"),
	"quest_r1_coleta_diaria": preload("res://data/quests/quest_r1_coleta_diaria.tres"),
	"quest_r2_pedreiro": preload("res://data/quests/quest_r2_pedreiro.tres"),
	"quest_r3_cacador": preload("res://data/quests/quest_r3_cacador.tres"),
	"quest_r4_capturador": preload("res://data/quests/quest_r4_capturador.tres"),
}


static func get_quest(quest_id: String) -> QuestDef:
	return _quests.get(quest_id, null)


static func todos_os_ids() -> Array:
	return _quests.keys()
