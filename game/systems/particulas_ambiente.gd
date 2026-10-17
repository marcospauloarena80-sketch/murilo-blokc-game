class_name ParticulasAmbiente
extends Node3D
## Partículas de vida (Ciclo 5, Frente 5C): pólen de dia e vagalumes de noite,
## acompanhando o jogador 2 blocos acima. Puramente cosmético — só escuta
## EventBus e lê GameState/ChunkManager, sem lógica de mundo (mesmo padrão de
## BlockBreakParticles/WeatherSystem). Dentro da água nada emite.

const ALTURA_ACIMA_DO_JOGADOR: float = 2.0
const EXTENSAO_CAIXA: Vector3 = Vector3(12, 3, 12)  ## caixa de 24 x 6 x 24 blocos
const QUANTIDADE_POLEN: int = 24
const QUANTIDADE_VAGALUMES: int = 16
const COR_POLEN: Color = Color(1.0, 0.95, 0.6, 0.85)
const COR_VAGALUME: Color = Color(0.75, 1.0, 0.35)

var _polen: GPUParticles3D
var _vagalumes: GPUParticles3D
var _jogador: Node3D
var _chunk_manager: ChunkManager
var _noite: bool = false
var _na_agua: bool = false


func _ready() -> void:
	_polen = _criar_polen()
	_polen.name = "Polen"
	add_child(_polen)
	_vagalumes = _criar_vagalumes()
	_vagalumes.name = "Vagalumes"
	add_child(_vagalumes)
	_noite = GameState.eh_noite()
	_atualizar_emissao()
	EventBus.day_started.connect(_ao_comecar_dia)
	EventBus.night_started.connect(_ao_comecar_noite)


func _criar_base(quantidade: int, vida: float, tamanho: float) -> GPUParticles3D:
	var particulas := GPUParticles3D.new()
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = EXTENSAO_CAIXA
	material.spread = 180.0
	material.gravity = Vector3.ZERO
	particulas.process_material = material
	## Quad virado pra câmera e sem sombreamento: pontinhos que não somem na sombra.
	var desenho := StandardMaterial3D.new()
	desenho.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	desenho.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	desenho.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	desenho.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(tamanho, tamanho)
	quad.material = desenho
	particulas.draw_pass_1 = quad
	particulas.amount = quantidade
	particulas.lifetime = vida
	particulas.emitting = false
	return particulas


func _criar_polen() -> GPUParticles3D:
	## Grãos amarelos bem lentos, flutuando quase parados.
	var particulas := _criar_base(QUANTIDADE_POLEN, 8.0, 0.08)
	var material := particulas.process_material as ParticleProcessMaterial
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 0.1
	material.initial_velocity_max = 0.35
	material.color = COR_POLEN
	return particulas


func _criar_vagalumes() -> GPUParticles3D:
	## Pontos verde-amarelados que acendem e apagam duas vezes por vida.
	var particulas := _criar_base(QUANTIDADE_VAGALUMES, 5.0, 0.14)
	var material := particulas.process_material as ParticleProcessMaterial
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 0.2
	material.initial_velocity_max = 0.6
	material.color = COR_VAGALUME
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	var apagado := Color(COR_VAGALUME, 0.0)
	gradiente.colors = PackedColorArray([apagado, COR_VAGALUME, apagado, COR_VAGALUME, apagado])
	var rampa := GradientTexture1D.new()
	rampa.gradient = gradiente
	material.color_ramp = rampa
	var desenho := (particulas.draw_pass_1 as QuadMesh).material as StandardMaterial3D
	desenho.emission_enabled = true
	desenho.emission = COR_VAGALUME
	desenho.emission_energy_multiplier = 2.0
	return particulas


func _ao_comecar_dia() -> void:
	_noite = false
	_atualizar_emissao()


func _ao_comecar_noite() -> void:
	_noite = true
	_atualizar_emissao()


func _atualizar_emissao() -> void:
	_polen.emitting = not _na_agua and not _noite
	_vagalumes.emitting = not _na_agua and _noite


func _garantir_referencias() -> void:
	if _jogador == null:
		_jogador = get_tree().get_first_node_in_group("player") as Node3D
	if _chunk_manager == null:
		_chunk_manager = get_tree().get_first_node_in_group("chunk_manager") as ChunkManager


func _jogador_na_agua() -> bool:
	if _chunk_manager == null:
		return false
	var bloco := Vector3i(_jogador.global_position.floor())
	return _chunk_manager.get_block(bloco) == BlockRegistry.AGUA_ID


func _process(_delta: float) -> void:
	_garantir_referencias()
	if _jogador == null:
		return
	global_position = _jogador.global_position + Vector3(0, ALTURA_ACIMA_DO_JOGADOR, 0)
	var na_agua := _jogador_na_agua()
	if na_agua != _na_agua:
		_na_agua = na_agua
		_atualizar_emissao()
