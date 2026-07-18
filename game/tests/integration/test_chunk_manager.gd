extends GutTest
## Ver docs/08-PLANO-TESTES.md §2 (integração ChunkManager).


func test_mundo_gera_blocos_solidos_no_subsolo() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)
	assert_true(
		BlockRegistry.e_solido(cm.get_block(Vector3i(5, 5, 5))),
		"y=5 deveria estar bem abaixo da superfície (base ~30)"
	)


func test_set_block_atualiza_get_block() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 2
	add_child_autofree(cm)
	cm.set_block(Vector3i(3, 40, 3), 3)
	assert_eq(cm.get_block(Vector3i(3, 40, 3)), 3)


func test_set_block_marca_chunk_como_pendente() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 3
	add_child_autofree(cm)
	# esvazia a fila inicial (mundo inteiro já entra sujo em _ready)
	while cm.tem_chunks_pendentes():
		cm._process(0.0)
	assert_false(cm.tem_chunks_pendentes())
	cm.set_block(Vector3i(3, 40, 3), 3)
	assert_true(cm.tem_chunks_pendentes(), "editar bloco deveria marcar o chunk como sujo")


func test_editar_borda_marca_chunk_vizinho_tambem() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 4
	add_child_autofree(cm)
	while cm.tem_chunks_pendentes():
		cm._process(0.0)
	# x=0 do chunk (1,0) é a borda com o chunk (0,0)
	cm.set_block(Vector3i(16, 40, 3), 3)
	assert_eq(
		cm.fila_pendente_tamanho(), 2, "chunk editado + chunk vizinho da borda devem entrar na fila"
	)
	assert_eq(cm.get_block(Vector3i(16, 40, 3)), 3)


func test_fora_do_mundo_retorna_ar() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 5
	add_child_autofree(cm)
	assert_eq(cm.get_block(Vector3i(-1, 30, 0)), BlockRegistry.AR_ID)
	assert_eq(cm.get_block(Vector3i(1000, 30, 0)), BlockRegistry.AR_ID)
