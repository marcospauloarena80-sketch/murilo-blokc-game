class_name CreatureDef
extends Resource
## Definição data-driven de uma espécie de Cubelin (F7). Ver docs/01-GDD.md §9
## e docs/07-DECISOES.md ADR-020. Batalha/captura/XP/ataques ficam pra F8 —
## aqui só o necessário pra existir e se comportar no mundo.

@export var especie_id: String = ""
@export var nome: String = ""
@export var elemento: String = ""  ## pedra | mato | brasa | gota | vento | faisca
@export var cor: Color = Color.WHITE
@export var vida_maxima: int = 10  ## também é o Vigor da F8 (docs/01-GDD.md §9)
@export var velocidade: float = 2.0
@export var raio_deteccao: float = 6.0
@export var eh_agressivo: bool = false
@export var dano_contato: int = 1
@export var periodo_spawn: String = "dia"  ## "dia" | "noite"
@export var pode_ser_selvagem: bool = true  ## false pras formas evoluídas (F8)

## --- Batalha (F8) — ver docs/07-DECISOES.md ADR-021 ---
@export var forca: int = 5
@export var guarda: int = 5
@export var agilidade: int = 5
@export var energia_maxima: int = 10
@export var aprendizado_ataques: Dictionary = {}  ## nivel(int) -> ataque_id(String)
@export var nivel_evolucao: int = 0  ## 0 = não evolui
@export var especie_evolucao: String = ""
