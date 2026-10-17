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
## Ciclo 8 (frente 8A): blocos em cruz e plantas que crescem.
@export var forma: String = "cubo"  ## "cubo" | "cruz" (dois planos cruzados, sem colisão)
@export var oclui: bool = true  ## false: não esconde a face dos vizinhos
@export var altura_cruz: float = 0.9  ## altura dos planos da forma "cruz"
@export var cresce_para: int = 0  ## id do próximo estágio (0 = não cresce)
@export var tempo_crescimento_seg: float = 0.0
## ids aceitos no bloco de baixo (vazio = qualquer)
@export var chao_exigido: PackedInt32Array = PackedInt32Array()
@export var drop_extra_id: String = ""  ## segundo drop, sorteado
@export var drop_extra_chance: float = 0.0
@export var drop_extra_min: int = 1
@export var drop_extra_max: int = 1

## Frente 8C (Ciclo 8): blocos de construção.
@export var forma: String = "cubo"  ## "cubo" | "vidro" | "laje" | "escada" | "porta" | "cerca"
@export var transparente: bool = false  ## vidro: não oclui e a textura tem furos (discard)

## Ciclo 8 (8E): ferramenta que acelera a quebra e tier mínimo para quebrar.
@export var ferramenta_ideal: String = ""  ## "" | "picareta" | "machado"
@export var tier_minimo: int = 0  ## 0 = quebra na mão
