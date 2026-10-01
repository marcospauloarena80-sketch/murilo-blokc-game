extends GutTest
## Regressão do bug que deixou o jogo sem progressão desde a F2 (ADR-027): o
## raio de mira saía da câmera (6 blocos atrás) com alcance 5 e nunca chegava a
## bloco, NPC ou criatura. Este teste monta jogador e câmera reais, diante de
## uma parede real, e usa a física de verdade (nada de chamar o handler de
## quebrar direto).

const PlayerScene := preload("res://entities/player/player.tscn")


func _drenar(cm: ChunkManager) -> void:
	while cm.tem_chunks_pendentes():
		cm._process(0.0)


func _montar_cena() -> Player:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)
	_drenar(cm)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	player.set_physics_process(false)
	player.global_position = Vector3(20.5, 58.0, 20.5)
	## Parede de pedra flutuando acima do terreno, 3 blocos à frente (o
	## jogador olha pra -Z).
	for dx in range(-2, 3):
		for dy in range(-5, 3):
			cm.set_block(Vector3i(20 + dx, 58 + dy, 17), 3)
	_drenar(cm)
	return player


func test_mira_acerta_a_parede_a_frente() -> void:
	var player := _montar_cena()
	await wait_physics_frames(3)

	var resultado := player._raycast_mira()

	assert_false(resultado.is_empty(), "a mira deveria alcançar a parede")
	assert_almost_eq((resultado["position"] as Vector3).z, 18.0, 0.01, "face sul do bloco z=17")
	assert_gt(
		(resultado["normal"] as Vector3).z,
		0.5,
		"normal virada pro jogador: senão o bloco mirado e o de colocar saem trocados"
	)


func test_mira_nunca_acerta_o_proprio_jogador() -> void:
	var player := _montar_cena()
	await wait_physics_frames(3)

	var resultado := player._raycast_mira()

	assert_ne(resultado.get("collider"), player)
