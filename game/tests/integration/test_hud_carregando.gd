extends GutTest
## Regressão: mundo gerando aos poucos (meshing time-sliced) parecia jogo
## travado — sem aviso na tela enquanto ChunkManager.tem_chunks_pendentes()
## é true. Ver ADR-026.


func after_each() -> void:
	GameState.mudar_estado(GameState.State.MENU)


func test_label_carregando_visivel_enquanto_mundo_gera_e_some_ao_terminar() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)

	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)

	var hud: Hud = preload("res://ui/hud/hud.tscn").instantiate()
	add_child_autofree(hud)

	hud._process(0.0)
	assert_true(hud._label_carregando.visible, "deveria avisar que o mundo está gerando")

	while cm.tem_chunks_pendentes():
		cm._process(0.0)

	hud._process(0.0)
	assert_false(hud._label_carregando.visible, "deveria sumir quando o mundo termina de gerar")
