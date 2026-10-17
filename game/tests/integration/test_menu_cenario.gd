extends GutTest
## Frente 6D — menu com o mundo ao fundo: um ChunkManager pequeno (3x3 chunks
## do centro, raio_chunks = 1) dentro de um SubViewport com o céu do jogo e
## uma câmera orbitando devagar o centro do mundo. Título com contorno
## dourado, subtítulo e botão Opções.

const MenuScene := preload("res://scenes/menu.tscn")
const CENTRO := Vector3(64, 34, 64)


func after_each() -> void:
	GameState.veio_de_continuar = false
	GameState.posicao_salva = Vector3(64, 45, 64)
	GameState.mudar_estado(GameState.State.MENU)


func _cenario(menu: Node) -> Node3D:
	return menu.get_node("Cenario3D/SubViewport/Cenario")


func _drenar(cm: ChunkManager) -> void:
	while cm.tem_chunks_pendentes():
		cm._process(0.0)


func test_cenario_tem_ceu_luz_chunks_e_camera() -> void:
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)
	var cenario := _cenario(menu)

	var ambiente: WorldEnvironment = cenario.get_node("WorldEnvironment")
	assert_not_null(ambiente.environment.sky, "o menu usa o céu do jogo")
	assert_true(ambiente.environment.sky.sky_material is ShaderMaterial)
	assert_not_null(cenario.get_node("DirectionalLight3D"))
	var camera: Camera3D = cenario.get_node("Camera3D")
	assert_true(camera.current)
	var cm: ChunkManager = cenario.get_node("ChunkManager")
	assert_eq(cm.raio_chunks, 1, "só os 3x3 chunks do centro")


func test_cenario_gera_so_os_nove_chunks_do_centro() -> void:
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)
	var cm: ChunkManager = _cenario(menu).get_node("ChunkManager")

	_drenar(cm)

	assert_eq(cm._chunks.size(), 9)
	assert_true(cm._chunks.has(Vector2i(4, 4)))
	assert_false(cm.tem_chunks_pendentes())


func test_mesmo_com_save_anterior_o_centro_e_o_do_mundo() -> void:
	## Sem Player, o ChunkManager usaria a posição salva de um Continuar anterior;
	## no menu a câmera olha pro centro do mundo, então os chunks têm que ser os do centro.
	GameState.veio_de_continuar = true
	GameState.posicao_salva = Vector3(5, 40, 5)
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)
	var cm: ChunkManager = _cenario(menu).get_node("ChunkManager")

	_drenar(cm)

	assert_true(cm._chunks.has(Vector2i(4, 4)))
	assert_false(cm._chunks.has(Vector2i(0, 0)))


func test_camera_orbita_o_centro_devagar_olhando_pra_ele() -> void:
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)
	var camera: Camera3D = _cenario(menu).get_node("Camera3D")

	menu._process(0.0)
	var antes := camera.global_position
	menu._process(1.0)
	var depois := camera.global_position

	assert_almost_eq(depois.y, 42.0, 0.01, "altura fixa")
	var horizontal := Vector2(depois.x - CENTRO.x, depois.z - CENTRO.z)
	assert_almost_eq(horizontal.length(), 22.0, 0.01, "raio fixo")
	var angulo := Vector2(antes.x - CENTRO.x, antes.z - CENTRO.z).angle_to(horizontal)
	assert_almost_eq(absf(angulo), 0.08, 0.001, "0,08 rad por segundo")
	var frente := -camera.global_transform.basis.z
	assert_almost_eq(frente.dot((CENTRO - depois).normalized()), 1.0, 0.001, "olha pro centro")


func test_titulo_subtitulo_e_botoes() -> void:
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)

	var titulo: Label = menu.get_node("VBox/Titulo")
	assert_eq(titulo.text, "Murilo Blocks Game")
	assert_eq(titulo.get_theme_font_size("font_size"), 56)
	assert_gt(titulo.get_theme_constant("outline_size"), 0, "contorno dourado")
	assert_eq(menu.get_node("VBox/Subtitulo").text, "Vale Dourado")
	assert_eq(menu.get_node("VBox/BotaoNovoJogo").text, "Novo Jogo")
	assert_eq(menu.get_node("VBox/BotaoContinuar").text, "Continuar")
	assert_eq(menu.get_node("VBox/BotaoOpcoes").text, "Opções")


func test_botao_opcoes_abre_a_tela_de_opcoes_sem_sair_do_menu() -> void:
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)
	var opcoes: OptionsScreen = menu.get_node("OptionsScreen")
	opcoes.caminho_cfg = "user://opcoes_teste.cfg"

	menu.get_node("VBox/BotaoOpcoes").pressed.emit()

	assert_true(opcoes.visible)
	assert_eq(GameState.current_state, GameState.State.MENU)
