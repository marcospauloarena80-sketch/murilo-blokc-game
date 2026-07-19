extends GutTest
## Ver docs/04-ROADMAP.md F6 (tochas com luz) e docs/07-DECISOES.md ADR-019.
## Mesmo padrão de test_loot_system.gd: emite o sinal do EventBus direto,
## sem precisar de ChunkManager/Player pra exercitar a lógica.


func test_colocar_tocha_spawna_luz() -> void:
	var gerenciador := TorchLightManager.new()
	add_child_autofree(gerenciador)

	EventBus.block_placed.emit(Vector3i(5, 40, 5), 9)  # tocha

	assert_eq(gerenciador.get_child_count(), 1)
	var luz: OmniLight3D = gerenciador.get_child(0)
	assert_eq(luz.position, Vector3(5.5, 40.5, 5.5))


func test_colocar_bloco_sem_luz_nao_spawna_nada() -> void:
	var gerenciador := TorchLightManager.new()
	add_child_autofree(gerenciador)

	EventBus.block_placed.emit(Vector3i(1, 40, 1), 3)  # pedra, não emite luz

	assert_eq(gerenciador.get_child_count(), 0)


func test_colocar_tocha_duas_vezes_na_mesma_posicao_nao_duplica_luz() -> void:
	var gerenciador := TorchLightManager.new()
	add_child_autofree(gerenciador)

	EventBus.block_placed.emit(Vector3i(2, 40, 2), 9)
	EventBus.block_placed.emit(Vector3i(2, 40, 2), 9)

	assert_eq(gerenciador.get_child_count(), 1)


func test_quebrar_tocha_remove_a_luz() -> void:
	var gerenciador := TorchLightManager.new()
	add_child_autofree(gerenciador)

	EventBus.block_placed.emit(Vector3i(3, 40, 3), 9)
	var luz: OmniLight3D = gerenciador.get_child(0)
	EventBus.block_broken.emit(Vector3i(3, 40, 3), 9)

	assert_true(luz.is_queued_for_deletion(), "luz deveria ter sido marcada pra remoção")


func test_quebrar_bloco_sem_luz_nao_afeta_luzes_existentes() -> void:
	var gerenciador := TorchLightManager.new()
	add_child_autofree(gerenciador)

	EventBus.block_placed.emit(Vector3i(4, 40, 4), 9)
	EventBus.block_broken.emit(Vector3i(99, 40, 99), 3)  # posição/bloco não relacionados

	assert_eq(gerenciador.get_child_count(), 1)
