class_name BlockDef
extends Resource
## Definição data-driven de um tipo de bloco (ADR-008). Ver docs/02-ARQUITETURA.md §4.2.
## Desde o Ciclo 4 (ADR-027) o bloco é desenhado com as texturas do AtlasBlocos;
## a cor ficou para partículas, ícones e mapa.

@export var id: int = 0
@export var nome: String = ""
@export var dureza: float = 1.0
@export var drop_id: String = ""
@export var cor: Color = Color.WHITE
@export var solido: bool = true
@export var emite_luz: bool = false
@export var tipo_especial: String = ""  ## "" | "cama" | "bau" — interação especial (F6)
@export var textura_lado: String = ""  ## nome em AtlasBlocos.NOMES
@export var textura_topo: String = ""  ## vazio = mesma do lado
@export var textura_base: String = ""  ## vazio = mesma do topo
@export var brilho: float = 0.0  ## luz própria na textura (0 = nenhuma)
