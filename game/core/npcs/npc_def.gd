class_name NpcDef
extends Resource
## Definição data-driven de um NPC (F9). Ver docs/01-GDD.md §12 e
## docs/07-DECISOES.md ADR-022.

@export var npc_id: String = ""
@export var nome: String = ""
@export var cor: Color = Color.WHITE
@export var linhas_dialogo: PackedStringArray = []
@export var oferece_quest_id: String = ""  ## "" = não oferece missão nenhuma
@export var abre_laboratorio: bool = false  ## Professora Lina (F9)
@export var cura_ao_interagir: bool = false  ## Refúgio (F9)
@export var troca_pede_item: String = ""  ## Comerciante (F9) — "" = não troca
@export var troca_pede_quantidade: int = 0
@export var troca_oferece_item: String = ""
@export var troca_oferece_quantidade: int = 0
@export var abre_arena: String = ""  ## Guardião de Arena (F10) — "" = não é Guardião
