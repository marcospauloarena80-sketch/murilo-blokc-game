class_name WeatherSystem
extends Node3D
## Clima (F11, ADR-024): sorteia Nenhum/Chuva/Tempestade por timer, mostra
## partículas de chuva e acompanha o jogador. Tempestade aumenta o peso de
## Faísca no sorteio de spawn (CreatureSpawner) — visual + spawn, sem dano
## (docs/01-GDD.md §3).

const INTERVALO_SORTEIO_SEG: float = 120.0
const ALTURA_PARTICULAS: float = 20.0

var estado_atual: WeatherService.Estado = WeatherService.Estado.NENHUM

var _jogador: Node3D
var _particulas: GPUParticles3D
var _tempo_desde_sorteio: float = 0.0


func _ready() -> void:
	add_to_group("weather_system")
	_particulas = _criar_particulas_chuva()
	add_child(_particulas)


func _criar_particulas_chuva() -> GPUParticles3D:
	var particulas := GPUParticles3D.new()
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.spread = 5.0
	material.gravity = Vector3(0, -9.0, 0)
	material.initial_velocity_min = 8.0
	material.initial_velocity_max = 10.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(24, 1, 24)
	material.color = Color(0.6, 0.7, 0.9, 0.6)
	particulas.process_material = material
	particulas.draw_pass_1 = QuadMesh.new()
	particulas.amount = 200
	particulas.lifetime = 2.0
	particulas.emitting = false
	return particulas


func _garantir_jogador() -> void:
	if _jogador == null:
		_jogador = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	_garantir_jogador()
	if _jogador != null:
		_particulas.global_position = _jogador.global_position + Vector3(0, ALTURA_PARTICULAS, 0)

	if GameState.current_state != GameState.State.PLAYING:
		return
	_tempo_desde_sorteio += delta
	if _tempo_desde_sorteio < INTERVALO_SORTEIO_SEG:
		return
	_tempo_desde_sorteio = 0.0
	_sortear_clima(randf())


func _sortear_clima(sorteio: float) -> void:
	estado_atual = WeatherService.sortear_estado(sorteio)
	_atualizar_visual()


func _atualizar_visual() -> void:
	_particulas.emitting = estado_atual != WeatherService.Estado.NENHUM
	_particulas.amount_ratio = (1.0 if estado_atual == WeatherService.Estado.TEMPESTADE else 0.5)


func eh_tempestade() -> bool:
	return estado_atual == WeatherService.Estado.TEMPESTADE
