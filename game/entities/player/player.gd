extends CharacterBody3D
## Movimento básico do Murilo (F1: cápsula placeholder; F3: modelo definitivo).
## Ver docs/02-ARQUITETURA.md §4.1.

const VELOCIDADE: float = 5.0
const VELOCIDADE_CORRIDA: float = 8.0
const FORCA_PULO: float = 4.5
const GRAVIDADE: float = 9.8

@onready var camera_pivot: Node3D = $CameraPivot


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
