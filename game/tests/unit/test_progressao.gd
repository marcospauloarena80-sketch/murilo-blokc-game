extends GutTest
## E1 (ADR-032): regras de desbloqueio com dados controlados, sem o registro real.


func _arena(id: String, ordem: int = 0) -> ArenaDef:
	var arena := ArenaDef.new()
	arena.arena_id = id
	arena.ordem = ordem
	return arena


func _vazio() -> Array[String]:
	var lista: Array[String] = []
	return lista


func test_arena_sem_requisitos_fica_liberada_com_cubelin() -> void:
	assert_true(Progressao.ginasio_disponivel(_arena("a"), _vazio(), _vazio(), true, 4))


func test_sem_cubelin_bloqueia_antes_de_qualquer_outra_regra() -> void:
	assert_eq(
		Progressao.motivo_bloqueio(_arena("a"), _vazio(), _vazio(), false, 4),
		Progressao.MOTIVO_SEM_CUBELIN
	)


func test_requer_insignias_exige_cada_uma() -> void:
	var arena := _arena("b")
	arena.requer_insignias = ["a"]
	var tem: Array[String] = ["a"]
	assert_eq(
		Progressao.motivo_bloqueio(arena, _vazio(), _vazio(), true, 4), Progressao.MOTIVO_INSIGNIA
	)
	assert_true(Progressao.ginasio_disponivel(arena, tem, _vazio(), true, 4))


func test_requer_quest_exige_a_quest_concluida() -> void:
	var arena := _arena("b")
	arena.requer_quest = "q1"
	var feitas: Array[String] = ["q1"]
	assert_eq(
		Progressao.motivo_bloqueio(arena, _vazio(), _vazio(), true, 4), Progressao.MOTIVO_QUEST
	)
	assert_true(Progressao.ginasio_disponivel(arena, _vazio(), feitas, true, 4))


func test_requer_todas_insignias_usa_o_total_informado() -> void:
	var arena := _arena("final")
	arena.requer_todas_insignias = true
	var tres: Array[String] = ["a", "b", "c"]
	var quatro: Array[String] = ["a", "b", "c", "d"]
	assert_eq(
		Progressao.motivo_bloqueio(arena, tres, _vazio(), true, 4),
		Progressao.MOTIVO_TODAS_INSIGNIAS
	)
	assert_true(Progressao.ginasio_disponivel(arena, quatro, _vazio(), true, 4))


func test_em_sequencia_ordena_e_ignora_ordem_zero() -> void:
	var arenas: Array[ArenaDef] = [
		_arena("c", 3), _arena("solta", 0), _arena("a", 1), _arena("b", 2)
	]
	var ids: Array[String] = []
	for arena: ArenaDef in Progressao.em_sequencia(arenas):
		ids.append(arena.arena_id)
	assert_eq(ids, ["a", "b", "c"])


func test_arenas_reais_continuam_sem_ordem_nem_requisitos() -> void:
	## Proteção: a E1 não decide a progressão; nenhum .tres ganhou ordem.
	for id: String in ArenaRegistry.todos_os_ids():
		var arena := ArenaRegistry.get_arena(id)
		assert_eq(arena.ordem, 0, id)
		assert_true(arena.requer_insignias.is_empty(), id)
		assert_eq(arena.requer_quest, "", id)
	assert_true(Progressao.em_sequencia([]).is_empty())
