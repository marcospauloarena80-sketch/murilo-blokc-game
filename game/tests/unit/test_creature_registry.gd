extends GutTest
## Ver docs/01-GDD.md §9 e docs/04-ROADMAP.md F7 (4 espécies iniciais).


func test_4_especies_iniciais_existem() -> void:
	var ids := ["brotinho", "ventim", "pedrolim", "faiscolt"]
	assert_eq(CreatureRegistry.todos_os_ids().size(), 4)
	for id: String in ids:
		assert_not_null(CreatureRegistry.get_creature(id), "espécie '%s' deveria existir" % id)


func test_especie_inexistente_retorna_null() -> void:
	assert_null(CreatureRegistry.get_creature("nao_existe"))


func test_especies_passivas_tem_dano_contato_zero() -> void:
	for id: String in ["brotinho", "ventim"]:
		var def := CreatureRegistry.get_creature(id)
		assert_false(def.eh_agressivo, "%s deveria ser passivo" % id)
		assert_eq(def.dano_contato, 0, "%s passivo não deveria causar dano de contato" % id)


func test_especies_agressivas_causam_dano_e_spawnam_de_noite() -> void:
	for id: String in ["pedrolim", "faiscolt"]:
		var def := CreatureRegistry.get_creature(id)
		assert_true(def.eh_agressivo, "%s deveria ser agressivo" % id)
		assert_gt(def.dano_contato, 0, "%s agressivo deveria causar dano de contato" % id)
		assert_eq(def.periodo_spawn, "noite")
