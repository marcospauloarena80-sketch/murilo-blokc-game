extends GutTest
## Frente 6D — raio_chunks limita a fila de geração ao quadrado em volta do
## chunk central (o menu gera só os 3x3 do centro). O padrão -1 mantém o
## comportamento de sempre: o mundo inteiro.


func after_each() -> void:
	GameState.veio_de_continuar = false


func _drenar(cm: ChunkManager) -> void:
	while cm.tem_chunks_pendentes():
		cm._process(0.0)


func test_padrao_planeja_o_mundo_inteiro() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)
	assert_eq(cm.raio_chunks, -1)

	cm._process(0.0)

	assert_eq(
		cm._chunks.size() + cm._fila_geracao.size(),
		ChunkManager.WORLD_CHUNKS_X * ChunkManager.WORLD_CHUNKS_Z,
		"sem raio, todos os chunks entram na fila"
	)


func test_raio_um_gera_so_os_nove_chunks_do_centro() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	cm.raio_chunks = 1
	add_child_autofree(cm)
	watch_signals(cm)

	_drenar(cm)

	assert_eq(cm._chunks.size(), 9)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			assert_true(cm._chunks.has(Vector2i(4 + dx, 4 + dz)), "chunk %d,%d" % [4 + dx, 4 + dz])
	assert_true(cm.area_pronta)
	assert_signal_emitted(cm, "mundo_gerado")


func test_raio_zero_gera_so_o_chunk_central() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	cm.raio_chunks = 0
	add_child_autofree(cm)

	_drenar(cm)

	assert_eq(cm._chunks.size(), 1)
	assert_true(cm._chunks.has(Vector2i(4, 4)))
