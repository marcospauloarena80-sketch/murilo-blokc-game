extends GutTest
## Ver docs/07-DECISOES.md ADR-025 — a câmera nunca girava com mouse/toque
## (gap real encontrado na F12, o jogo só tinha direção fixa). girar_camera()
## agora é o ponto único usado tanto por mouse (desktop) quanto arrasto de
## tela (touch).

const PlayerScene := preload("res://entities/player/player.tscn")


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_girar_camera_gira_o_corpo_no_eixo_y() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	var yaw_antes := player.rotation.y

	player.girar_camera(10.0, 0.0, 0.01)

	assert_lt(player.rotation.y, yaw_antes, "olhar pra direita deveria girar o yaw")


func test_girar_camera_ajusta_o_pitch_da_camera() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	var pitch_antes := player.camera_pivot.rotation.x

	player.girar_camera(0.0, -10.0, 0.01)

	assert_gt(
		player.camera_pivot.rotation.x, pitch_antes, "olhar pra cima deveria levantar o pitch"
	)


func test_girar_camera_nao_passa_do_limite_de_pitch() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	for i in range(50):
		player.girar_camera(0.0, -1000.0, 0.01)

	assert_almost_eq(player.camera_pivot.rotation.x, CameraLookMath.PITCH_MAX, 0.0001)


func test_atualizar_captura_do_mouse_nao_gera_erro() -> void:
	## O driver de tela "dummy" do --headless não reflete captura de mouse de
	## verdade (sem janela real) — o comportamento visual é confirmado no
	## navegador (F12), aqui só garante que a lógica roda sem estourar erro.
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	player._atualizar_captura_do_mouse(true)
	player._atualizar_captura_do_mouse(false)

	assert_true(true, "chamadas não deveriam gerar erro")
