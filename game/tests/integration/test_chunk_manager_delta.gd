extends GutTest
## Ver docs/07-DECISOES.md ADR-006 — delta de blocos editados (não a seed inteira).


func _drenar(cm: ChunkManager) -> void:
	## Geração de chunk é time-sliced (ADR-026) — precisa existir antes de editar.
	while cm.tem_chunks_pendentes():
		cm._process(0.0)


func test_editar_bloco_entra_no_delta() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)
	_drenar(cm)

	cm.set_block(Vector3i(3, 40, 3), 3)
	var delta := cm.exportar_delta()

	assert_true(delta.has("3,40,3"))
	assert_eq(delta["3,40,3"], 3)


func test_delta_e_json_safe() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 2
	add_child_autofree(cm)
	_drenar(cm)

	cm.set_block(Vector3i(1, 40, 1), 3)
	cm.set_block(Vector3i(2, 40, 2), BlockRegistry.AR_ID)
	var texto := JSON.stringify(cm.exportar_delta())
	assert_not_null(JSON.parse_string(texto))


func test_aplicar_delta_reproduz_as_edicoes_num_chunk_manager_novo() -> void:
	var cm_original := ChunkManager.new()
	cm_original.world_seed = 3
	add_child_autofree(cm_original)
	_drenar(cm_original)
	cm_original.set_block(Vector3i(5, 40, 5), 3)
	cm_original.set_block(Vector3i(6, 40, 6), BlockRegistry.AR_ID)
	var delta := cm_original.exportar_delta()

	var cm_novo := ChunkManager.new()
	cm_novo.world_seed = 3
	add_child_autofree(cm_novo)
	_drenar(cm_novo)
	cm_novo.aplicar_delta(delta)

	assert_eq(cm_novo.get_block(Vector3i(5, 40, 5)), 3)
	assert_eq(cm_novo.get_block(Vector3i(6, 40, 6)), BlockRegistry.AR_ID)
