extends GutTest
## Ver docs/01-GDD.md §3 e docs/07-DECISOES.md ADR-024 — tempestade dobra o
## peso de Faísca no sorteio de spawn, sem suprimir os outros elementos.


func test_sem_tempestade_faisca_aparece_1_vez() -> void:
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)

	var candidatas := spawner._especies_do_periodo_e_bioma("noite", "campos_dourados")

	var vezes := 0
	for def: CreatureDef in candidatas:
		if def.especie_id == "faiscolt":
			vezes += 1
	assert_eq(vezes, 1)


func test_com_tempestade_faisca_aparece_2_vezes() -> void:
	var clima := WeatherSystem.new()
	add_child_autofree(clima)
	clima._sortear_clima(0.95)  # tempestade

	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)

	var candidatas := spawner._especies_do_periodo_e_bioma("noite", "campos_dourados")

	var vezes := 0
	for def: CreatureDef in candidatas:
		if def.especie_id == "faiscolt":
			vezes += 1
	assert_eq(vezes, 2, "tempestade deveria dobrar o peso de Faísca")


func test_com_tempestade_outros_elementos_continuam_com_1_vez() -> void:
	var clima := WeatherSystem.new()
	add_child_autofree(clima)
	clima._sortear_clima(0.95)  # tempestade

	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)

	var candidatas := spawner._especies_do_periodo_e_bioma("noite", "campos_dourados")

	var vezes := 0
	for def: CreatureDef in candidatas:
		if def.especie_id == "pedrolim":
			vezes += 1
	assert_eq(vezes, 1, "tempestade só afeta Faísca, não Pedra")
