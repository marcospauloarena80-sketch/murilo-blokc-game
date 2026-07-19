extends GutTest
## Ver docs/01-GDD.md §11 e docs/07-DECISOES.md ADR-021. Testa a orquestração
## direto (padrão chest_screen/inventory_screen) — sorteio de fuga/captura é
## injetável nos métodos privados justamente pra isso ser determinístico.

const BattleScreenScene := preload("res://ui/battle_screen/battle_screen.tscn")
const CreatureScene := preload("res://entities/creatures/creature.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")


func _criatura_selvagem(especie_id: String) -> Creature:
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	criatura.configurar(CreatureRegistry.get_creature(especie_id))
	return criatura


func before_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []
	GameState.mudar_estado(GameState.State.PLAYING)


func test_abrir_pausa_o_jogo_e_cria_a_batalha() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrolim", 20)]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)

	tela._abrir(_criatura_selvagem("brotinho"))

	assert_true(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PAUSED)
	assert_not_null(tela._batalha)
	assert_eq(tela._batalha.selvagem.especie_id, "brotinho")


func test_fechar_despausa_e_esconde() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrolim", 20)]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir(_criatura_selvagem("brotinho"))

	tela._fechar()

	assert_false(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PLAYING)
	assert_null(tela._batalha)


func test_atacar_causa_dano_no_selvagem() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrolim", 20)]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir(_criatura_selvagem("brotinho"))
	var vida_antes := tela._batalha.selvagem.vida_atual

	tela._ao_atacar(0)

	assert_lt(tela._batalha.selvagem.vida_atual, vida_antes)


func test_trocar_troca_o_ativo() -> void:
	GameState.equipe_cubelins = [
		CreatureInstance.new("pedrolim", 1), CreatureInstance.new("ventim", 1)
	]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir(_criatura_selvagem("brotinho"))

	tela._ao_trocar()

	assert_eq(tela._batalha.indice_ativo, 1)


func test_usar_pocao_cura_o_ativo_e_consome_o_item() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrolim", 20)]
	GameState.inventario_hotbar.adicionar("pocao_cura", 1)
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir(_criatura_selvagem("ventim"))  # ventim passivo, contra-ataque fraco
	tela._batalha.jogador_ativo().vida_atual = 1

	tela._ao_usar_pocao()

	assert_gt(tela._batalha.jogador_ativo().vida_atual, 1)
	assert_eq(GameState.inventario_hotbar.contar("pocao_cura"), 0)


func test_usar_cubo_com_sorteio_baixo_captura() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrolim", 20)]
	GameState.inventario_hotbar.adicionar("cubo_captura", 1)
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir(_criatura_selvagem("brotinho"))

	tela._usar_cubo_com_sorteio(0.0)

	assert_eq(tela._batalha.resultado, BattleService.Resultado.CAPTUROU)
	assert_eq(GameState.inventario_hotbar.contar("cubo_captura"), 0)
	assert_eq(GameState.equipe_cubelins.size(), 2, "brotinho capturado deveria entrar na equipe")


func test_usar_cubo_com_sorteio_alto_falha_mas_consome_o_cubo() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrolim", 20)]
	GameState.inventario_hotbar.adicionar("cubo_captura", 1)
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir(_criatura_selvagem("brotinho"))

	tela._usar_cubo_com_sorteio(0.999)

	assert_eq(
		GameState.inventario_hotbar.contar("cubo_captura"), 0, "cubo é consumido mesmo na falha"
	)
	assert_eq(GameState.equipe_cubelins.size(), 1, "captura falhou, ninguém novo na equipe")


func test_fugir_com_sorteio_baixo_sucesso() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrolim", 20)]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir(_criatura_selvagem("brotinho"))

	tela._fugir_com_sorteio(0.0)

	assert_eq(tela._batalha.resultado, BattleService.Resultado.FUGIU)


func test_fugir_com_sorteio_alto_falha() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrolim", 20)]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir(_criatura_selvagem("brotinho"))

	tela._fugir_com_sorteio(0.999)

	assert_eq(tela._batalha.resultado, BattleService.Resultado.EM_ANDAMENTO)


func test_vitoria_remove_a_criatura_do_mundo() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrolim", 20)]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	var criatura := _criatura_selvagem("brotinho")
	tela._abrir(criatura)

	tela._ao_atacar(0)

	assert_eq(tela._batalha.resultado, BattleService.Resultado.VITORIA)
	assert_true(criatura.is_queued_for_deletion())


func test_fechar_apos_derrota_teleporta_pro_refugio_e_cura() -> void:
	var equipe := CreatureInstance.new("brotinho", 1)
	GameState.equipe_cubelins = [equipe]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir(_criatura_selvagem("pedrolim"))
	tela._batalha.selvagem_ataca("pedra_investida", 1.1)
	assert_eq(tela._batalha.resultado, BattleService.Resultado.DERROTA)

	var jogador := PlayerScene.instantiate() as Player
	add_child_autofree(jogador)
	jogador.global_position = Vector3(1, 1, 1)

	tela._fechar()

	assert_eq(jogador.global_position, GameState.PONTO_REFUGIO)
	assert_false(equipe.esta_desmaiado())
