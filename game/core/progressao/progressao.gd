class_name Progressao
extends RefCounted
## Regras de desbloqueio de arenas/ginásios (E1, ADR-032). Classe pura: recebe
## o estado como parâmetro e não lê GameState, pra ser testada com dados
## controlados. Só interpreta os campos genéricos de ArenaDef; a ordem real
## dos ginásios, nomes e equipes são decisões de produto ainda pendentes.

const MOTIVO_NENHUM: String = ""
const MOTIVO_SEM_CUBELIN: String = "sem_cubelin"
const MOTIVO_INSIGNIA: String = "insignia"
const MOTIVO_QUEST: String = "quest"
const MOTIVO_TODAS_INSIGNIAS: String = "todas_insignias"


## Primeiro motivo que impede o desafio, ou MOTIVO_NENHUM se está liberado.
static func motivo_bloqueio(
	arena: ArenaDef,
	insignias: Array[String],
	quests_concluidas: Array[String],
	tem_cubelin: bool,
	total_de_insignias: int
) -> String:
	if not tem_cubelin:
		return MOTIVO_SEM_CUBELIN
	if arena.requer_todas_insignias and insignias.size() < total_de_insignias:
		return MOTIVO_TODAS_INSIGNIAS
	for exigida: String in arena.requer_insignias:
		if not insignias.has(exigida):
			return MOTIVO_INSIGNIA
	if arena.requer_quest != "" and not quests_concluidas.has(arena.requer_quest):
		return MOTIVO_QUEST
	return MOTIVO_NENHUM


static func ginasio_disponivel(
	arena: ArenaDef,
	insignias: Array[String],
	quests_concluidas: Array[String],
	tem_cubelin: bool,
	total_de_insignias: int
) -> bool:
	return (
		motivo_bloqueio(arena, insignias, quests_concluidas, tem_cubelin, total_de_insignias)
		== MOTIVO_NENHUM
	)


## Arenas ordenadas por `ordem` (empate mantém a ordem de entrada). Arenas com
## ordem 0 ficam fora da sequência: é o estado atual de todas elas.
static func em_sequencia(arenas: Array[ArenaDef]) -> Array[ArenaDef]:
	var com_ordem: Array[ArenaDef] = []
	for arena: ArenaDef in arenas:
		if arena.ordem > 0:
			com_ordem.append(arena)
	com_ordem.sort_custom(func(a: ArenaDef, b: ArenaDef) -> bool: return a.ordem < b.ordem)
	return com_ordem
