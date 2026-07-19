extends GutTest
## Ver docs/01-GDD.md §13 e docs/07-DECISOES.md ADR-023.


func before_each() -> void:
	GameState.insignias_conquistadas = []


func test_sem_insignia_no_comeco() -> void:
	assert_false(GameState.tem_insignia("pedra"))


func test_conquistar_insignia_marca_como_tida() -> void:
	GameState.conquistar_insignia("pedra")
	assert_true(GameState.tem_insignia("pedra"))


func test_conquistar_insignia_e_idempotente() -> void:
	GameState.conquistar_insignia("pedra")
	GameState.conquistar_insignia("pedra")
	assert_eq(GameState.insignias_conquistadas.count("pedra"), 1)


func test_insignias_diferentes_nao_se_confundem() -> void:
	GameState.conquistar_insignia("pedra")
	assert_false(GameState.tem_insignia("brasa"))


func test_reiniciar_para_novo_jogo_zera_insignias() -> void:
	GameState.conquistar_insignia("pedra")
	GameState.reiniciar_para_novo_jogo()
	assert_eq(GameState.insignias_conquistadas.size(), 0)
