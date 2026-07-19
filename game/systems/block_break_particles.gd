class_name BlockBreakParticles
extends Node3D
## Partículas ao quebrar bloco (F11, ADR-024) — burst curto colorido pela
## cor do BlockDef, puramente cosmético (sem gameplay). Mesmo padrão de
## LootSpawner/TorchLightManager: só escuta EventBus, sem lógica de mundo.

const DURACAO_VIDA: float = 0.6


func _ready() -> void:
	EventBus.block_broken.connect(_ao_quebrar_bloco)


func _ao_quebrar_bloco(pos: Vector3i, block_id: int) -> void:
	var bloco := BlockRegistry.get_block(block_id)
	if bloco == null:
		return
	var particulas := _criar_burst(bloco.cor)
	particulas.position = Vector3(pos) + Vector3(0.5, 0.5, 0.5)
	add_child(particulas)
	get_tree().create_timer(DURACAO_VIDA + 0.2).timeout.connect(particulas.queue_free)


func _criar_burst(cor: Color) -> GPUParticles3D:
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
	particulas.amount = 12
	particulas.lifetime = DURACAO_VIDA
	particulas.one_shot = true
	particulas.emitting = true
	return particulas
