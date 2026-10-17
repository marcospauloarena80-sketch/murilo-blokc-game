class_name Npc
extends StaticBody3D
## NPC estacionário (F9) com corpo de blocos humanoide (Ciclo 5, Frente 5A):
## rosto, placa de nome acima da cabeça, "!" enquanto tem missão disponível e
## giro devagar pra olhar o jogador quando ele chega perto. Existe como
## obstáculo, sem física própria — interação via "interagir" abre diálogo.
## Ver docs/01-GDD.md §12 e docs/07-DECISOES.md ADR-022.

const DISTANCIA_OLHAR: float = 6.0
const VELOCIDADE_GIRO: float = 3.0  ## rad/s
const INTERVALO_MARCADOR_SEG: float = 0.5
## Pés em y=0, Corpo em 0,95: topo do cabelo fica em ~2,07.
const ALTURA_PLACA: float = 2.3
const ALTURA_MARCADOR: float = 2.7
const ALCANCE_PLACA: float = 24.0
const COR_MARCADOR := Color(1.0, 0.85, 0.1)
## Faixa do guardião por elemento da arena ("" = Coração Dourado).
const CORES_ELEMENTO: Dictionary[String, Color] = {
	"pedra": Color(0.45, 0.42, 0.4),
	"mato": Color(0.3, 0.7, 0.25),
	"brasa": Color(0.95, 0.45, 0.2),
	"gota": Color(0.3, 0.55, 0.85),
	"vento": Color(0.75, 0.85, 0.9),
	"faisca": Color(0.95, 0.85, 0.2),
	"": Color(0.95, 0.8, 0.25),
}

@export var npc_id_inicial: String = ""  ## preenchido na cena — auto-configura em _ready()

var def: NpcDef

var _jogador: Node3D
var _tempo_marcador: float = INTERVALO_MARCADOR_SEG
var _placa: Label3D
var _marcador: Label3D


func configurar(npc_def: NpcDef) -> void:
	def = npc_def
	## $Corpo direto (não @onready): o configurar pode vir antes do add_child.
	var corpo := $Corpo as CorpoBlocos
	corpo.aplicar_aparencia(def.aparencia())
	if def.abre_arena != "":
		corpo.definir_faixa(cor_do_elemento_da_arena(def.abre_arena))
	_criar_placas()
	_atualizar_marcador()


func _ready() -> void:
	add_to_group("npc")
	if npc_id_inicial != "":
		configurar(NpcRegistry.get_npc(npc_id_inicial))


func _process(delta: float) -> void:
	_tempo_marcador += delta
	if _tempo_marcador >= INTERVALO_MARCADOR_SEG:
		_tempo_marcador = 0.0
		_atualizar_marcador()
		if not is_instance_valid(_jogador):
			_jogador = get_tree().get_first_node_in_group("player") as Node3D
	_olhar_para_o_jogador(delta)


static func cor_do_elemento_da_arena(arena_id: String) -> Color:
	var arena := ArenaRegistry.get_arena(arena_id)
	var elemento := arena.elemento if arena != null else ""
	if CORES_ELEMENTO.has(elemento):
		return CORES_ELEMENTO[elemento]
	return CORES_ELEMENTO[""]


func _criar_placas() -> void:
	if _placa == null:
		_placa = _criar_label("Placa", 30, Color.WHITE, ALTURA_PLACA)
		add_child(_placa)
	_placa.text = def.nome
	if _marcador == null:
		_marcador = _criar_label("Marcador", 64, COR_MARCADOR, ALTURA_MARCADOR)
		_marcador.text = "!"
		add_child(_marcador)


func _criar_label(nome: String, tamanho: int, cor: Color, altura: float) -> Label3D:
	var label := Label3D.new()
	label.name = nome
	label.font_size = tamanho
	label.modulate = cor
	label.outline_size = 12
	label.outline_modulate = Color.BLACK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.visibility_range_end = ALCANCE_PLACA
	label.position = Vector3(0.0, altura, 0.0)
	return label


func _atualizar_marcador() -> void:
	## "!" só enquanto a missão oferecida não está ativa nem concluída.
	if _marcador == null or def == null:
		return
	_marcador.visible = (
		def.oferece_quest_id != ""
		and GameState.quest_atual_id != def.oferece_quest_id
		and not GameState.quests_concluidas.has(def.oferece_quest_id)
		and QuestRegistry.liberada(def.oferece_quest_id)
	)


func _olhar_para_o_jogador(delta: float) -> void:
	if not is_instance_valid(_jogador):
		return
	var para_jogador := _jogador.global_position - global_position
	para_jogador.y = 0.0
	var distancia := para_jogador.length()
	if distancia > DISTANCIA_OLHAR or distancia < 0.01:
		return
	## A frente do corpo é -Z: ângulo em Y que leva -Z até o jogador.
	var alvo := atan2(-para_jogador.x, -para_jogador.z)
	rotation.y = lerp_angle(rotation.y, alvo, minf(1.0, VELOCIDADE_GIRO * delta))
