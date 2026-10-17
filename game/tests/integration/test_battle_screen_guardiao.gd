extends GutTest
## Ver docs/01-GDD.md §13 e docs/07-DECISOES.md ADR-023 — batalha de Guardião
## reaproveita o BattleScreen (mesmo padrão de test_battle_screen.gd), sem
## captura/fuga e encadeando pelos membros do Guardião via GuardianBattle.

const BattleScreenScene := preload("res://ui/battle_screen/battle_screen.tscn")


func before_each() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrargo", 20)]
	GameState.deposito_cubelins = []
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.insignias_conquistadas = []


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []
	GameState.insignias_conquistadas = []
	GameState.mudar_estado(GameState.State.PLAYING)


func test_abrir_arena_cria_guardian_battle_contra_o_primeiro_membro() -> void:
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)

	tela._abrir_arena("pedra")

	assert_true(tela.visible)
	assert_not_null(tela._guardiao)
	assert_eq(tela._batalha.selvagem.especie_id, "pedrolim")


func test_cubo_e_fugir_ficam_escondidos_contra_guardiao() -> void:
	GameState.inventario_hotbar.adicionar("cubo_captura", 1)
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)

	tela._abrir_arena("pedra")

	assert_false(tela._botao_cubo.visible)
	assert_false(tela._botao_fugir.visible)


func test_cubo_nao_faz_nada_contra_guardiao_mesmo_chamado_direto() -> void:
	GameState.inventario_hotbar.adicionar("cubo_captura", 1)
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir_arena("pedra")

	tela._usar_cubo_com_sorteio(0.0)

	assert_eq(GameState.inventario_hotbar.contar("cubo_captura"), 1, "cubo não deveria ser gasto")
	assert_eq(GameState.equipe_cubelins.size(), 1, "ninguém deveria ser capturado")


func test_fugir_nao_faz_nada_contra_guardiao_mesmo_chamado_direto() -> void:
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir_arena("pedra")

	tela._fugir_com_sorteio(0.0)

	assert_eq(tela._batalha.resultado, BattleService.Resultado.EM_ANDAMENTO)


func test_vencer_o_primeiro_membro_avanca_pro_proximo_sem_fechar() -> void:
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir_arena("pedra")  # pedrolim nv8, rochedo nv10

	while tela._guardiao.indice_guardiao == 0:
		tela._ao_atacar(0)

	assert_true(tela.visible, "não deveria fechar sozinho ao vencer só o primeiro membro")
	assert_eq(tela._guardiao.indice_guardiao, 1)
	assert_eq(tela._batalha.selvagem.especie_id, "rochedo")
	assert_false(GameState.tem_insignia("pedra"), "insígnia só depois do último membro")


func test_vencer_o_guardiao_inteiro_concede_a_insignia() -> void:
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir_arena("pedra")

	var guarda := 0
	while not GameState.tem_insignia("pedra") and guarda < 100:
		tela._ao_atacar(0)
		guarda += 1

	assert_true(GameState.tem_insignia("pedra"))
	assert_eq(tela._batalha.resultado, BattleService.Resultado.VITORIA)


func test_vencer_o_coracao_dourado_emite_game_completed_ao_fechar() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrargo", 30)]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir_arena("coracao_dourado")

	# Um golpe sempre causa >=1 de dano (BattleService.calcular_dano) — deixar
	# cada adversário com 1 HP garante 1 hit-kill determinístico, sem depender
	# de vantagem elemental/ordem de turno pra varrer os 3 membros.
	for i in range(3):
		tela._batalha.selvagem.vida_atual = 1
		tela._ao_atacar(0)

	assert_eq(tela._batalha.resultado, BattleService.Resultado.VITORIA)
	assert_false(
		GameState.tem_insignia("coracao_dourado"), "o desafio final não é uma insígnia (E0-3)"
	)

	var recebido: Array = [false]
	var callback := func() -> void: recebido[0] = true
	EventBus.game_completed.connect(callback)

	tela._fechar()

	EventBus.game_completed.disconnect(callback)
	assert_true(recebido[0])


func test_derrota_contra_guardiao_manda_pro_refugio_como_selvagem() -> void:
	var equipe := CreatureInstance.new("brotinho", 1)
	GameState.equipe_cubelins = [equipe]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir_arena("pedra")  # primeiro membro: pedrolim nv8
	tela._batalha.selvagem_ataca("pedra_investida", 1.1)
	assert_eq(tela._batalha.resultado, BattleService.Resultado.DERROTA)

	GameState.vida_atual = 1

	tela._fechar()

	assert_eq(GameState.vida_atual, GameState.vida_maxima)
	assert_false(equipe.esta_desmaiado())


func _vencer_o_final(tela: BattleScreen) -> void:
	tela._abrir_arena("coracao_dourado")
	for i in range(3):
		tela._batalha.selvagem.vida_atual = 1
		tela._ao_atacar(0)
	assert_eq(tela._batalha.resultado, BattleService.Resultado.VITORIA)


func test_revanche_no_coracao_dourado_nao_repete_game_completed() -> void:
	## Defeito E0-3: cada nova vitória reabria os créditos.
	GameState.equipe_cubelins = [CreatureInstance.new("pedrargo", 30)]
	GameState.treinadores_vencidos = {}
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	var vezes: Array = [0]
	var callback := func() -> void: vezes[0] += 1
	EventBus.game_completed.connect(callback)

	_vencer_o_final(tela)
	tela._fechar()
	_vencer_o_final(tela)
	tela._fechar()

	EventBus.game_completed.disconnect(callback)
	GameState.treinadores_vencidos = {}
	assert_eq(vezes[0], 1)


func test_abrir_arena_marca_a_equipe_do_guardiao_como_vista_no_caderno() -> void:
	## Defeito E0-5: batalhas de arena não passavam por battle_started.
	GameState.especies_vistas = []
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)

	tela._abrir_arena("pedra")

	assert_true(GameState.especies_vistas.has("pedrolim"))
	assert_true(GameState.especies_vistas.has("rochedo"))
	GameState.especies_vistas = []
