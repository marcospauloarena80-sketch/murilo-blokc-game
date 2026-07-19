class_name ItemDrop
extends Area3D
## Item físico dropado ao quebrar bloco. Flutua, gira, atrai pro player
## dentro do raio de ímã, coleta em contato. Ver docs/02-ARQUITETURA.md §4.4.

const RAIO_IMA: float = 3.0
const VELOCIDADE_IMA: float = 6.0
const TEMPO_DE_VIDA: float = 300.0

var item_id: String = ""
var quantidade: int = 1

var _tempo_vivo: float = 0.0
var _jogador: Node3D = null

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	body_entered.connect(_ao_tocar_corpo)
	_jogador = get_tree().get_first_node_in_group("player")
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
