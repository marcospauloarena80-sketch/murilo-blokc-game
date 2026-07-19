extends GutTest
## Ver docs/01-GDD.md §11/§12 e docs/07-DECISOES.md ADR-022.


func before_each() -> void:
	GameState.equipe_cubelins = []


func after_each() -> void:
	GameState.equipe_cubelins = []


func test_curar_no_refugio_restaura_vida_fome_e_energia_do_jogador() -> void:
	GameState.vida_atual = 1
	GameState.fome_atual = 2
	GameState.energia_atual = 3

	GameState.curar_no_refugio()

	assert_eq(GameState.vida_atual, GameState.vida_maxima)
	assert_eq(GameState.fome_atual, GameState.fome_maxima)
	assert_eq(GameState.energia_atual, GameState.energia_maxima)


func test_curar_no_refugio_restaura_a_equipe_inteira() -> void:
	var cubelin := CreatureInstance.new("pedrolim", 5)
	cubelin.vida_atual = 1
	cubelin.energia_atual = 0
	GameState.equipe_cubelins = [cubelin]

	GameState.curar_no_refugio()

	assert_eq(cubelin.vida_atual, cubelin.vida_maxima_efetiva())
	assert_eq(cubelin.energia_atual, cubelin.energia_maxima_efetiva())
