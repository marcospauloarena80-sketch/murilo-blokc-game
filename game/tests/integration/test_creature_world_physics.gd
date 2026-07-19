extends GutTest
## Regressão de risco real do roadmap F7 ("risco médio: steering em terreno
## voxel"). Instancia main.tscn de verdade (mesmo padrão de
## test_main_save_flow.gd), spawna criaturas no mundo gerado de verdade e
## roda física real por várias frames — garante que não travam/erroram ao
## colidir com o terreno voxel real (não só lógica isolada com posições
## sintéticas, como nos outros testes de criatura).

const MainScene := preload("res://scenes/main.tscn")


func before_each() -> void:
	GameState.reiniciar_para_novo_jogo()
	GameState.mudar_estado(GameState.State.PLAYING)


func after_each() -> void:
	GameState.mudar_estado(GameState.State.BOOT)


func _drenar_fila(main_instance: Node3D) -> void:
	var cm: ChunkManager = main_instance.get_node("ChunkManager")
	while cm.tem_chunks_pendentes():
		cm._process(0.0)


func test_criaturas_spawnadas_se_movem_no_mundo_real_sem_erro() -> void:
	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)
	_drenar_fila(main_instance)

	var spawner: CreatureSpawner = main_instance.get_node("CreatureSpawner")
	for i in range(6):
		spawner._tentar_spawnar()

	var criaturas := get_tree().get_nodes_in_group("creature")
	assert_gt(criaturas.size(), 0, "deveria ter conseguido spawnar ao menos 1 criatura")

	var posicoes_iniciais: Dictionary = {}
	for c: Node3D in criaturas:
		posicoes_iniciais[c] = c.global_position

	for frame in range(120):
		for c: Node3D in criaturas:
			if is_instance_valid(c):
				c._physics_process(1.0 / 60.0)

	var alguma_se_moveu := false
	for c: Node3D in criaturas:
		if not is_instance_valid(c):
			continue
		var antes: Vector3 = posicoes_iniciais[c]
		if antes.distance_to(c.global_position) > 0.01:
			alguma_se_moveu = true
	assert_true(alguma_se_moveu, "ao menos uma criatura deveria ter se movido em 2s de física real")


func test_criatura_nao_atravessa_o_chao_apos_fisica_real() -> void:
	var main_instance := MainScene.instantiate()
	add_child_autofree(main_instance)
	_drenar_fila(main_instance)

	var spawner: CreatureSpawner = main_instance.get_node("CreatureSpawner")
	for i in range(6):
		spawner._tentar_spawnar()

	var criaturas := get_tree().get_nodes_in_group("creature")
	assert_gt(criaturas.size(), 0)

	for frame in range(60):
		for c: Node3D in criaturas:
			if is_instance_valid(c):
				c._physics_process(1.0 / 60.0)

	for c: Node3D in criaturas:
		if is_instance_valid(c):
			assert_gt(
				c.global_position.y, 0.0, "criatura não deveria ter caído pro vazio abaixo do mundo"
			)
