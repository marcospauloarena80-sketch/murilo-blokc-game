extends GutTest
## Regressão do bug real da F2: física do player rodava mais rápido que o
## meshing time-sliced, atravessando o chão inteiro (ADR-014). O player deve
## começar com a física pausada e só ligar quando o mundo termina de gerar.


func test_fisica_do_player_comeca_pausada_e_liga_apos_mundo_pronto() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)

	var player := preload("res://entities/player/player.tscn").instantiate()
	add_child_autofree(player)

	assert_false(player.is_physics_processing(), "física deveria começar pausada")

	while cm.tem_chunks_pendentes():
		cm._process(0.0)

	assert_true(player.is_physics_processing(), "física deveria ligar após mundo_gerado")
