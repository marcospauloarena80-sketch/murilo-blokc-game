extends GutTest
## Ver docs/04-ROADMAP.md F5. Mesmo motivo do F3/F4: clique simulado em canvas
## WebGL não é confiável nesta ferramenta — valida a lógica direto.

const PauseScreenScene := preload("res://ui/pause_screen/pause_screen.tscn")


func test_abrir_pausa_o_jogo() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)
	var tela: PauseScreen = PauseScreenScene.instantiate()
	add_child_autofree(tela)

	tela._abrir()

	assert_true(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PAUSED)


func test_fechar_volta_a_jogar() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)
	var tela: PauseScreen = PauseScreenScene.instantiate()
	add_child_autofree(tela)

	tela._abrir()
	tela._fechar()

	assert_false(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PLAYING)
