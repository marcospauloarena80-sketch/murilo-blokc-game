class_name ItemDef
extends Resource
## Definição data-driven de um item (ADR-008). Ver docs/02-ARQUITETURA.md §4.4.
## Cor é placeholder de ícone até a fase de assets (ADR-009).

@export var id: String = ""
@export var nome: String = ""
@export var stack_maximo: int = 64
@export var cor: Color = Color.WHITE
@export var bloco_id: int = 0
@export var eh_ferramenta: bool = false
@export var multiplicador_velocidade: float = 1.0
