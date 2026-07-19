extends GutTest
## Ver docs/01-GDD.md §3 e docs/07-DECISOES.md ADR-024. Sorteio sempre
## injetado por parâmetro, nunca chamado internamente — mesmo padrão de
## BattleService/CaptureService (ADR-021).


func test_sorteio_baixo_e_nenhum() -> void:
	assert_eq(WeatherService.sortear_estado(0.0), WeatherService.Estado.NENHUM)


func test_sorteio_medio_e_chuva() -> void:
	assert_eq(WeatherService.sortear_estado(0.7), WeatherService.Estado.CHUVA)


func test_sorteio_alto_e_tempestade() -> void:
	assert_eq(WeatherService.sortear_estado(0.95), WeatherService.Estado.TEMPESTADE)


func test_fronteira_nenhum_chuva() -> void:
	assert_eq(WeatherService.sortear_estado(0.59), WeatherService.Estado.NENHUM)
	assert_eq(WeatherService.sortear_estado(0.61), WeatherService.Estado.CHUVA)


func test_fronteira_chuva_tempestade() -> void:
	assert_eq(WeatherService.sortear_estado(0.89), WeatherService.Estado.CHUVA)
	assert_eq(WeatherService.sortear_estado(0.91), WeatherService.Estado.TEMPESTADE)
