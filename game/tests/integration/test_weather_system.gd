extends GutTest
## Ver docs/01-GDD.md §3 e docs/07-DECISOES.md ADR-024 — orquestração fina
## por cima do WeatherService puro (mesmo padrão de battle_screen/chest_screen).


func after_each() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)


func test_comeca_sem_clima_e_sem_particulas() -> void:
	var clima := WeatherSystem.new()
	add_child_autofree(clima)

	assert_eq(clima.estado_atual, WeatherService.Estado.NENHUM)
	assert_false(clima._particulas.emitting)


func test_sortear_clima_baixo_mantem_nenhum() -> void:
	var clima := WeatherSystem.new()
	add_child_autofree(clima)

	clima._sortear_clima(0.0)

	assert_eq(clima.estado_atual, WeatherService.Estado.NENHUM)
	assert_false(clima.eh_tempestade())


func test_sortear_clima_alto_liga_tempestade_e_particulas() -> void:
	var clima := WeatherSystem.new()
	add_child_autofree(clima)

	clima._sortear_clima(0.95)

	assert_true(clima.eh_tempestade())
	assert_true(clima._particulas.emitting)


func test_sortear_clima_medio_liga_chuva_sem_ser_tempestade() -> void:
	var clima := WeatherSystem.new()
	add_child_autofree(clima)

	clima._sortear_clima(0.7)

	assert_eq(clima.estado_atual, WeatherService.Estado.CHUVA)
	assert_false(clima.eh_tempestade())
	assert_true(clima._particulas.emitting)
