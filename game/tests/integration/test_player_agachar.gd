extends GutTest
## Ciclo 8 (8E): agachar (Shift) anda devagar e não cai de bordas.

const PlayerScene := preload("res://entities/player/player.tscn")
const X: int = 20
const Z: int = 20
const Y_CHAO: int = 50
const ALTURA_DOS_PES: float = 0.95


func before_each() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)


func after_each() -> void:
	Input.action_release("agachar")
	Input.action_release("mover_direita")
	GameState.mudar_estado(GameState.State.BOOT)


func _montar_plataforma() -> Player:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)
	while cm.tem_chunks_pendentes():
		cm._process(0.0)
	## Plataforma 3x3 flutuando: x de X-1 a X+1 (borda leste em X+2,0).
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			cm.set_block(Vector3i(X + dx, Y_CHAO, Z + dz), 3)
	while cm.tem_chunks_pendentes():
		cm._process(0.0)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	player.global_position = Vector3(X + 0.5, Y_CHAO + 1 + ALTURA_DOS_PES, Z + 0.5)
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	return player


func test_acao_agachar_e_shift_e_nao_conflita_com_correr() -> void:
	var tecla_agachar: int = -1
	for ev: InputEvent in InputMap.action_get_events("agachar"):
		if ev is InputEventKey:
			tecla_agachar = (ev as InputEventKey).physical_keycode
	assert_eq(tecla_agachar, KEY_SHIFT)
	for ev: InputEvent in InputMap.action_get_events("correr"):
		if ev is InputEventKey:
			assert_ne((ev as InputEventKey).physical_keycode, tecla_agachar)


func test_agachado_na_borda_nao_cai() -> void:
	var player := _montar_plataforma()
	await wait_physics_frames(3)
	Input.action_press("agachar")
	Input.action_press("mover_direita")
	for i in range(120):
		await wait_physics_frames(1)
	assert_true(player.agachado)
	assert_gt(player.global_position.y, Y_CHAO + 1.0, "continua em cima da plataforma")
	assert_lt(player.global_position.x, X + 2.0 + 0.4, "parou na borda")
	assert_gt(player.global_position.x, X + 1.0, "chegou perto da borda")


func test_em_pe_na_mesma_borda_cai() -> void:
	var player := _montar_plataforma()
	await wait_physics_frames(3)
	Input.action_press("mover_direita")
	for i in range(120):
		await wait_physics_frames(1)
	assert_false(player.agachado)
	assert_lt(player.global_position.y, Y_CHAO + 1.0, "sem agachar, cai da plataforma")


func test_agachado_anda_mais_devagar_e_camera_desce() -> void:
	var player := _montar_plataforma()
	await wait_physics_frames(3)
	var y_camera_em_pe := player.camera_pivot.position.y
	Input.action_press("agachar")
	Input.action_press("mover_direita")
	await wait_physics_frames(10)
	assert_almost_eq(player.velocity.x, Player.VELOCIDADE * Player.FATOR_VELOCIDADE_AGACHADO, 0.01)
	assert_almost_eq(
		player.camera_pivot.position.y,
		y_camera_em_pe - Player.DESCIDA_CAMERA_AGACHADO,
		0.1,
		"câmera mais baixa"
	)
