extends GutTest
## Ver docs/04-ROADMAP.md F5. Mesmo motivo do F3/F4: clique simulado em canvas
## WebGL não é confiável nesta ferramenta — valida a lógica direto.

const PauseScreenScene := preload("res://ui/pause_screen/pause_screen.tscn")


func after_each() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)
	## A troca de cena real (change_scene_to_file) acontece no fim do quadro;
	## sem descartar a cena que sobra, ela fica na árvore até o fim da suíte e
	## recebe input/muda o GameState no meio dos testes seguintes.
	await get_tree().process_frame
	await get_tree().process_frame
	if get_tree().current_scene != null:
		get_tree().unload_current_scene()


## Dublê de scenes/main.tscn: só registra quantas vezes salvar_jogo foi chamado.
class CenaDuble:
	extends Node
	var chamadas_salvar: int = 0

	func salvar_jogo() -> bool:
		chamadas_salvar += 1
		return true


func _instalar_cena_duble() -> CenaDuble:
	## current_scene precisa ser filho direto de root — por isso não usa add_child_autofree.
	var duble := CenaDuble.new()
	get_tree().root.add_child(duble)
	autofree(duble)
	get_tree().current_scene = duble
	return duble


func _remover_cena_duble(duble: CenaDuble, cena_original: Node) -> void:
	if duble.get_parent() == get_tree().root:
		get_tree().root.remove_child(duble)
	get_tree().current_scene = cena_original


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


func test_salvar_chama_a_cena_e_confirma_no_botao_e_no_rotulo() -> void:
	var cena_original: Node = get_tree().current_scene
	var duble := _instalar_cena_duble()
	var tela: PauseScreen = PauseScreenScene.instantiate()
	add_child_autofree(tela)
	tela._abrir()

	tela._ao_salvar()

	assert_eq(duble.chamadas_salvar, 1)
	assert_eq(tela._rotulo_status.text, "Jogo salvo!")
	assert_eq(tela._botao_salvar.text, "Salvo!")
	_remover_cena_duble(duble, cena_original)


func test_botao_salvar_volta_ao_texto_original_depois_de_um_tempo() -> void:
	var cena_original: Node = get_tree().current_scene
	var duble := _instalar_cena_duble()
	var tela: PauseScreen = PauseScreenScene.instantiate()
	add_child_autofree(tela)
	tela._abrir()
	tela._ao_salvar()

	await get_tree().create_timer(1.7).timeout

	assert_eq(tela._botao_salvar.text, "Salvar")
	_remover_cena_duble(duble, cena_original)


func test_sair_salva_o_jogo_antes_de_voltar_pro_menu() -> void:
	var cena_original: Node = get_tree().current_scene
	var duble := _instalar_cena_duble()
	var tela: PauseScreen = PauseScreenScene.instantiate()
	add_child_autofree(tela)
	tela._abrir()

	tela._ao_sair()

	assert_eq(duble.chamadas_salvar, 1)
	_remover_cena_duble(duble, cena_original)


func test_sair_sem_salvar_jogo_na_cena_nao_quebra() -> void:
	var cena_original: Node = get_tree().current_scene
	var sem_metodo := Node.new()
	get_tree().root.add_child(sem_metodo)
	autofree(sem_metodo)
	get_tree().current_scene = sem_metodo
	var tela: PauseScreen = PauseScreenScene.instantiate()
	add_child_autofree(tela)
	tela._abrir()

	tela._ao_sair()

	assert_false(get_tree().current_scene == sem_metodo, "deveria ter pedido a troca de cena")
	if sem_metodo.get_parent() == get_tree().root:
		get_tree().root.remove_child(sem_metodo)
	get_tree().current_scene = cena_original
