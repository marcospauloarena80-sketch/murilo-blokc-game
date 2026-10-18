extends GutTest
## ADR-033: na tela, quando o oponente é mais rápido e derruba o ativo, o ativo
## desmaiado não contra-ataca. Reproduz o cenário do playtest (Ventim nível 1
## contra o Faiscolt do Diego) sem depender de sorteio: o dano é sempre letal.

const BattleScreenScene := preload("res://ui/battle_screen/battle_screen.tscn")


func before_each() -> void:
	GameState.equipe_cubelins = [
		CreatureInstance.new("ventim", 1), CreatureInstance.new("pedrargo", 30)
	]
	GameState.deposito_cubelins = []
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.mudar_estado(GameState.State.PLAYING)


func test_oponente_mais_rapido_derruba_e_o_desmaiado_nao_contra_ataca() -> void:
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir_arena("faisca")  ## Faiscolt nv.14 é bem mais rápido que o Ventim nv.1
	var oponente := tela._batalha.selvagem
	var vida_do_oponente := oponente.vida_atual
	var ventim := GameState.equipe_cubelins[0]
	assert_eq(tela._batalha.quem_age_primeiro(), "selvagem", "pré-condição do cenário")

	tela._ao_atacar(0)

	assert_true(ventim.esta_desmaiado())
	assert_eq(ventim.xp, 0)
	assert_eq(oponente.vida_atual, vida_do_oponente, "o desmaiado não causou dano")
	for linha: String in tela._linhas_log:
		assert_false(linha.contains("Ventim usou"), "sem contra-ataque do desmaiado: " + linha)
