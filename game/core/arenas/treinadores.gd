class_name Treinadores
extends RefCounted
## Regras dos treinadores de mundo (Ciclo 9, 9E): vitória sem insígnia que premia
## uma vez por dia de jogo. O estado fica em GameState.treinadores_vencidos
## (arena_id -> dia da última vitória).


static func dia_de_jogo() -> int:
	## Dia corrente (0 = primeiro) contado pelo tempo jogado: dormir não o recua.
	return int(GameState.tempo_de_jogo_seg / GameState.DURACAO_CICLO_SEG)


static func revanche_liberada(arena_id: String) -> bool:
	## Livre se nunca foi vencido ou se passou um dia de jogo.
	if not GameState.treinadores_vencidos.has(arena_id):
		return true
	return dia_de_jogo() > int(GameState.treinadores_vencidos[arena_id])


static func registrar_vitoria(arena_id: String) -> void:
	GameState.treinadores_vencidos[arena_id] = dia_de_jogo()
