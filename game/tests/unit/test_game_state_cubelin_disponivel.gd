extends GutTest
## Ver docs/01-GDD.md §11 (gatilho de batalha exige ao menos 1 Cubelin apto)
## e docs/07-DECISOES.md ADR-021.


func before_each() -> void:
	GameState.equipe_cubelins = []


func after_each() -> void:
	GameState.equipe_cubelins = []


func test_sem_equipe_nao_tem_cubelin_disponivel() -> void:
	assert_false(GameState.tem_cubelin_disponivel())


func test_com_equipe_saudavel_tem_cubelin_disponivel() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("brotinho", 1)]
	assert_true(GameState.tem_cubelin_disponivel())


func test_equipe_toda_desmaiada_nao_tem_cubelin_disponivel() -> void:
	var instancia := CreatureInstance.new("brotinho", 1)
	instancia.vida_atual = 0
	GameState.equipe_cubelins = [instancia]
	assert_false(GameState.tem_cubelin_disponivel())


func test_um_membro_saudavel_entre_desmaiados_conta_como_disponivel() -> void:
	var desmaiado := CreatureInstance.new("brotinho", 1)
	desmaiado.vida_atual = 0
	var saudavel := CreatureInstance.new("ventim", 1)
	GameState.equipe_cubelins = [desmaiado, saudavel]
	assert_true(GameState.tem_cubelin_disponivel())
