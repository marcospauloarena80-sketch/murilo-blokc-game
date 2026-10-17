extends GutTest
## ADR-034: "Jogo salvo!" só aparece quando a gravação aconteceu de fato; na
## falha o jogador vê um erro inequívoco (e Sair não o joga no menu sem salvar).

const PauseScreenScene := preload("res://ui/pause_screen/pause_screen.tscn")


func before_each() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)


func after_each() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)


func _tela(salvador: Callable) -> PauseScreen:
	var tela: PauseScreen = PauseScreenScene.instantiate()
	add_child_autofree(tela)
	tela.salvador = salvador
	tela._abrir()
	return tela


func test_gravou_mostra_sucesso() -> void:
	var tela := _tela(func() -> bool: return true)

	tela._ao_salvar()

	assert_eq(tela._rotulo_status.text, "Jogo salvo!")
	assert_eq(tela._botao_salvar.text, "Salvo!")
	assert_eq(tela._rotulo_status.get_theme_color("font_color"), PauseScreen.COR_SALVO)


func test_falhou_mostra_erro_e_nunca_diz_salvo() -> void:
	var tela := _tela(func() -> bool: return false)

	tela._ao_salvar()

	assert_eq(tela._rotulo_status.text, "Não foi possível salvar o jogo!")
	assert_false(tela._rotulo_status.text.contains("salvo!"), "sem falsa confirmação")
	assert_eq(tela._botao_salvar.text, "Falhou!")
	assert_eq(tela._rotulo_status.get_theme_color("font_color"), PauseScreen.COR_ERRO)


func test_falha_e_depois_sucesso_troca_a_mensagem() -> void:
	var resultado: Array = [false]
	var tela := _tela(func() -> bool: return resultado[0])
	tela._ao_salvar()

	resultado[0] = true
	tela._ao_salvar()

	assert_eq(tela._rotulo_status.text, "Jogo salvo!")
	assert_eq(tela._rotulo_status.get_theme_color("font_color"), PauseScreen.COR_SALVO)


func test_sair_com_falha_ao_gravar_fica_na_pausa_com_o_erro() -> void:
	var cena_antes: Node = get_tree().current_scene
	var tela := _tela(func() -> bool: return false)

	tela._ao_sair()

	assert_eq(get_tree().current_scene, cena_antes, "não trocou de cena")
	assert_true(tela.visible)
	assert_string_contains(tela._rotulo_status.text, "Não foi possível salvar")
