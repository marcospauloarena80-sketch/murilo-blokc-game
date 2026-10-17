extends GutTest
## Ver docs/07-DECISOES.md ADR-025 — joystick flutuante (mover) + arrasto
## (olhar) precisam funcionar ao mesmo tempo (2 dedos), por isso usa
## InputEventScreenTouch/Drag com índice direto em vez de emulação de mouse
## (que só suporta 1 ponteiro).

const TouchControlsScene := preload("res://ui/touch_controls/touch_controls.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")
const InventoryScreenScene := preload("res://ui/inventory_screen/inventory_screen.tscn")
const PauseScreenScene := preload("res://ui/pause_screen/pause_screen.tscn")
const ACOES_MOVIMENTO := ["mover_frente", "mover_tras", "mover_esquerda", "mover_direita"]
const ACOES_POR_EVENTO := ["inventario", "pausar"]


func before_each() -> void:
	## Testes anteriores da suíte (test_menu_fluxo_completo) trocam de cena de
	## verdade e deixam um Main inteiro pendente/na árvore, com InventoryScreen
	## e PauseScreen próprios que receberiam o InputEventAction antes dos nós
	## deste teste. Flusha a troca pendente e descarta a sobra.
	await get_tree().process_frame
	if get_tree().current_scene != null:
		get_tree().unload_current_scene()


func after_each() -> void:
	for acao: String in ACOES_MOVIMENTO + ACOES_POR_EVENTO:
		Input.action_release(acao)
	GameState.mudar_estado(GameState.State.PLAYING)


func _metade_da_tela() -> float:
	return get_viewport().get_visible_rect().size.x / 2.0


func _toque(index: int, posicao: Vector2, pressionado: bool) -> InputEventScreenTouch:
	var evento := InputEventScreenTouch.new()
	evento.index = index
	evento.position = posicao
	evento.pressed = pressionado
	return evento


func _arrasto(index: int, posicao: Vector2, relativo: Vector2) -> InputEventScreenDrag:
	var evento := InputEventScreenDrag.new()
	evento.index = index
	evento.position = posicao
	evento.relative = relativo
	return evento


func _controles_com_toque() -> TouchControls:
	var controles := TouchControlsScene.instantiate() as TouchControls
	controles.forcar_toque = true
	add_child_autofree(controles)
	return controles


func test_botoes_de_acao_ficam_escondidos_sem_tela_de_toque() -> void:
	## No desktop os botões cobriam o "Jogar" do criador de personagem e
	## poluíam a tela; o caso do trackpad (ADR-026) hoje é coberto pelas
	## teclas Q/C. No ambiente de teste headless não há tela de toque.
	var controles := TouchControlsScene.instantiate() as TouchControls
	add_child_autofree(controles)

	assert_false(controles.get_node("Acoes").visible, "botões de ação só com tela de toque")
	assert_false(controles.get_node("Pausa").visible, "botão de pausa só com tela de toque")
	assert_false(controles.get_node("Joystick").visible, "joystick continua só sob demanda")


func test_botoes_de_acao_ficam_visiveis_com_tela_de_toque() -> void:
	var controles := _controles_com_toque()

	assert_true(controles.get_node("Acoes").visible, "botões de ação aparecem com tela de toque")
	assert_true(controles.get_node("Pausa").visible, "botão de pausa aparece com tela de toque")
	assert_false(controles.get_node("Joystick").visible, "joystick continua só sob demanda")


func test_botao_bolsa_abre_o_inventario() -> void:
	## Regressão: Input.action_press não gera InputEvent, e o InventoryScreen
	## abre em _unhandled_input — o botão precisa despachar um InputEventAction.
	var inventario := InventoryScreenScene.instantiate() as InventoryScreen
	add_child_autofree(inventario)
	var controles := _controles_com_toque()
	GameState.mudar_estado(GameState.State.PLAYING)

	controles._botao_inventario.button_down.emit()
	controles._botao_inventario.button_up.emit()
	await get_tree().process_frame
	await get_tree().process_frame

	assert_true(inventario.visible, "a Bolsa deve abrir o inventário")
	assert_eq(GameState.current_state, GameState.State.PAUSED)


func test_botao_pausa_abre_a_tela_de_pausa() -> void:
	var pausa := PauseScreenScene.instantiate() as PauseScreen
	add_child_autofree(pausa)
	var controles := _controles_com_toque()
	GameState.mudar_estado(GameState.State.PLAYING)

	controles._botao_pausa.button_down.emit()
	controles._botao_pausa.button_up.emit()
	await get_tree().process_frame
	await get_tree().process_frame

	assert_true(pausa.visible, "o botão Pausa deve abrir a tela de pausa")
	assert_eq(GameState.current_state, GameState.State.PAUSED)


func test_tocar_no_lado_esquerdo_mostra_o_joystick() -> void:
	var controles := TouchControlsScene.instantiate() as TouchControls
	add_child_autofree(controles)
	controles.visible = true

	controles._ao_tocar(_toque(0, Vector2(_metade_da_tela() * 0.5, 0), true))

	assert_true(controles.get_node("Joystick").visible)


func test_tocar_no_lado_direito_nao_mostra_joystick() -> void:
	var controles := TouchControlsScene.instantiate() as TouchControls
	add_child_autofree(controles)
	controles.visible = true

	controles._ao_tocar(_toque(1, Vector2(_metade_da_tela() * 1.5, 0), true))

	assert_false(controles.get_node("Joystick").visible)


func test_arrastar_o_joystick_pra_frente_aciona_mover_frente() -> void:
	var controles := TouchControlsScene.instantiate() as TouchControls
	add_child_autofree(controles)
	controles.visible = true
	var origem := Vector2(_metade_da_tela() * 0.5, 100)
	controles._ao_tocar(_toque(0, origem, true))

	controles._ao_arrastar(_arrasto(0, origem + Vector2(0, -40), Vector2(0, -40)))

	assert_true(Input.is_action_pressed("mover_frente"))


func test_soltar_o_joystick_esconde_e_zera_as_acoes() -> void:
	var controles := TouchControlsScene.instantiate() as TouchControls
	add_child_autofree(controles)
	controles.visible = true
	var origem := Vector2(_metade_da_tela() * 0.5, 100)
	controles._ao_tocar(_toque(0, origem, true))
	controles._ao_arrastar(_arrasto(0, origem + Vector2(0, -40), Vector2(0, -40)))

	controles._ao_tocar(_toque(0, origem + Vector2(0, -40), false))

	assert_false(controles.get_node("Joystick").visible)
	assert_false(Input.is_action_pressed("mover_frente"))


func test_arrastar_no_lado_direito_gira_a_camera_do_jogador() -> void:
	var jogador := PlayerScene.instantiate() as Player
	add_child_autofree(jogador)
	var controles := TouchControlsScene.instantiate() as TouchControls
	add_child_autofree(controles)
	controles.visible = true
	var origem := Vector2(_metade_da_tela() * 1.5, 100)
	controles._ao_tocar(_toque(1, origem, true))
	var yaw_antes := jogador.rotation.y

	controles._ao_arrastar(_arrasto(1, origem + Vector2(50, 0), Vector2(50, 0)))

	assert_ne(jogador.rotation.y, yaw_antes)


func test_dois_dedos_ao_mesmo_tempo_movem_e_olham() -> void:
	var jogador := PlayerScene.instantiate() as Player
	add_child_autofree(jogador)
	var controles := TouchControlsScene.instantiate() as TouchControls
	add_child_autofree(controles)
	controles.visible = true
	var origem_esquerda := Vector2(_metade_da_tela() * 0.5, 100)
	var origem_direita := Vector2(_metade_da_tela() * 1.5, 100)
	var yaw_antes := jogador.rotation.y

	controles._ao_tocar(_toque(0, origem_esquerda, true))
	controles._ao_tocar(_toque(1, origem_direita, true))
	controles._ao_arrastar(_arrasto(0, origem_esquerda + Vector2(0, -40), Vector2(0, -40)))
	controles._ao_arrastar(_arrasto(1, origem_direita + Vector2(50, 0), Vector2(50, 0)))

	assert_true(Input.is_action_pressed("mover_frente"))
	assert_ne(jogador.rotation.y, yaw_antes)


func test_botoes_nao_guardam_foco_de_teclado() -> void:
	## Num aparelho com toque e teclado, Espaço/Enter reativavam o último
	## botão tocado (a Bolsa reabria o inventário a cada pulo).
	var controles := _controles_com_toque()

	for caminho: String in [
		"Acoes/BotaoPular",
		"Acoes/BotaoQuebrar",
		"Acoes/BotaoColocar",
		"Acoes/BotaoInteragir",
		"Acoes/BotaoInventario",
		"Pausa/BotaoPausa"
	]:
		var botao: Button = controles.get_node(caminho)
		assert_eq(botao.focus_mode, Control.FOCUS_NONE, "%s sem foco de teclado" % caminho)


func test_botoes_somem_na_criacao_de_personagem_e_voltam_jogando() -> void:
	## Com tela de toque os botões cobriam a metade direita do "Jogar".
	var controles := _controles_com_toque()
	GameState.mudar_estado(GameState.State.CHARACTER_CREATION)
	await get_tree().process_frame

	assert_false(controles.get_node("Acoes").visible, "botões de ação escondidos ao criar o Murilo")
	assert_false(controles.get_node("Pausa").visible, "pausa escondida ao criar o Murilo")

	GameState.mudar_estado(GameState.State.PLAYING)
	await get_tree().process_frame

	assert_true(controles.get_node("Acoes").visible)
	assert_true(controles.get_node("Pausa").visible)


func _controles_com_jogador() -> Array:
	var jogador: Player = autofree(PlayerScene.instantiate())
	add_child(jogador)
	var controles: Node = autofree(TouchControlsScene.instantiate())
	controles.forcar_toque = true
	add_child(controles)
	return [controles, jogador]


func test_botoes_de_poder_so_aparecem_com_tela_de_toque() -> void:
	var controles: Node = autofree(TouchControlsScene.instantiate())
	add_child(controles)
	assert_false(controles.get_node("Poderes").visible, "sem toque, sem botões de poder")
	var com_toque: Node = autofree(TouchControlsScene.instantiate())
	com_toque.forcar_toque = true
	add_child(com_toque)
	assert_true(com_toque.get_node("Poderes").visible)


func test_seta_cima_duas_vezes_voa_e_seta_baixo_pousa() -> void:
	var par := _controles_com_jogador()
	var controles: Node = par[0]
	var jogador: Player = par[1]
	controles._ao_apertar_cima()
	controles._ao_soltar_cima()
	controles._ao_apertar_cima()
	controles._ao_soltar_cima()
	assert_true(jogador.poderes.voando, "dois toques ativam o voo")
	controles._ao_apertar_baixo()
	assert_false(jogador.poderes.voando, "seta para baixo para de voar")
	Input.action_release("agachar")
	Input.action_release("pular")


func test_botao_turbo_alterna_a_velocidade() -> void:
	var par := _controles_com_jogador()
	var controles: Node = par[0]
	var jogador: Player = par[1]
	controles._ao_apertar_turbo()
	assert_true(jogador.poderes.turbo)
	controles._ao_apertar_turbo()
	assert_false(jogador.poderes.turbo)
