extends GutTest
## Ver docs/09-PERFORMANCE.md (face culling) e docs/08-PLANO-TESTES.md.


func test_bloco_isolado_gera_6_faces() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, 3)
	var mesher := ChunkMesher.new()
	var vizinho_solido := func(x: int, y: int, z: int) -> bool:
		return BlockRegistry.e_solido(chunk.get_block(x, y, z))
	var malha := mesher.construir_malha(chunk, vizinho_solido)
	var faces := malha.get_faces()
	assert_eq(faces.size(), 36, "6 faces x 2 triângulos x 3 vértices = 36")


func test_dois_blocos_vizinhos_escondem_a_face_compartilhada() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, 3)
	chunk.set_block(6, 5, 5, 3)
	var mesher := ChunkMesher.new()
	var vizinho_solido := func(x: int, y: int, z: int) -> bool:
		return BlockRegistry.e_solido(chunk.get_block(x, y, z))
	var malha := mesher.construir_malha(chunk, vizinho_solido)
	var faces := malha.get_faces()
	assert_eq(faces.size(), 60, "10 faces expostas (12 - 2 compartilhadas) x 2 tri x 3 vert")


func test_chunk_totalmente_vazio_nao_gera_malha() -> void:
	var chunk := ChunkData.new()
	var mesher := ChunkMesher.new()
	var vizinho_solido := func(x: int, y: int, z: int) -> bool: return false
	var malha := mesher.construir_malha(chunk, vizinho_solido)
	assert_null(malha, "chunk vazio não deve gerar mesh")


func test_vizinho_solido_fora_do_chunk_esconde_a_face_da_borda() -> void:
	## Vizinhos internos vêm direto dos dados; o Callable só decide a borda
	## com o chunk vizinho (ADR-026).
	var chunk := ChunkData.new()
	chunk.set_block(0, 5, 5, 3)
	var mesher := ChunkMesher.new()
	var fora_do_chunk_e_solido := func(x: int, _y: int, _z: int) -> bool: return x < 0
	var malha := mesher.construir_malha(chunk, fora_do_chunk_e_solido)
	assert_eq(malha.get_faces().size(), 30, "5 faces expostas: a face oeste fica escondida")


func test_callable_so_e_consultado_na_borda() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, 3)
	var mesher := ChunkMesher.new()
	var chamadas: Array[int] = [0]
	var contar := func(_x: int, _y: int, _z: int) -> bool:
		chamadas[0] += 1
		return false
	mesher.construir_malha(chunk, contar)
	assert_eq(chamadas[0], 0, "bloco no meio do chunk não precisa consultar o vizinho")
