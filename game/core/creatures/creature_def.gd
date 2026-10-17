class_name CreatureDef
extends Resource
## Definição data-driven de uma espécie de Cubelin (F7). Ver docs/01-GDD.md §9
## e docs/07-DECISOES.md ADR-020. Batalha/captura/XP/ataques ficam pra F8 —
## aqui só o necessário pra existir e se comportar no mundo.

@export var especie_id: String = ""
@export var nome: String = ""
@export var descricao: String = ""  ## uma frase curta, mostrada no Caderno (Ciclo 9, 9D)
@export var elemento: String = ""  ## pedra | mato | brasa | gota | vento | faisca
@export var cor: Color = Color.WHITE
## Visual (Ciclo 5, Frente 5B): só muda a caixa desenhada, a colisão fica 0,7³.
## cubo = 0,7³ | achatado = 0,9 x 0,45 x 0,9 | alto = 0,5 x 0,9 x 0,5
@export var formato: String = "cubo"
@export var cor_secundaria: Color = Color.WHITE  ## faixa na base, na cor do elemento
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

## --- Animais (Ciclo 8, Frente 8B): bichos passivos que dão comida ---
@export var eh_animal: bool = false  ## animal não luta nem é capturado: bater dá dano e dropa
@export var drops: Dictionary = {}  ## item_id -> quantidade máxima (sorteia de 1 até ela)
@export var bioma_animal: String = ""  ## bioma onde nasce de dia ("" = qualquer)
