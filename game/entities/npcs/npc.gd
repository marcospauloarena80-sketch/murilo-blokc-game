class_name Npc
extends StaticBody3D
## NPC estacionário (F9): corpo único (cubo colorido), sem física própria
## além de existir como obstáculo — interação via "interagir" abre diálogo.
## Ver docs/01-GDD.md §12 e docs/07-DECISOES.md ADR-022.

@export var npc_id_inicial: String = ""  ## preenchido na cena — auto-configura em _ready()

var def: NpcDef

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func configurar(npc_def: NpcDef) -> void:
	def = npc_def
	var material := StandardMaterial3D.new()
	material.albedo_color = def.cor
	_mesh.material_override = material


func _ready() -> void:
	add_to_group("npc")
	if npc_id_inicial != "":
		configurar(NpcRegistry.get_npc(npc_id_inicial))
