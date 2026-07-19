class_name BiomeDef
extends Resource
## Definição data-driven de um bioma (F11). Ver docs/01-GDD.md §3 e
## docs/07-DECISOES.md ADR-024.

@export var bioma_id: String = ""
@export var nome: String = ""
@export var elementos_cubelin: PackedStringArray = []  ## quais elementos de Cubelin spawnam aqui
@export var cor_ambiente: Color = Color.WHITE  ## tinge a luz ambiente (polimento visual)
