class_name NpcDef
extends Resource
## Definição data-driven de um NPC (F9). Ver docs/01-GDD.md §12 e
## docs/07-DECISOES.md ADR-022. Aparência humanoide (Ciclo 5, Frente 5A):
## as quatro cores pintam o CorpoBlocos igual ao do jogador.

@export var npc_id: String = ""
@export var nome: String = ""
@export var cor: Color = Color.WHITE  ## cor de destaque (era o cubo da F9)
## professora | refugio | comerciante | construtor | guardiao | treinador
@export var papel: String = ""
@export var cor_pele: Color = Color(0.945, 0.761, 0.49)
@export var cor_cabelo: Color = Color(0.353, 0.22, 0.145)
@export var cor_camisa: Color = Color(0.204, 0.596, 0.859)
@export var cor_calca: Color = Color(0.173, 0.243, 0.314)
@export var linhas_dialogo: PackedStringArray = []
@export var oferece_quest_id: String = ""  ## "" = não oferece missão nenhuma
@export var abre_laboratorio: bool = false  ## Professora Lina (F9)
@export var cura_ao_interagir: bool = false  ## Refúgio (F9)
@export var troca_pede_item: String = ""  ## Comerciante (F9) — "" = não troca
@export var troca_pede_quantidade: int = 0
@export var troca_oferece_item: String = ""
@export var troca_oferece_quantidade: int = 0
@export var abre_arena: String = ""  ## Guardião de Arena (F10) — "" = não é Guardião


func aparencia() -> CharacterAppearance:
	## Mesmo recurso que o jogador usa, pra CorpoBlocos.aplicar_aparencia().
	var resultado := CharacterAppearance.new()
	resultado.cor_pele = cor_pele
	resultado.cor_cabelo = cor_cabelo
	resultado.cor_camisa = cor_camisa
	resultado.cor_calca = cor_calca
	return resultado
