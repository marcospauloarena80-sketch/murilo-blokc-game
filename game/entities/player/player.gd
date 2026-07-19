class_name Player
extends CharacterBody3D
## Movimento e interação com o mundo do Murilo.
## Ver docs/02-ARQUITETURA.md §4.1/§4.2 e docs/07-DECISOES.md ADR-014/ADR-015.
##
## Física começa pausada e só liga quando o mundo termina de gerar (sinal
## mundo_gerado do ChunkManager). Movimento/quebrar/colocar só respondem no
## estado GameState.PLAYING — durante CHARACTER_CREATION a gravidade continua
## (o personagem se assenta no chão pro preview), mas os controles ficam mudos.

const VELOCIDADE: float = 5.0
const VELOCIDADE_CORRIDA: float = 8.0
const FORCA_PULO: float = 4.5
const GRAVIDADE: float = 9.8
const ALCANCE: float = 5.0
const AMPLITUDE_MAX_BALANCO: float = 0.6
const SEGUNDOS_POR_PONTO_ENERGIA: float = 2.0
const ALTURA_QUEDA_SEGURA: float = 3.0
const INTERVALO_ATAQUE_SEG: float = 0.5
const DANO_MAO_NUA: int = 1

var _chunk_manager: ChunkManager
var _outline: MeshInstance3D
var _progresso_quebra: float = 0.0
var _bloco_em_quebra: Vector3i = Vector3i(0, -999, 0)
var _fase_balanco: float = 0.0
var _tempo_energia: float = 0.0
var _estava_no_ar: bool = false
var _y_inicio_queda: float = 0.0
var _tempo_desde_ataque: float = INTERVALO_ATAQUE_SEG

var _mat_pele: StandardMaterial3D
var _mat_cabelo: StandardMaterial3D
var _mat_camisa: StandardMaterial3D
var _mat_calca: StandardMaterial3D

@onready var camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var _ombro_esquerdo: Node3D = $Corpo/OmbroEsquerdo
@onready var _ombro_direito: Node3D = $Corpo/OmbroDireito
@onready var _quadril_esquerdo: Node3D = $Corpo/QuadrilEsquerdo
@onready var _quadril_direito: Node3D = $Corpo/QuadrilDireito


func _ready() -> void:
	add_to_group("player")
	_configurar_materiais()
	aplicar_aparencia(GameState.aparencia_atual)

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


func _configurar_materiais() -> void:
	_mat_pele = StandardMaterial3D.new()
	_mat_cabelo = StandardMaterial3D.new()
	_mat_camisa = StandardMaterial3D.new()
	_mat_calca = StandardMaterial3D.new()

	$Corpo/Cabeca.material_override = _mat_pele
	$Corpo/OmbroEsquerdo/BracoEsquerdo.material_override = _mat_pele
	$Corpo/OmbroDireito/BracoDireito.material_override = _mat_pele
	$Corpo/Cabelo.material_override = _mat_cabelo
	$Corpo/Tronco.material_override = _mat_camisa
	$Corpo/QuadrilEsquerdo/PernaEsquerda.material_override = _mat_calca
	$Corpo/QuadrilDireito/PernaDireita.material_override = _mat_calca


func aplicar_aparencia(aparencia: CharacterAppearance) -> void:
	_mat_pele.albedo_color = aparencia.cor_pele
	_mat_cabelo.albedo_color = aparencia.cor_cabelo
	_mat_camisa.albedo_color = aparencia.cor_camisa
	_mat_calca.albedo_color = aparencia.cor_calca


func _ao_mundo_pronto() -> void:
	if GameState.veio_de_continuar:
		global_position = GameState.posicao_salva
		velocity = Vector3.ZERO
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
		if not _estava_no_ar:
			_estava_no_ar = true
			_y_inicio_queda = global_position.y
	elif _estava_no_ar:
		_estava_no_ar = false
		if GameState.current_state == GameState.State.PLAYING:
			_aplicar_dano_de_queda(_y_inicio_queda - global_position.y)

	var jogando := GameState.current_state == GameState.State.PLAYING

	if jogando:
		if Input.is_action_just_pressed("pular") and is_on_floor():
			velocity.y = FORCA_PULO

		var input_dir := Input.get_vector(
			"mover_esquerda", "mover_direita", "mover_frente", "mover_tras"
		)
		var direcao := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var esta_correndo := (
			Input.is_action_pressed("correr")
			and direcao != Vector3.ZERO
			and GameState.energia_atual > 0
		)
		var velocidade_atual := VELOCIDADE_CORRIDA if esta_correndo else VELOCIDADE
		_atualizar_energia(delta, esta_correndo)

		if direcao:
			velocity.x = direcao.x * velocidade_atual
			velocity.z = direcao.z * velocidade_atual
		else:
			velocity.x = move_toward(velocity.x, 0, velocidade_atual)
			velocity.z = move_toward(velocity.z, 0, velocidade_atual)
	else:
		velocity.x = move_toward(velocity.x, 0, VELOCIDADE)
		velocity.z = move_toward(velocity.z, 0, VELOCIDADE)

	move_and_slide()
	_animar_membros(delta)

	if jogando:
		_processar_selecao_de_bloco()
		_processar_mira_e_interacao(delta)
		if Input.is_action_just_pressed("comer"):
			_tentar_comer()
	elif _outline:
		_outline.visible = false


func _animar_membros(delta: float) -> void:
	var velocidade_horizontal := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and velocidade_horizontal > 0.1:
		_fase_balanco += delta * velocidade_horizontal * 3.0
	var fator: float = clamp(velocidade_horizontal / VELOCIDADE_CORRIDA, 0.0, 1.0)
	var amplitude: float = fator * AMPLITUDE_MAX_BALANCO
	var angulo: float = sin(_fase_balanco) * amplitude
	_ombro_esquerdo.rotation.x = angulo
	_ombro_direito.rotation.x = -angulo
	_quadril_esquerdo.rotation.x = -angulo
	_quadril_direito.rotation.x = angulo


func _processar_selecao_de_bloco() -> void:
	for i in range(1, 9):
		if Input.is_action_just_pressed("hotbar_%d" % i):
			GameState.hotbar_selecionado = i - 1


func _aplicar_dano_de_queda(altura_queda: float) -> void:
	var excesso: float = altura_queda - ALTURA_QUEDA_SEGURA
	if excesso <= 0.0:
		return
	GameState.vida_atual = max(0, GameState.vida_atual - int(floor(excesso)))


func _atualizar_energia(delta: float, esta_correndo: bool) -> void:
	_tempo_energia += delta
	if _tempo_energia < SEGUNDOS_POR_PONTO_ENERGIA:
		return
	_tempo_energia = 0.0
	if esta_correndo:
		GameState.energia_atual = max(0, GameState.energia_atual - 1)
	else:
		GameState.energia_atual = min(GameState.energia_maxima, GameState.energia_atual + 1)


func _tentar_comer() -> void:
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	if item_id == "":
		return
	var def := ItemRegistry.get_item(item_id)
	if def == null or not def.eh_comida:
		return
	if GameState.fome_atual >= GameState.fome_maxima:
		return
	if not GameState.inventario_hotbar.remover(item_id, 1):
		return
	GameState.fome_atual = min(GameState.fome_maxima, GameState.fome_atual + def.restaura_fome)


func _multiplicador_ferramenta_atual() -> float:
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	if item_id == "":
		return 1.0
	var def := ItemRegistry.get_item(item_id)
	if def == null or not def.eh_ferramenta:
		return 1.0
	return def.multiplicador_velocidade


func _raycast_mira() -> Dictionary:
	if _chunk_manager == null:
		return {}
	var origem := _camera.global_transform.origin
	var direcao := -_camera.global_transform.basis.z
	var destino := origem + direcao * ALCANCE
	var espaco := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origem, destino)
	return espaco.intersect_ray(query)


func _dano_de_ataque_atual() -> int:
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	if item_id == "":
		return DANO_MAO_NUA
	var def := ItemRegistry.get_item(item_id)
	if def == null or not def.eh_arma:
		return DANO_MAO_NUA
	return def.dano_ataque


func _processar_mira_e_interacao(delta: float) -> void:
	_tempo_desde_ataque += delta

	var resultado := _raycast_mira()
	if resultado.is_empty():
		_outline.visible = false
		_progresso_quebra = 0.0
		return

	var colisor: Node = resultado.get("collider")
	if colisor != null and colisor.is_in_group("creature"):
		_outline.visible = false
		_progresso_quebra = 0.0
		if Input.is_action_just_pressed("quebrar") and _tempo_desde_ataque >= INTERVALO_ATAQUE_SEG:
			_tempo_desde_ataque = 0.0
			(colisor as Creature).receber_dano(_dano_de_ataque_atual())
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
			_progresso_quebra += delta * _multiplicador_ferramenta_atual()
			if _progresso_quebra >= def.dureza:
				_chunk_manager.set_block(bloco_mirado, BlockRegistry.AR_ID)
				_progresso_quebra = 0.0
	else:
		_progresso_quebra = 0.0

	if Input.is_action_just_pressed("colocar"):
		var adjacente := bloco_mirado + Vector3i(normal.round())
		if _chunk_manager.get_block(adjacente) == BlockRegistry.AR_ID:
			_tentar_colocar_bloco(adjacente)

	if Input.is_action_just_pressed("interagir"):
		_processar_interacao(bloco_mirado)


func _processar_interacao(bloco_mirado: Vector3i) -> void:
	var id_alvo := _chunk_manager.get_block(bloco_mirado)
	var def := BlockRegistry.get_block(id_alvo)
	if def == null:
		return
	if def.tipo_especial == "cama":
		GameState.ponto_respawn = Vector3(bloco_mirado) + Vector3(0.5, 1.0, 0.5)
	elif def.tipo_especial == "bau":
		EventBus.chest_requested.emit(GameState.chave_posicao(bloco_mirado))


func _tentar_colocar_bloco(adjacente: Vector3i) -> void:
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	if item_id == "":
		return
	var def := ItemRegistry.get_item(item_id)
	if def == null or def.bloco_id == BlockRegistry.AR_ID:
		return
	if not GameState.inventario_hotbar.remover(item_id, 1):
		return
	_chunk_manager.set_block(adjacente, def.bloco_id)
