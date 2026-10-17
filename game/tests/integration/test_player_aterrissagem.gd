extends GutTest
## Poeira ao aterrissar (Ciclo 5, Frente 5C): o Player emite
## EventBus.player_landed ao tocar o chão depois de cair mais de 1,5 bloco,
## com física real (mesmo padrão de test_player_nadar.gd).

const PlayerScene := preload("res://entities/player/player.tscn")
const X: int = 20
const Z: int = 20
const Y_CHAO: int = 50  ## plataforma flutuando acima do terreno; o topo é 51.0
const ALTURA_DOS_PES: float = 0.95


func before_each() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)


func after_each() -> void:
	GameState.mudar_estado(GameState.State.BOOT)


func _drenar(cm: ChunkManager) -> void:
	while cm.tem_chunks_pendentes():
		cm._process(0.0)


func _montar_plataforma(altura_queda: float) -> Player:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)
	_drenar(cm)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			cm.set_block(Vector3i(X + dx, Y_CHAO, Z + dz), 3)
	_drenar(cm)

	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	player.global_position = Vector3(X + 0.5, Y_CHAO + 1 + altura_queda + ALTURA_DOS_PES, Z + 0.5)
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	return player


func _esperar_tocar_o_chao(player: Player, quadros_max: int) -> void:
	for i in range(quadros_max):
		await wait_physics_frames(1)
		if player.is_on_floor():
			break
	await wait_physics_frames(2)


func test_cair_2_blocos_emite_player_landed_nos_pes() -> void:
	var player := _montar_plataforma(2.0)
	watch_signals(EventBus)

	await _esperar_tocar_o_chao(player, 90)

	assert_signal_emitted(EventBus, "player_landed", "deveria avisar a aterrissagem")
	var parametros: Array = get_signal_parameters(EventBus, "player_landed")
	if parametros == null:
		return
	var pos: Vector3 = parametros[0]
	var altura: float = parametros[1]
	assert_almost_eq(pos.y, float(Y_CHAO + 1), 0.3, "a poeira sai nos pés, junto do chão")
	assert_almost_eq(altura, 2.0, 0.5, "altura da queda aproximada")


func test_descer_meio_bloco_nao_emite_player_landed() -> void:
	var player := _montar_plataforma(0.5)
	watch_signals(EventBus)

	await _esperar_tocar_o_chao(player, 60)

	assert_signal_not_emitted(EventBus, "player_landed", "queda curta não levanta poeira")
