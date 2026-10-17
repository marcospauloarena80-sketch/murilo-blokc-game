class_name Crescimento
extends Node
## Faz as plantas crescerem (Ciclo 8, frente 8A): muda vira árvore, trigo passa
## por 3 estágios. A cada INTERVALO_SEG olha as plantas dos chunks a até
## RAIO_CHUNKS do jogador (o resto do mundo fica parado, como o resto do jogo),
## soma tempo por posição e, quando passa do tempo_crescimento_seg do BlockDef,
## troca o bloco pelo próximo estágio. Determinístico: nada de sorteio, as
## plantas são percorridas em ordem estável (no máximo MAX_POR_PASSO por passo,
## em rodízio) e o relógio é injetável: avancar(segundos) é chamável direto
## pelos testes e pela sonda (muriloAcelerarCrescimento).

const INTERVALO_SEG: float = 2.0
const MAX_POR_PASSO: int = 40
const RAIO_CHUNKS: int = 2

## Se preenchido, vale no lugar do ChunkManager do grupo (testes).
var chunk_manager: ChunkManager

var _acumulado: Dictionary = {}  ## Vector3i -> {"id": int, "tempo": float}
var _resto_seg: float = 0.0
var _cursor: int = 0


func _process(delta: float) -> void:
	avancar(delta)


func avancar(segundos: float) -> void:
	_resto_seg += segundos
	while _resto_seg >= INTERVALO_SEG:
		_resto_seg -= INTERVALO_SEG
		_passo()


func tempo_acumulado(pos: Vector3i) -> float:
	var entrada: Dictionary = _acumulado.get(pos, {})
	return float(entrada.get("tempo", 0.0))


func _passo() -> void:
	var cm := chunk_manager
	if cm == null:
		cm = get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	var jogador := get_tree().get_first_node_in_group("player") as Node3D
	if cm == null or jogador == null:
		return
	var centro := Vector2i(
		floori(jogador.global_position.x) >> 4, floori(jogador.global_position.z) >> 4
	)
	var plantas := cm.plantas_perto(centro, RAIO_CHUNKS)
	if plantas.is_empty():
		_acumulado.clear()
		_cursor = 0
		return
	var total: int = plantas.size()
	## Mais plantas que o limite: cada passo atende um lote, em rodízio, e o
	## tempo somado compensa os passos em que a planta ficou de fora.
	var rodadas: int = ceili(float(total) / MAX_POR_PASSO)
	var lote: int = mini(total, MAX_POR_PASSO)
	for k in range(lote):
		_crescer_planta(cm, plantas[(_cursor + k) % total], INTERVALO_SEG * rodadas)
	_cursor = (_cursor + lote) % total


func _crescer_planta(cm: ChunkManager, pos: Vector3i, segundos: float) -> void:
	var id: int = cm.get_block(pos)
	var def := BlockRegistry.get_block(id)
	if def == null or def.cresce_para == 0:
		_acumulado.erase(pos)
		return
	var entrada: Dictionary = _acumulado.get(pos, {})
	if int(entrada.get("id", -1)) != id:
		entrada = {"id": id, "tempo": 0.0}  # planta nova nesse lugar: começa do zero
	entrada["tempo"] = float(entrada["tempo"]) + segundos
	_acumulado[pos] = entrada
	if float(entrada["tempo"]) < def.tempo_crescimento_seg:
		return
	if def.tipo_especial == "muda":
		## Árvore: se algo sólido atrapalha o tronco a muda espera e tenta de novo.
		if cm.plantar_arvore(pos):
			_acumulado.erase(pos)
	else:
		cm.trocar_bloco_sem_evento(pos, def.cresce_para)
		_acumulado.erase(pos)
