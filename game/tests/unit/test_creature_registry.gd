extends GutTest
## Ver docs/01-GDD.md §9 e docs/04-ROADMAP.md F7 (4 espécies iniciais) / F8
## (formas evoluídas Pedrargo/Faiscozap).


func test_4_especies_iniciais_existem() -> void:
	var ids := ["brotinho", "ventim", "pedrolim", "faiscolt"]
	for id: String in ids:
		assert_not_null(CreatureRegistry.get_creature(id), "espécie '%s' deveria existir" % id)


func test_18_especies_no_total_incluindo_evolucoes() -> void:
	## 12 espécies base + 6 evoluções = 18 (F10, docs/01-GDD.md §9/§13)
	assert_eq(CreatureRegistry.todos_os_ids().size(), 18)


func test_formas_evoluidas_nao_spawnam_selvagens() -> void:
	for id: String in ["pedrargo", "faiscozap"]:
		var def := CreatureRegistry.get_creature(id)
		assert_not_null(def)
		assert_false(def.pode_ser_selvagem, "%s não deveria spawnar selvagem" % id)


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


func test_brotinho_e_ventim_nao_evoluem() -> void:
	for id: String in ["brotinho", "ventim"]:
		var def := CreatureRegistry.get_creature(id)
		assert_eq(def.nivel_evolucao, 0)
		assert_eq(def.especie_evolucao, "")


func test_pedrolim_evolui_pra_pedrargo_no_nivel_12() -> void:
	var def := CreatureRegistry.get_creature("pedrolim")
	assert_eq(def.nivel_evolucao, 12)
	assert_eq(def.especie_evolucao, "pedrargo")
	assert_not_null(CreatureRegistry.get_creature(def.especie_evolucao))


func test_faiscolt_evolui_pra_faiscozap_no_nivel_10() -> void:
	var def := CreatureRegistry.get_creature("faiscolt")
	assert_eq(def.nivel_evolucao, 10)
	assert_eq(def.especie_evolucao, "faiscozap")
	assert_not_null(CreatureRegistry.get_creature(def.especie_evolucao))


func test_todas_as_especies_tem_pelo_menos_1_ataque_conhecido_desde_o_nivel_1() -> void:
	for id: String in CreatureRegistry.todos_os_ids():
		var def := CreatureRegistry.get_creature(id)
		assert_true(def.aprendizado_ataques.has(1), "%s deveria aprender algo no nível 1" % id)
		var ataque_id: String = def.aprendizado_ataques[1]
		assert_not_null(
			AttackRegistry.get_ataque(ataque_id), "%s referencia ataque inexistente" % id
		)
