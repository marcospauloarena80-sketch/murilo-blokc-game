extends GutTest
## Ciclo 9, Frente 9B: barras de vida, log das 3 últimas linhas e arena 3D.

const BattleScreenScene := preload("res://ui/battle_screen/battle_screen.tscn")
const CreatureScene := preload("res://entities/creatures/creature.tscn")


func _criatura_selvagem(especie_id: String) -> Creature:
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	criatura.configurar(CreatureRegistry.get_creature(especie_id))
	return criatura


func _tela(especie_jogador: String, nivel: int, especie_selvagem: String) -> BattleScreen:
	GameState.equipe_cubelins = [CreatureInstance.new(especie_jogador, nivel)]
	var tela := BattleScreenScene.instantiate() as BattleScreen
	add_child_autofree(tela)
	tela._abrir(_criatura_selvagem(especie_selvagem))
	return tela


func before_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []
	GameState.mudar_estado(GameState.State.PLAYING)


func test_barras_refletem_a_vida() -> void:
	var tela := _tela("pedrolim", 20, "brotinho")
	var jogador := tela._batalha.jogador_ativo()
	var selvagem := tela._batalha.selvagem
	tela._atualizar()
	assert_eq(int(tela._barra_jogador.max_value), jogador.vida_maxima_efetiva())
	assert_eq(int(tela._barra_selvagem.value), selvagem.vida_atual)

	selvagem.vida_atual = 1
	jogador.vida_atual = 2
	tela._atualizar()

	assert_eq(int(tela._barra_selvagem.value), 1)
	assert_eq(int(tela._barra_jogador.value), 2)


func test_log_recebe_linha_apos_atacar() -> void:
	var tela := _tela("pedrolim", 20, "brotinho")

	tela._ao_atacar(0)

	assert_string_contains(tela._log.text, "usou")
	assert_string_contains(tela._log.text, "de dano!")


func test_log_guarda_so_as_3_ultimas_linhas() -> void:
	var tela := _tela("pedrolim", 20, "brotinho")
	for i in range(5):
		tela._adicionar_log("linha %d" % i)

	assert_eq(tela._log.text, "linha 2\nlinha 3\nlinha 4")


func test_ataque_super_efetivo_registra_no_log() -> void:
	## mato vence gota: ataque de mato contra um Cubelin de gota.
	var tela := _tela("brotinho", 20, "gotelo")
	var ataque_id: String = ""
	for id in tela._batalha.jogador_ativo().ataques_conhecidos:
		if AttackRegistry.get_ataque(id).elemento == "mato":
			ataque_id = id
	if ataque_id == "":
		pending("sem ataque de mato neste nível")
		return

	tela._registrar_ataque(
		tela._batalha.jogador_ativo(), tela._batalha.selvagem, ataque_id, 5, Arena3D.Lado.JOGADOR
	)

	assert_string_contains(tela._log.text, "É super efetivo!")


func test_captura_registra_linha_no_log() -> void:
	var tela := _tela("pedrolim", 20, "brotinho")
	GameState.inventario_hotbar.adicionar("cubo_captura", 1)

	tela._usar_cubo_com_sorteio(0.0)

	assert_string_contains(tela._log.text, "foi capturado!")


func test_arena_monta_as_duas_criaturas_frente_a_frente() -> void:
	var tela := _tela("pedrolim", 20, "brotinho")
	var jogador := tela._arena_3d.corpo_do_lado(Arena3D.Lado.JOGADOR)
	var oponente := tela._arena_3d.corpo_do_lado(Arena3D.Lado.OPONENTE)
	assert_not_null(jogador)
	assert_not_null(oponente)
	assert_lt(jogador.position.x, oponente.position.x)


func test_animacoes_headless_nao_travam_nem_deixam_residuo() -> void:
	var tela := _tela("pedrolim", 20, "brotinho")
	var arena := tela._arena_3d
	arena.investida(Arena3D.Lado.JOGADOR)
	arena.piscar_dano(Arena3D.Lado.OPONENTE)
	arena.animar_captura(true)
	assert_false(arena.corpo_do_lado(Arena3D.Lado.OPONENTE).visible)

	arena.animar_captura(false)
	assert_true(arena.corpo_do_lado(Arena3D.Lado.OPONENTE).visible)


func test_animacoes_ligadas_terminam_na_posicao_original() -> void:
	var tela := _tela("pedrolim", 20, "brotinho")
	var arena := tela._arena_3d
	arena.animacoes_ligadas = true
	var corpo := arena.corpo_do_lado(Arena3D.Lado.JOGADOR)
	var x_base := corpo.position.x

	arena.investida(Arena3D.Lado.JOGADOR)
	arena.piscar_dano(Arena3D.Lado.JOGADOR)
	await wait_seconds(0.9)

	assert_almost_eq(corpo.position.x, x_base, 0.001)


func test_evolucao_troca_a_forma_na_arena() -> void:
	var tela := _tela("folhaz", 1, "ventim")
	var antes := tela._arena_3d.corpo_do_lado(Arena3D.Lado.JOGADOR)
	var inst := tela._batalha.jogador_ativo()
	var evolucao: String = inst.especie_def().especie_evolucao
	if evolucao == "":
		pending("Folhaz sem evolução")
		return

	inst.especie_id = evolucao
	tela._atualizar()

	assert_ne(tela._arena_3d.corpo_do_lado(Arena3D.Lado.JOGADOR), antes)
