extends GutTest
## Ver docs/01-GDD.md §10/§12 e docs/07-DECISOES.md ADR-022.

const LaboratorioScreenScene := preload("res://ui/laboratorio_screen/laboratorio_screen.tscn")


func before_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []
	GameState.mudar_estado(GameState.State.PLAYING)


func test_abrir_pausa_e_mostra() -> void:
	var tela := LaboratorioScreenScene.instantiate() as LaboratorioScreen
	add_child_autofree(tela)

	tela._abrir()

	assert_true(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PAUSED)


func test_fechar_despausa_e_esconde() -> void:
	var tela := LaboratorioScreenScene.instantiate() as LaboratorioScreen
	add_child_autofree(tela)
	tela._abrir()

	tela._fechar()

	assert_false(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PLAYING)


func test_clicar_equipe_move_pro_deposito() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("brotinho", 1)]
	var tela := LaboratorioScreenScene.instantiate() as LaboratorioScreen
	add_child_autofree(tela)
	tela._abrir()

	tela._ao_clicar_equipe(0)

	assert_eq(GameState.equipe_cubelins.size(), 0)
	assert_eq(GameState.deposito_cubelins.size(), 1)


func test_clicar_deposito_move_pra_equipe_se_tiver_espaco() -> void:
	GameState.deposito_cubelins = [CreatureInstance.new("ventim", 1)]
	var tela := LaboratorioScreenScene.instantiate() as LaboratorioScreen
	add_child_autofree(tela)
	tela._abrir()

	tela._ao_clicar_deposito(0)

	assert_eq(GameState.equipe_cubelins.size(), 1)
	assert_eq(GameState.deposito_cubelins.size(), 0)


func test_clicar_deposito_com_equipe_cheia_nao_faz_nada() -> void:
	GameState.equipe_cubelins = [
		CreatureInstance.new("brotinho", 1),
		CreatureInstance.new("ventim", 1),
		CreatureInstance.new("pedrolim", 1)
	]
	GameState.deposito_cubelins = [CreatureInstance.new("faiscolt", 1)]
	var tela := LaboratorioScreenScene.instantiate() as LaboratorioScreen
	add_child_autofree(tela)
	tela._abrir()

	tela._ao_clicar_deposito(0)

	assert_eq(GameState.equipe_cubelins.size(), 3)
	assert_eq(GameState.deposito_cubelins.size(), 1)
