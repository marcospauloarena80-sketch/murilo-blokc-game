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


func test_bloco_cercado_por_solidos_nao_gera_faces() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, 3)
	var mesher := ChunkMesher.new()
	var vizinho_sempre_solido := func(x: int, y: int, z: int) -> bool: return true
	var malha := mesher.construir_malha(chunk, vizinho_sempre_solido)
	assert_null(malha, "bloco totalmente cercado não deve expor face nenhuma")
