class_name CreatureBehavior
extends RefCounted
## FSM pura (Idle/Wander/Flee/Aggro) pro comportamento dos Cubelins (F7).
## Sem Node — testável direto, sem instanciar cena. Ver docs/02-ARQUITETURA.md
## §4.2 e docs/07-DECISOES.md ADR-020.
##
## Dia/noite não entra aqui: só afeta QUEM spawna (CreatureSpawner), não o
## comportamento de uma criatura já viva no mundo.

enum Estado { IDLE, WANDER, FLEE, AGGRO }

const TEMPO_MAX_IDLE: float = 3.0
const TEMPO_MAX_WANDER: float = 4.0

var estado: Estado = Estado.IDLE

var _def: CreatureDef
var _tempo_no_estado: float = 0.0
var _direcao_wander: Vector3 = Vector3.ZERO


func _init(def: CreatureDef) -> void:
	_def = def


func atualizar(delta: float, pos_criatura: Vector3, pos_jogador: Vector3) -> Vector3:
	var distancia: float = pos_criatura.distance_to(pos_jogador)
	var jogador_perto: bool = distancia <= _def.raio_deteccao

	_decidir_estado(delta, jogador_perto)

	match estado:
		Estado.FLEE:
			return (pos_criatura - pos_jogador).normalized()
		Estado.AGGRO:
			return (pos_jogador - pos_criatura).normalized()
		Estado.WANDER:
			return _direcao_wander
		_:
			return Vector3.ZERO


func _decidir_estado(delta: float, jogador_perto: bool) -> void:
	if jogador_perto:
		var novo_estado: Estado = Estado.AGGRO if _def.eh_agressivo else Estado.FLEE
		if estado != novo_estado:
			estado = novo_estado
			_tempo_no_estado = 0.0
		return

	if estado == Estado.AGGRO or estado == Estado.FLEE:
		estado = Estado.IDLE
		_tempo_no_estado = 0.0
		return

	_tempo_no_estado += delta
	if estado == Estado.IDLE and _tempo_no_estado >= TEMPO_MAX_IDLE:
		estado = Estado.WANDER
		_tempo_no_estado = 0.0
		_direcao_wander = _direcao_aleatoria()
	elif estado == Estado.WANDER and _tempo_no_estado >= TEMPO_MAX_WANDER:
		estado = Estado.IDLE
		_tempo_no_estado = 0.0


func _direcao_aleatoria() -> Vector3:
	var angulo: float = randf() * TAU
	return Vector3(cos(angulo), 0, sin(angulo))
