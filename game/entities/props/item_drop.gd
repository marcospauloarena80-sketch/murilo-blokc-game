class_name ItemDrop
extends Area3D
## Item físico dropado ao quebrar bloco. Flutua, gira, atrai pro player
## dentro do raio de ímã, coleta em contato. Ver docs/02-ARQUITETURA.md §4.4.

const RAIO_IMA: float = 3.0
const VELOCIDADE_IMA: float = 6.0
const TEMPO_DE_VIDA: float = 300.0
## Item cai até repousar sobre um bloco sólido. Antes ele flutuava onde o bloco
## estava: tronco alto deixava o item fora do alcance do ímã (achado jogando,
## ADR-027).
const VELOCIDADE_QUEDA: float = 6.0
const MEIA_ALTURA: float = 0.55
const Y_MINIMO: float = -10.0

var item_id: String = ""
var quantidade: int = 1

var _tempo_vivo: float = 0.0
var _jogador: Node3D = null
var _chunk_manager: ChunkManager = null

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	body_entered.connect(_ao_tocar_corpo)
	_jogador = get_tree().get_first_node_in_group("player")
	_chunk_manager = get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	var def := ItemRegistry.get_item(item_id)
	if def != null:
		var material := StandardMaterial3D.new()
		material.albedo_color = def.cor
		_mesh.material_override = material


func _process(delta: float) -> void:
	_tempo_vivo += delta
	if _tempo_vivo >= TEMPO_DE_VIDA:
		queue_free()
		return

	rotation.y += delta * 1.5
	_cair(delta)

	if _jogador != null:
		var distancia: float = global_position.distance_to(_jogador.global_position)
		if distancia <= RAIO_IMA and distancia > 0.05:
			var direcao: Vector3 = (_jogador.global_position - global_position).normalized()
			global_position += direcao * VELOCIDADE_IMA * delta


func _ao_tocar_corpo(corpo: Node3D) -> void:
	if not corpo.is_in_group("player"):
		return
	var sobra: int = GameState.adicionar_item(item_id, quantidade)
	var coletado: int = quantidade - sobra
	if coletado > 0:
		EventBus.item_collected.emit(item_id, coletado)
	if sobra <= 0:
		queue_free()
	else:
		quantidade = sobra


func _cair(delta: float) -> void:
	if _chunk_manager == null:
		return
	if global_position.y < Y_MINIMO:
		queue_free()
		return
	var abaixo := Vector3i((global_position - Vector3(0, MEIA_ALTURA, 0)).floor())
	if not BlockRegistry.e_solido(_chunk_manager.get_block(abaixo)):
		global_position.y -= VELOCIDADE_QUEDA * delta
