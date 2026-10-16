extends GutTest
## Ver docs/01-GDD.md §13 e docs/07-DECISOES.md ADR-023.

const CreditsScreenScene := preload("res://ui/credits_screen/credits_screen.tscn")


func after_each() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)
	## A troca de cena real (change_scene_to_file) acontece no fim do quadro;
	## sem descartar a cena que sobra, ela fica na árvore até o fim da suíte e
	## recebe input/muda o GameState no meio dos testes seguintes.
	await get_tree().process_frame
	await get_tree().process_frame
	if get_tree().current_scene != null:
		get_tree().unload_current_scene()


func test_comeca_escondida() -> void:
	var tela := CreditsScreenScene.instantiate() as CreditsScreen
	add_child_autofree(tela)

	assert_false(tela.visible)


func test_game_completed_abre_e_pausa() -> void:
	var tela := CreditsScreenScene.instantiate() as CreditsScreen
	add_child_autofree(tela)

	EventBus.game_completed.emit()

	assert_true(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PAUSED)


func test_abrir_mostra_creditos_da_engine_e_do_autor() -> void:
	var tela := CreditsScreenScene.instantiate() as CreditsScreen
	add_child_autofree(tela)

	tela._abrir()

	assert_true(tela._label_texto.text.contains("Godot Engine"))
	assert_true(tela._label_texto.text.contains("Murilo"))


func test_voltar_esconde_a_tela() -> void:
	var tela := CreditsScreenScene.instantiate() as CreditsScreen
	add_child_autofree(tela)
	tela._abrir()

	tela._botao_voltar.pressed.emit()

	assert_false(tela.visible)
