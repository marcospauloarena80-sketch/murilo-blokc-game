extends CharacterBody3D
## Movimento e interação com o mundo do Murilo (F1: movimento; F2: mirar/quebrar/colocar).
## Ver docs/02-ARQUITETURA.md §4.1 e §4.2.
##
## Física começa pausada e só liga quando o mundo termina de gerar (sinal
## mundo_gerado do ChunkManager). Sem isso, o player pode cair mais rápido do
## que o meshing time-sliced consegue construir a colisão do próprio chunk
## e atravessar o chão (bug real encontrado e corrigido nesta fase).

const VELOCIDADE: float = 5.0
const VELOCIDADE_CORRIDA: float = 8.0
const FORCA_PULO: float = 4.5
const GRAVIDADE: float = 9.8
const ALCANCE: float = 5.0

var _chunk_manager: ChunkManager
var _outline: MeshInstance3D
var _bloco_a_colocar: int = 3
var _progresso_quebra: float = 0.0
var _bloco_em_quebra: Vector3i = Vector3i(0, -999, 0)

@onready var camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D


func _ready() -> void:
	_outline = _criar_outline()
	add_child(_outline)
	_outline.visible = false

	set_physics_process(false)
	_chunk_manager = get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	if _chunk_manager == null:
		return
	if _chunk_manager.tem_chunks_pendentes():
		_chunk_manager.mundo_gerado.connect(_ao_mundo_pronto)
	else:
		_ao_mundo_pronto()


func _ao_mundo_pronto() -> void:
	set_physics_process(true)


func _criar_outline() -> MeshInstance3D:
	var no := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(1.02, 1.02, 1.02)
	no.mesh = caixa
	no.top_level = true
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.25)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	no.material_override = material
	return no


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta

	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = FORCA_PULO

	var input_dir := Input.get_vector(
		"mover_esquerda", "mover_direita", "mover_frente", "mover_tras"
	)
	var direcao := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var velocidade_atual := VELOCIDADE_CORRIDA if Input.is_action_pressed("correr") else VELOCIDADE

	if direcao:
		velocity.x = direcao.x * velocidade_atual
		velocity.z = direcao.z * velocidade_atual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidade_atual)
		velocity.z = move_toward(velocity.z, 0, velocidade_atual)

	move_and_slide()
	_processar_selecao_de_bloco()
	_processar_mira_e_interacao(delta)


func _processar_selecao_de_bloco() -> void:
	for i in range(1, 7):
		if Input.is_action_just_pressed("hotbar_%d" % i):
			_bloco_a_colocar = i


func _raycast_mira() -> Dictionary:
	if _chunk_manager == null:
		return {}
	var origem := _camera.global_transform.origin
	var direcao := -_camera.global_transform.basis.z
	var destino := origem + direcao * ALCANCE
	var espaco := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origem, destino)
	return espaco.intersect_ray(query)


func _processar_mira_e_interacao(delta: float) -> void:
	var resultado := _raycast_mira()
	if resultado.is_empty():
		_outline.visible = false
		_progresso_quebra = 0.0
		return

	var normal: Vector3 = resultado["normal"]
	var ponto_dentro: Vector3 = resultado["position"] - normal * 0.5
	var bloco_mirado := Vector3i(
		floori(ponto_dentro.x), floori(ponto_dentro.y), floori(ponto_dentro.z)
	)

	_outline.visible = true
	_outline.global_position = Vector3(bloco_mirado) + Vector3(0.5, 0.5, 0.5)

	if bloco_mirado != _bloco_em_quebra:
		_bloco_em_quebra = bloco_mirado
		_progresso_quebra = 0.0

	if Input.is_action_pressed("quebrar"):
		var id_alvo := _chunk_manager.get_block(bloco_mirado)
		var def := BlockRegistry.get_block(id_alvo)
		if def != null:
			_progresso_quebra += delta
			if _progresso_quebra >= def.dureza:
				_chunk_manager.set_block(bloco_mirado, BlockRegistry.AR_ID)
				_progresso_quebra = 0.0
	else:
		_progresso_quebra = 0.0

	if Input.is_action_just_pressed("colocar"):
		var adjacente := bloco_mirado + Vector3i(normal.round())
		if _chunk_manager.get_block(adjacente) == BlockRegistry.AR_ID:
			_chunk_manager.set_block(adjacente, _bloco_a_colocar)
