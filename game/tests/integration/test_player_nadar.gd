extends GutTest
## Sair da água pela superfície (Ciclo 4): com física real, o jogador numa
## piscina de 2 blocos de fundo segurando "pular" precisa alcançar a borda.
## Antes, "na água" só valia pro bloco do centro da cápsula: ao chegar à
## superfície ele saía do modo nado com os pés 0,6 abaixo do topo e caía de
## volta, sem jamais passar da margem.

const PlayerScene := preload("res://entities/player/player.tscn")
const X: int = 20
const Z: int = 20
const Y_CHAO: int = 50
const Y_TOPO_AGUA: int = 52  ## água em y=51 e y=52; o topo da coluna é 53.0
const ALTURA_DOS_PES: float = 0.95


func before_each() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)


func after_each() -> void:
	Input.action_release("pular")
	GameState.mudar_estado(GameState.State.BOOT)


func _drenar(cm: ChunkManager) -> void:
	while cm.tem_chunks_pendentes():
		cm._process(0.0)


func _montar_piscina() -> Player:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)
	_drenar(cm)
	## Piscina 1x1 flutuando acima do terreno: chão sólido, 2 de água e
	## paredes sólidas em volta até 1 bloco acima da água.
	cm.set_block(Vector3i(X, Y_CHAO, Z), 3)
	for y in range(Y_CHAO + 1, Y_TOPO_AGUA + 1):
		cm.set_block(Vector3i(X, y, Z), BlockRegistry.AGUA_ID)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			for y in range(Y_CHAO + 1, Y_TOPO_AGUA + 2):
				cm.set_block(Vector3i(X + dx, y, Z + dz), 3)
	_drenar(cm)

	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	player.global_position = Vector3(X + 0.5, Y_CHAO + 1 + ALTURA_DOS_PES, Z + 0.5)
	player.velocity = Vector3.ZERO
	player.set_physics_process(true)
	return player


func test_segurando_pular_na_piscina_os_pes_passam_do_topo_da_agua() -> void:
	var player := _montar_piscina()
	await wait_physics_frames(2)

	Input.action_press("pular")
	var y_max_pes: float = -INF
	for i in range(90):
		await wait_physics_frames(1)
		y_max_pes = maxf(y_max_pes, player.global_position.y - ALTURA_DOS_PES)
	Input.action_release("pular")

	assert_gte(
		y_max_pes,
		float(Y_TOPO_AGUA + 1),
		"os pés deveriam passar do topo da água (%.1f) pra alcançar a margem" % (Y_TOPO_AGUA + 1)
	)
