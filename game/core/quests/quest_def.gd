class_name QuestDef
extends Resource
## Definição data-driven de uma missão (F9). Ver docs/01-GDD.md §12 e
## docs/07-DECISOES.md ADR-022.

@export var quest_id: String = ""
@export var nome: String = ""
@export var descricao: String = ""
@export var tipo: String = ""  ## "coletar" | "construir" | "derrotar" | "capturar"
@export var alvo_id: String = ""  ## item_id | block_id (String) | especie_id, conforme o tipo
@export var quantidade_alvo: int = 1
@export var recompensa_receita: String = ""  ## "" = nenhuma; senão id de uma RecipeDef
@export var recompensa_itens: Dictionary = {}  ## item_id -> quantidade
@export var proxima_quest_id: String = ""  ## "" = fim da cadeia
@export var repetivel: bool = false
@export var npc_id: String = ""  ## quem dá essa missão
