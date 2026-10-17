extends GutTest
## HUD do Ciclo 6 (Frente 6C): vida em corações, fome em maçãs, cartão de
## objetivo com título/descrição/progresso e dicas de controle nos primeiros
## 25 s de um jogo novo.

const CENA_HUD := preload("res://ui/hud/hud.tscn")

var _acoes_pressionadas: Array[String] = []


func before_each() -> void:
	GameState.reiniciar_para_novo_jogo()
	GameState.mudar_estado(GameState.State.PLAYING)


func after_each() -> void:
	for acao: String in _acoes_pressionadas:
		Input.action_release(acao)
	_acoes_pressionadas.clear()
	GameState.reiniciar_para_novo_jogo()
	GameState.mudar_estado(GameState.State.MENU)


func _criar_hud() -> Hud:
	var hud: Hud = CENA_HUD.instantiate()
	add_child_autofree(hud)
	return hud


func _pressionar(acao: String) -> void:
	Input.action_press(acao)
	_acoes_pressionadas.append(acao)


func _contar_texturas(nos: Array[TextureRect], textura: Texture2D) -> int:
	var total := 0
	for no: TextureRect in nos:
		if no.texture == textura:
			total += 1
	return total


func test_vida_13_mostra_6_cheios_1_meio_e_3_vazios() -> void:
	var hud := _criar_hud()
	GameState.vida_atual = 13

	hud._process(0.0)

	assert_eq(hud._coracoes.size(), 10, "20 de vida = 10 corações")
	assert_eq(_contar_texturas(hud._coracoes, hud._tex_cheio), 6)
	assert_eq(_contar_texturas(hud._coracoes, hud._tex_meio), 1)
	assert_eq(_contar_texturas(hud._coracoes, hud._tex_vazio), 3)
	assert_same(hud._coracoes[6].texture, hud._tex_meio, "o meio coração vem logo após os cheios")
	assert_false(hud._barra_vida.visible, "a barra antiga fica escondida")


func test_vida_cheia_mostra_10_cheios_e_vida_zero_10_vazios() -> void:
	var hud := _criar_hud()
	GameState.vida_atual = 20
	hud._process(0.0)
	assert_eq(_contar_texturas(hud._coracoes, hud._tex_cheio), 10)

	GameState.vida_atual = 0
	hud._process(0.0)
	assert_eq(_contar_texturas(hud._coracoes, hud._tex_vazio), 10)


func test_fome_20_mostra_10_macas_cheias_e_fome_7_mostra_3_cheias() -> void:
	var hud := _criar_hud()
	GameState.fome_atual = 20
	hud._process(0.0)
	assert_eq(hud._macas.size(), 10)
	assert_eq(_contar_texturas(hud._macas, hud._tex_maca_cheia), 10)

	GameState.fome_atual = 7
	hud._process(0.0)
	assert_eq(_contar_texturas(hud._macas, hud._tex_maca_cheia), 3, "7 de fome = 3 maçãs inteiras")
	assert_eq(_contar_texturas(hud._macas, hud._tex_maca_vazia), 7)


func test_barra_de_energia_so_aparece_com_energia_abaixo_do_maximo() -> void:
	var hud := _criar_hud()
	GameState.energia_atual = GameState.energia_maxima
	hud._process(0.0)
	assert_false(hud._barra_energia.visible)

	GameState.energia_atual = 12
	hud._process(0.0)
	assert_true(hud._barra_energia.visible)
	assert_eq(hud._barra_energia.value, 12.0)


func test_cartao_mostra_nome_descricao_e_progresso_da_missao() -> void:
	var hud := _criar_hud()
	GameState.iniciar_quest("quest_01_boas_vindas")
	GameState.progresso_quest_atual = 2

	hud._process(0.0)

	assert_true(hud._cartao_objetivo.visible)
	assert_eq(hud._label_titulo_cartao.text, "Boas-vindas ao Vale")
	assert_string_contains(hud._label_descricao_cartao.text, "(2/5)")
	assert_eq(hud._barra_cartao.max_value, 5.0)
	assert_eq(hud._barra_cartao.value, 2.0)
	assert_string_contains(Hud.texto_objetivo(), "(2/5)", "texto_objetivo() continua existindo")


func test_cartao_sem_missao_mostra_a_dica_da_lina() -> void:
	var hud := _criar_hud()

	hud._process(0.0)

	assert_true(hud._cartao_objetivo.visible)
	assert_string_contains(hud._label_descricao_cartao.text, "Lina")
	assert_false(hud._barra_cartao.visible, "sem missão não há barra de progresso")


func test_cartao_pulsa_quando_o_progresso_muda() -> void:
	var hud := _criar_hud()
	GameState.iniciar_quest("quest_01_boas_vindas")
	hud._process(0.0)
	assert_null(hud._tween_cartao, "sem mudança de progresso, sem pulso")

	GameState.progresso_quest_atual = 1
	hud._process(0.0)

	assert_not_null(hud._tween_cartao)
	assert_true(hud._tween_cartao.is_running())


func test_dicas_visiveis_no_comeco_e_invisiveis_depois_de_25_s() -> void:
	var hud := _criar_hud()
	GameState.tempo_de_jogo_seg = 0.0
	hud._process(0.0)
	assert_true(hud._label_dicas.visible)
	assert_string_contains(hud._label_dicas.text, "WASD anda")
	assert_string_contains(hud._label_dicas.text, "Esc pausa")

	GameState.tempo_de_jogo_seg = 30.0
	hud._process(0.0)
	assert_false(hud._label_dicas.visible)


func test_dica_some_quando_a_tecla_correspondente_e_pressionada() -> void:
	var hud := _criar_hud()
	GameState.tempo_de_jogo_seg = 0.0
	hud._process(0.0)
	assert_string_contains(hud._label_dicas.text, "Espaço pula")

	_pressionar("pular")
	hud._process(0.0)

	assert_false(hud._label_dicas.text.contains("Espaço pula"), "pulou: a dica do pulo some")
	assert_string_contains(hud._label_dicas.text, "WASD anda", "as outras ficam")


func test_toast_tem_fundo_e_esmaece_antes_de_sumir() -> void:
	var hud := _criar_hud()
	hud._mostrar_aviso("+1 Tronco", false)
	assert_true(hud._painel_aviso.visible)
	var fundo: StyleBoxFlat = hud._painel_aviso.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(fundo, "o toast tem fundo próprio")
	assert_gt(fundo.corner_radius_top_left, 0, "cantos arredondados")
	assert_eq(hud._painel_aviso.modulate.a, 1.0)

	hud._process(Hud.DURACAO_AVISO_SEG - Hud.FADE_AVISO_SEG / 2.0)

	assert_true(hud._painel_aviso.visible, "na metade do fade ainda aparece")
	assert_almost_eq(hud._painel_aviso.modulate.a, 0.5, 0.05, "meio transparente")

	hud._process(Hud.FADE_AVISO_SEG)
	assert_false(hud._painel_aviso.visible)
	assert_false(hud._label_aviso.visible)
