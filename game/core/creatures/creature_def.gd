class_name CreatureDef
extends Resource
## Definição data-driven de uma espécie de Cubelin (F7). Ver docs/01-GDD.md §9
## e docs/07-DECISOES.md ADR-020. Batalha/captura/XP/ataques ficam pra F8 —
## aqui só o necessário pra existir e se comportar no mundo.

@export var especie_id: String = ""
@export var nome: String = ""
@export var elemento: String = ""  ## pedra | mato | brasa | gota | vento | faisca
@export var cor: Color = Color.WHITE
@export var vida_maxima: int = 10
@export var velocidade: float = 2.0
@export var raio_deteccao: float = 6.0
@export var eh_agressivo: bool = false
@export var dano_contato: int = 1
@export var periodo_spawn: String = "dia"  ## "dia" | "noite"
