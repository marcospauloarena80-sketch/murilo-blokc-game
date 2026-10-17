class_name BlockBreakParticles
extends Node3D
## Partículas ao quebrar bloco (F11, ADR-024) — burst curto colorido pela
## cor do BlockDef, puramente cosmético (sem gameplay). Mesmo padrão de
## LootSpawner/TorchLightManager: só escuta EventBus, sem lógica de mundo.

const DURACAO_VIDA: float = 0.6
const DURACAO_POEIRA: float = 0.4
const QUANTIDADE_POEIRA: int = 10
const COR_POEIRA: Color = Color(0.76, 0.66, 0.5)  ## marrom-claro


func _ready() -> void:
	EventBus.block_broken.connect(_ao_quebrar_bloco)
	EventBus.player_landed.connect(_ao_aterrissar)


func _ao_quebrar_bloco(pos: Vector3i, block_id: int) -> void:
	var bloco := BlockRegistry.get_block(block_id)
	if bloco == null or not is_inside_tree():
		return
	var particulas := _criar_burst(bloco.cor)
	particulas.position = Vector3(pos) + Vector3(0.5, 0.5, 0.5)
	add_child(particulas)
	get_tree().create_timer(DURACAO_VIDA + 0.2).timeout.connect(particulas.queue_free)


func _ao_aterrissar(pos: Vector3, _altura_queda: float) -> void:
	## Poeira curta nos pés ao tocar o chão depois de uma queda (Ciclo 5, 5C).
	if not is_inside_tree():
		return
	var poeira := _criar_burst(COR_POEIRA, QUANTIDADE_POEIRA, DURACAO_POEIRA)
	var material := poeira.process_material as ParticleProcessMaterial
	material.gravity = Vector3(0, -2.0, 0)
	material.initial_velocity_min = 0.8
	material.initial_velocity_max = 1.6
	material.scale_min = 0.08
	material.scale_max = 0.16
	poeira.position = pos
	add_child(poeira)
	get_tree().create_timer(DURACAO_POEIRA + 0.2).timeout.connect(poeira.queue_free)


func _criar_burst(cor: Color, quantidade: int = 12, vida: float = DURACAO_VIDA) -> GPUParticles3D:
	var particulas := GPUParticles3D.new()
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 180.0
	material.gravity = Vector3(0, -9.0, 0)
	material.initial_velocity_min = 1.5
	material.initial_velocity_max = 3.0
	material.color = cor
	particulas.process_material = material
	particulas.draw_pass_1 = BoxMesh.new()
	particulas.amount = quantidade
	particulas.lifetime = vida
	particulas.one_shot = true
	particulas.emitting = true
	return particulas
