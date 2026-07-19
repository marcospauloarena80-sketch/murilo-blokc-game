extends GutTest
## Ver docs/01-GDD.md §13 e docs/07-DECISOES.md ADR-023.

const ARENAS_REGULARES := ["pedra", "brasa", "gota", "faisca"]


func test_4_arenas_regulares_mais_o_desafio_final_existem() -> void:
	assert_eq(ArenaRegistry.todos_os_ids().size(), 5)
	for id: String in ARENAS_REGULARES:
		assert_not_null(ArenaRegistry.get_arena(id), "arena '%s' deveria existir" % id)
	assert_not_null(ArenaRegistry.get_arena("coracao_dourado"))


func test_arenas_regulares_tem_2_a_3_membros() -> void:
	for id: String in ARENAS_REGULARES:
		var arena := ArenaRegistry.get_arena(id)
		assert_between(arena.equipe.size(), 2, 3, "%s deveria ter 2-3 membros" % id)


func test_coracao_dourado_tem_3_membros_e_exige_todas_as_insignias() -> void:
	var arena := ArenaRegistry.get_arena("coracao_dourado")
	assert_eq(arena.equipe.size(), 3)
	assert_true(arena.requer_todas_insignias)


func test_arenas_regulares_nao_exigem_todas_as_insignias() -> void:
	for id: String in ARENAS_REGULARES:
		assert_false(ArenaRegistry.get_arena(id).requer_todas_insignias)


func test_todas_as_arenas_referenciam_especies_existentes() -> void:
	for id: String in ArenaRegistry.todos_os_ids():
		var arena := ArenaRegistry.get_arena(id)
		for membro: Dictionary in arena.equipe:
			assert_not_null(
				CreatureRegistry.get_creature(membro["especie_id"]),
				"%s referencia espécie inexistente: %s" % [id, membro["especie_id"]]
			)


func test_arenas_regulares_tem_receita_exclusiva() -> void:
	for id: String in ARENAS_REGULARES:
		var arena := ArenaRegistry.get_arena(id)
		assert_ne(arena.recompensa_receita, "", "%s deveria ter receita exclusiva" % id)
		assert_not_null(RecipeRegistry.get_receita(arena.recompensa_receita))


func test_construir_equipe_cria_instancias_no_nivel_certo() -> void:
	var arena := ArenaRegistry.get_arena("pedra")
	var equipe := arena.construir_equipe()
	assert_eq(equipe.size(), 2)
	assert_eq(equipe[0].especie_id, "pedrolim")
	assert_eq(equipe[0].nivel, 8)
	assert_eq(equipe[1].especie_id, "rochedo")
	assert_eq(equipe[1].nivel, 10)
