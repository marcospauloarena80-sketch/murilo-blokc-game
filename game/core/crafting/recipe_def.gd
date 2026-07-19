class_name RecipeDef
extends Resource
## Definição data-driven de uma receita (ADR-008/ADR-012 — lista, sem grid).
## Ver docs/02-ARQUITETURA.md §4.5.

@export var id: String = ""
@export var nome: String = ""
@export var ingredientes: Dictionary = {}
@export var resultado_id: String = ""
@export var resultado_quantidade: int = 1
@export var exige_bancada: bool = false
