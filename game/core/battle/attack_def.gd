class_name AttackDef
extends Resource
## Definição data-driven de um ataque de Cubelin (F8). Ver docs/01-GDD.md §9/§11
## e docs/07-DECISOES.md ADR-021.

@export var ataque_id: String = ""
@export var nome: String = ""
@export var elemento: String = ""  ## pedra | mato | brasa | gota | vento | faisca
@export var poder: int = 5
@export var custo_energia: int = 0
