extends GutTest
## Ver docs/01-GDD.md §10 (equipe até 3, excedente no depósito) e ADR-021 (F8).


func before_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []


func test_adicionar_cubelin_vai_pra_equipe_ate_o_limite() -> void:
	for i in range(GameState.MAX_EQUIPE):
		GameState.adicionar_cubelin(CreatureInstance.new("brotinho", 1))
	assert_eq(GameState.equipe_cubelins.size(), GameState.MAX_EQUIPE)
	assert_eq(GameState.deposito_cubelins.size(), 0)


func test_adicionar_cubelin_alem_do_limite_vai_pro_deposito() -> void:
	for i in range(GameState.MAX_EQUIPE + 2):
		GameState.adicionar_cubelin(CreatureInstance.new("brotinho", 1))
	assert_eq(GameState.equipe_cubelins.size(), GameState.MAX_EQUIPE)
	assert_eq(GameState.deposito_cubelins.size(), 2)
