extends GutTest
## FOV da câmera (Ciclo 5, Frente 5C): 72 parado, abre pra 80 correndo e volta,
## com interpolação suave a 6/s.

const PlayerScene := preload("res://entities/player/player.tscn")


func _montar_jogador() -> Player:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	player.set_physics_process(false)
	return player


func test_fov_parado_e_72() -> void:
	var player := _montar_jogador()

	assert_eq(player._camera.fov, 72.0)


func test_fov_abre_correndo_sem_passar_de_80() -> void:
	var player := _montar_jogador()

	player._atualizar_fov(0.1, true)
	var fov_apos_um_passo := player._camera.fov
	for i in range(60):
		player._atualizar_fov(0.1, true)

	assert_gt(fov_apos_um_passo, 72.0, "um passo correndo já abre o FOV")
	assert_lt(fov_apos_um_passo, 80.0, "abre devagar, não salta pro máximo")
	assert_almost_eq(player._camera.fov, 80.0, 0.01, "converge pra 80 correndo")


func test_fov_volta_a_72_ao_parar() -> void:
	var player := _montar_jogador()
	for i in range(60):
		player._atualizar_fov(0.1, true)

	for i in range(60):
		player._atualizar_fov(0.1, false)

	assert_almost_eq(player._camera.fov, 72.0, 0.01)
