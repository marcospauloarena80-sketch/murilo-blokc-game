class_name Creature
extends CharacterBody3D
## Cubelin vivo no mundo (F7): corpo único (cubo colorido pelo elemento),
## física simples com colisão real no terreno voxel, sem pathfinding —
## direção crua + move_and_slide (ADR-020). Batalha/captura/XP ficam pra F8.

const GRAVIDADE: float = 9.8
const INTERVALO_DANO_CONTATO_SEG: float = 1.0

var especie: CreatureDef
var vida_atual: int = 0

var _comportamento: CreatureBehavior
var _jogador: Node3D
var _tempo_desde_dano_contato: float = INTERVALO_DANO_CONTATO_SEG

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _hurtbox: Area3D = $Hurtbox


func configurar(def: CreatureDef) -> void:
	especie = def
	vida_atual = def.vida_maxima
	_comportamento = CreatureBehavior.new(def)
	var material := StandardMaterial3D.new()
	material.albedo_color = def.cor
	_mesh.material_override = material


func _ready() -> void:
	add_to_group("creature")
	_jogador = get_tree().get_first_node_in_group("player")
	_hurtbox.body_entered.connect(_ao_tocar_jogador)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta
	else:
		velocity.y = 0.0

	if _jogador != null and _comportamento != null:
		var direcao: Vector3 = _comportamento.atualizar(
			delta, global_position, _jogador.global_position
		)
		velocity.x = direcao.x * especie.velocidade
		velocity.z = direcao.z * especie.velocidade
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	_tempo_desde_dano_contato += delta


func receber_dano(quantidade: int) -> void:
	vida_atual = max(0, vida_atual - quantidade)
	if vida_atual <= 0:
		EventBus.creature_defeated.emit(especie.especie_id)
		queue_free()


func _ao_tocar_jogador(corpo: Node3D) -> void:
	if not corpo.is_in_group("player"):
		return
	if especie == null or not especie.eh_agressivo:
		return
	if _tempo_desde_dano_contato < INTERVALO_DANO_CONTATO_SEG:
		return
	_tempo_desde_dano_contato = 0.0
	GameState.vida_atual = max(0, GameState.vida_atual - especie.dano_contato)
