class_name Companheiro
extends Node3D
## Cubelin companheiro no mundo (Ciclo 9, 9C): mantém uma Creature em modo
## companheiro para GameState.equipe_cubelins[0] e a refaz quando a equipe muda
## (EventBus.team_changed). Também confere a identidade do primeiro da equipe a
## cada quadro, porque o carregar de save troca o array sem emitir o sinal.

const CreatureScene := preload("res://entities/creatures/creature.tscn")
const ALTURA_ACIMA_DO_CHAO: float = 0.4
const DESLOCAMENTO_NASCER: float = 2.5

var criatura: Creature  ## null = sem companheiro

var _instancia_atual: CreatureInstance


func _ready() -> void:
	EventBus.team_changed.connect(atualizar)
	atualizar()


func _process(_delta: float) -> void:
	var primeiro: CreatureInstance = _primeiro_da_equipe()
	if primeiro != _instancia_atual or (primeiro != null and not is_instance_valid(criatura)):
		atualizar()


func atualizar() -> void:
	_instancia_atual = _primeiro_da_equipe()
	if is_instance_valid(criatura):
		criatura.queue_free()
	criatura = null
	if _instancia_atual == null:
		return
	criatura = CreatureScene.instantiate() as Creature
	criatura.configurar_companheiro(_instancia_atual)
	add_child(criatura)
	criatura.global_position = _ponto_de_nascimento()


func _primeiro_da_equipe() -> CreatureInstance:
	if GameState.equipe_cubelins.is_empty():
		return null
	return GameState.equipe_cubelins[0]


func _ponto_de_nascimento() -> Vector3:
	var jogador := get_tree().get_first_node_in_group("player") as Node3D
	if jogador == null:
		return Vector3.ZERO
	return jogador.global_position + Vector3(DESLOCAMENTO_NASCER, ALTURA_ACIMA_DO_CHAO, 0.0)
