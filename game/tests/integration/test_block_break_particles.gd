extends GutTest
## Ver docs/07-DECISOES.md ADR-024. Chama o handler privado direto (não emite
## no EventBus) — mesma razão do LootSpawner/TorchLightManager: outras cenas
## de teste instanciam main.tscn, que tem seu próprio listener conectado.


func test_quebrar_bloco_cria_uma_burst_de_particulas() -> void:
	var sistema := BlockBreakParticles.new()
	add_child_autofree(sistema)

	sistema._ao_quebrar_bloco(Vector3i(5, 10, 5), 3)  # pedra

	assert_eq(sistema.get_child_count(), 1)
	var particulas: GPUParticles3D = sistema.get_child(0)
	assert_true(particulas.emitting)
	assert_eq(particulas.process_material.color, BlockRegistry.get_block(3).cor)


func test_bloco_inexistente_nao_cria_particulas() -> void:
	var sistema := BlockBreakParticles.new()
	add_child_autofree(sistema)

	sistema._ao_quebrar_bloco(Vector3i(0, 0, 0), 9999)

	assert_eq(sistema.get_child_count(), 0)


func test_particulas_ficam_na_posicao_do_bloco_quebrado() -> void:
	var sistema := BlockBreakParticles.new()
	add_child_autofree(sistema)

	sistema._ao_quebrar_bloco(Vector3i(2, 3, 4), 1)  # grama

	var particulas: GPUParticles3D = sistema.get_child(0)
	assert_eq(particulas.position, Vector3(2.5, 3.5, 4.5))
