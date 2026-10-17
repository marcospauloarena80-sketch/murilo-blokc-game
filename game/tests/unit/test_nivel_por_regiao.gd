extends GutTest
## Ciclo 9, 9A: nível por região e placa com nível.

const CreatureScene := preload("res://entities/creatures/creature.tscn")


func test_sortear_respeita_a_faixa_de_cada_bioma() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for bioma: String in NivelPorRegiao.FAIXAS:
		var faixa: Vector2i = NivelPorRegiao.faixa(bioma)
		for i in range(50):
			var nivel: int = NivelPorRegiao.sortear(bioma, rng)
			assert_between(nivel, faixa.x, faixa.y, bioma)


func test_faixas_dos_aneis() -> void:
	assert_eq(NivelPorRegiao.faixa("campos_dourados"), Vector2i(3, 5))
	assert_eq(NivelPorRegiao.faixa("floresta_cubica"), Vector2i(5, 8))
	assert_eq(NivelPorRegiao.faixa("colinas_de_pedra"), Vector2i(8, 12))
	assert_eq(NivelPorRegiao.faixa("deserto_de_ambar"), Vector2i(12, 16))
	assert_eq(NivelPorRegiao.faixa("picos_gelados"), Vector2i(16, 20))


func test_bioma_desconhecido_usa_faixa_dos_campos() -> void:
	assert_eq(NivelPorRegiao.faixa("nao_existe"), Vector2i(3, 5))


func test_definir_nivel_escala_vida_e_mostra_na_placa() -> void:
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	var def: CreatureDef = CreatureRegistry.get_creature("brotinho")
	criatura.configurar(def)

	criatura.definir_nivel(4)

	var esperado: int = CreatureInstance.new("brotinho", 4).vida_maxima_efetiva()
	assert_eq(criatura.nivel, 4)
	assert_eq(criatura.vida_atual, esperado)
	assert_eq((criatura.get_node("Placa") as Label3D).text, "%s Nv.4" % def.nome)


func test_sem_nivel_mantem_vida_base() -> void:
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	var def: CreatureDef = CreatureRegistry.get_creature("brotinho")
	criatura.configurar(def)

	assert_eq(criatura.nivel, 0)
	assert_eq(criatura.vida_atual, def.vida_maxima)


func test_perto_do_vilarejo_so_pedrolim_e_faiscolt_entre_agressivos() -> void:
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)
	for bioma: String in ["campos_dourados", "colinas_de_pedra", "floresta_cubica"]:
		for def: CreatureDef in spawner._especies_do_periodo_e_bioma("noite", bioma, true):
			if def.eh_agressivo:
				assert_true(["pedrolim", "faiscolt"].has(def.especie_id), def.especie_id)


func test_longe_do_vilarejo_agressivos_fortes_podem_nascer() -> void:
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)
	var ids: Array[String] = []
	for def: CreatureDef in spawner._especies_do_periodo_e_bioma(
		"noite", "colinas_de_pedra", false
	):
		ids.append(def.especie_id)
	assert_true(ids.has("rochedo"), "rochedo fora do anel central")
