extends GutTest
## Regressões do HUD jogando o build real: o aviso (toast) aparecia cortado na
## borda esquerda, e a hotbar criava 8 StyleBoxFlat novos por quadro.

const CENA_HUD := preload("res://ui/hud/hud.tscn")
## Headless a janela tem 64 px de largura; o toast precisa da tela do jogo.
const TAMANHO_TELA := Vector2i(1152, 648)

var _tamanho_janela_original: Vector2i


func before_each() -> void:
	_tamanho_janela_original = get_window().size
	get_window().size = TAMANHO_TELA


func after_each() -> void:
	get_window().size = _tamanho_janela_original
	GameState.hotbar_selecionado = 0


func _criar_hud() -> Hud:
	var hud: Hud = CENA_HUD.instantiate()
	add_child_autofree(hud)
	return hud


func test_aviso_fica_centrado_na_largura_da_tela() -> void:
	var hud := _criar_hud()

	hud._mostrar_aviso("Missão concluída: Boas-vindas ao Vale!", true)
	await get_tree().process_frame
	await get_tree().process_frame

	var rect: Rect2 = hud._label_aviso.get_global_rect()
	var centro_tela: float = get_viewport().get_visible_rect().size.x / 2.0
	assert_gte(rect.position.x, 0.0, "o aviso não pode começar fora da tela")
	assert_almost_eq(rect.get_center().x, centro_tela, 4.0, "o aviso deveria ficar centrado")


func test_slot_mantem_o_mesmo_stylebox_entre_quadros_sem_mudanca() -> void:
	GameState.hotbar_selecionado = 0
	var hud := _criar_hud()

	hud._process(0.0)
	var estilo_slot_0: StyleBox = hud._botoes[0].get_theme_stylebox("normal")
	var estilo_slot_1: StyleBox = hud._botoes[1].get_theme_stylebox("normal")
	hud._process(0.0)

	assert_same(hud._botoes[0].get_theme_stylebox("normal"), estilo_slot_0)
	assert_same(hud._botoes[1].get_theme_stylebox("normal"), estilo_slot_1)


func test_mudar_selecao_troca_o_stylebox_do_slot_novo_para_o_selecionado() -> void:
	GameState.hotbar_selecionado = 0
	var hud := _criar_hud()
	hud._process(0.0)
	var estilo_antes: StyleBox = hud._botoes[2].get_theme_stylebox("normal")

	GameState.hotbar_selecionado = 2
	hud._process(0.0)

	var estilo_depois: StyleBoxFlat = hud._botoes[2].get_theme_stylebox("normal") as StyleBoxFlat
	assert_same(estilo_depois, hud._estilos_selecionado[2])
	assert_ne(estilo_depois, estilo_antes, "o slot novo deveria trocar para o estilo selecionado")
	assert_eq(estilo_depois.border_width_left, 3)
	assert_eq(estilo_depois.border_color, Color.WHITE)
	var estilo_slot_0: StyleBoxFlat = hud._botoes[0].get_theme_stylebox("normal") as StyleBoxFlat
	assert_same(estilo_slot_0, hud._estilos_normal[0])
	assert_eq(estilo_slot_0.border_width_left, 0)


func test_aviso_nao_expira_enquanto_uma_tela_cobre_o_jogo() -> void:
	## Missão concluída dentro da batalha ou do inventário: o aviso contava
	## tempo coberto pela tela e já tinha sumido quando o jogador voltava.
	var hud := _criar_hud()
	GameState.mudar_estado(GameState.State.PAUSED)
	hud._mostrar_aviso("Missão concluída!", true)

	hud._process(Hud.DURACAO_AVISO_IMPORTANTE_SEG + 1.0)

	assert_true(hud._label_aviso.visible, "pausado, o aviso espera a tela fechar")
	GameState.mudar_estado(GameState.State.PLAYING)
	hud._process(Hud.DURACAO_AVISO_IMPORTANTE_SEG + 1.0)
	assert_false(hud._label_aviso.visible, "jogando, o aviso expira normalmente")
