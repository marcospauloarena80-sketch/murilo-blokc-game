class_name QuestDef
extends Resource
## Definição data-driven de uma missão (F9). Ver docs/01-GDD.md §12 e
## docs/07-DECISOES.md ADR-022.

@export var quest_id: String = ""
@export var nome: String = ""
@export var descricao: String = ""
## "coletar" | "construir" | "derrotar" | "capturar" | "craftar" | "vencer_treinador"
@export var tipo: String = ""
@export var alvo_id: String = ""  ## item_id | block_id (String) | especie_id, conforme o tipo
@export var quantidade_alvo: int = 1
@export var recompensa_receita: String = ""  ## "" = nenhuma; senão id de uma RecipeDef
@export var recompensa_itens: Dictionary = {}  ## item_id -> quantidade
## Espécie dada de presente ao concluir. Sem isso não havia como ganhar o
## primeiro Cubelin: batalha exige ter um, e Cubelin só vinha de captura em
## batalha (dependência circular achada na auditoria, ADR-027).
@export var recompensa_cubelin: String = ""
@export var proxima_quest_id: String = ""  ## "" = fim da cadeia
@export var repetivel: bool = false
@export var npc_id: String = ""  ## quem dá essa missão
## Só fica disponível depois de concluir esta outra missão ("" = sem pré-requisito).
@export var requer_quest: String = ""
