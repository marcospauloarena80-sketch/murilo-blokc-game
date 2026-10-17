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
@export var eh_comida: bool = false
@export var restaura_fome: int = 0
@export var eh_arma: bool = false
@export var dano_ataque: int = 0
@export var eh_pocao: bool = false
@export var cura_pontos: int = 0
@export var pode_arar: bool = false  ## enxada: interagir em grama/terra vira terra arada (Ciclo 8)

## Ciclo 8 (8E): ferramenta certa, tier mínimo e desgaste.
@export var tipo_ferramenta: String = ""  ## "picareta" | "machado" | "enxada" | ""
@export var tier: int = 0  ## 0 a 4: madeira 1, pedra 2, ferrite 3, cristal 4
@export var durabilidade: int = 0  ## usos até quebrar; 0 = infinita
