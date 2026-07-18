extends GutTest
## Ver docs/02-ARQUITETURA.md §4.2 e docs/08-PLANO-TESTES.md.


func test_novo_chunk_comeca_vazio() -> void:
	var chunk := ChunkData.new()
	assert_eq(chunk.get_block(0, 0, 0), BlockRegistry.AR_ID)
	assert_eq(chunk.get_block(15, 63, 15), BlockRegistry.AR_ID)


func test_set_e_get_roundtrip() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(3, 10, 7, 3)
	assert_eq(chunk.get_block(3, 10, 7), 3)
	assert_eq(
		chunk.get_block(3, 11, 7), BlockRegistry.AR_ID, "posições vizinhas não devem ser afetadas"
	)


func test_fora_dos_limites_retorna_ar_sem_crash() -> void:
	var chunk := ChunkData.new()
	assert_eq(chunk.get_block(-1, 0, 0), BlockRegistry.AR_ID)
	assert_eq(chunk.get_block(16, 0, 0), BlockRegistry.AR_ID)
	assert_eq(chunk.get_block(0, 64, 0), BlockRegistry.AR_ID)
	assert_eq(chunk.get_block(0, -1, 0), BlockRegistry.AR_ID)


func test_set_fora_dos_limites_nao_quebra() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(100, 100, 100, 5)
	assert_true(true, "não deve lançar erro")
