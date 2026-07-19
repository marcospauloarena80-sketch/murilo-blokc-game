extends GutTest
## Ver docs/07-DECISOES.md ADR-025 — joystick flutuante (mover) + arrasto
## (olhar) precisam funcionar ao mesmo tempo (2 dedos), por isso usa
## InputEventScreenTouch/Drag com índice direto em vez de emulação de mouse
## (que só suporta 1 ponteiro).

const TouchControlsScene := preload("res://ui/touch_controls/touch_controls.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")
const ACOES_MOVIMENTO := ["mover_frente", "mover_tras", "mover_esquerda", "mover_direita"]


func after_each() -> void:
	for acao: String in ACOES_MOVIMENTO:
		Input.action_release(acao)


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


func test_botoes_de_acao_ficam_visiveis_mesmo_sem_tela_de_toque() -> void:
	## Regressão: clicar-e-segurar (mouse/trackpad) pra minerar podia falhar
	## dependendo do navegador/hardware (achado real: Chrome/Mac, ADR-026) —
	## os botões de ação são Button comuns, então ficam visíveis em qualquer
	## plataforma como alternativa clicável, não só quando há tela de toque.
	var controles := TouchControlsScene.instantiate() as TouchControls
	add_child_autofree(controles)

	assert_true(controles.visible, "os botões de ação devem ficar visíveis")
	assert_false(controles.get_node("Joystick").visible, "joystick continua só sob demanda")


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
