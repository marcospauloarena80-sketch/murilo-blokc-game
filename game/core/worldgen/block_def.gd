class_name BlockDef
extends Resource
## Definição data-driven de um tipo de bloco (ADR-008). Ver docs/02-ARQUITETURA.md §4.2.
## Cor é placeholder até a fase de assets (atlas de textura entra na F11/F3+ conforme ADR-009).

@export var id: int = 0
@export var nome: String = ""
@export var dureza: float = 1.0
@export var drop_id: String = ""
@export var cor: Color = Color.WHITE
@export var solido: bool = true
