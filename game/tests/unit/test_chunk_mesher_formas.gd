extends GutTest
## Ciclo 8 (Frente 8C): blocos de construção não cúbicos. A colisão sai da
## própria malha (trimesh), então medir a geometria da malha mede a colisão.

const PEDRA: int = 3
const VIDRO: int = 24
const LAJE: int = 25
const ESCADA: int = 26
const PORTA_FECHADA: int = 27
const PORTA_ABERTA: int = 28
const PORTA_TOPO: int = 29
const CERCA: int = 30


func _malha(chunk: ChunkData) -> ArrayMesh:
	var mesher := ChunkMesher.new()
	var vizinho := func(x: int, y: int, z: int) -> bool:
		return BlockRegistry.e_oclusor(chunk.get_block(x, y, z))
	return mesher.construir_malha(chunk, vizinho)


func _limites(malha: ArrayMesh) -> AABB:
	var pontos: PackedVector3Array = malha.get_faces()
	var caixa := AABB(pontos[0], Vector3.ZERO)
	for p: Vector3 in pontos:
		caixa = caixa.expand(p)
	return caixa


func test_laje_tem_meia_altura() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, LAJE)
	var caixa := _limites(_malha(chunk))
	assert_almost_eq(caixa.size.y, 0.5, 0.001, "altura máxima dos vértices = 0,5")
	assert_almost_eq(caixa.size.x, 1.0, 0.001)
	assert_almost_eq(caixa.size.z, 1.0, 0.001)
	assert_eq(_malha(chunk).get_faces().size(), 36, "uma caixa: 6 faces")


func test_escada_chega_a_altura_cheia_so_no_fundo() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, ESCADA)
	var caixa := _limites(_malha(chunk))
	assert_almost_eq(caixa.size.y, 1.0, 0.001)
	var alto_no_fundo := true
	for p: Vector3 in _malha(chunk).get_faces():
		if p.y > 5.5 + 0.001 and p.z > 5.5 + 0.001:
			alto_no_fundo = false
	assert_true(alto_no_fundo, "degrau alto só na metade norte (z menor)")


func test_porta_fechada_e_fina_em_z_e_aberta_e_fina_em_x() -> void:
	var fechada := ChunkData.new()
	fechada.set_block(5, 5, 5, PORTA_FECHADA)
	fechada.set_block(5, 6, 5, PORTA_TOPO)
	var caixa := _limites(_malha(fechada))
	assert_almost_eq(caixa.size.y, 2.0, 0.001, "dois blocos de altura")
	assert_almost_eq(caixa.size.z, 0.2, 0.001)
	assert_almost_eq(caixa.size.x, 1.0, 0.001)
	var aberta := ChunkData.new()
	aberta.set_block(5, 5, 5, PORTA_ABERTA)
	aberta.set_block(5, 6, 5, PORTA_TOPO)
	caixa = _limites(_malha(aberta))
	assert_almost_eq(caixa.size.y, 2.0, 0.001)
	assert_almost_eq(caixa.size.x, 0.2, 0.001, "o topo acompanha a porta de baixo")
	assert_almost_eq(caixa.size.z, 1.0, 0.001)


func test_cerca_tem_poste_fino_e_travessas() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, CERCA)
	var caixa := _limites(_malha(chunk))
	assert_almost_eq(caixa.size.y, 1.0, 0.001)
	assert_almost_eq(caixa.size.x, 1.0, 0.001, "travessas atravessam o bloco")
	assert_almost_eq(caixa.size.z, 0.25, 0.001, "poste de 0,25")


func test_vidro_isolado_tem_6_faces_e_dois_vidros_escondem_a_face_comum() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, VIDRO)
	assert_eq(_malha(chunk).get_faces().size(), 36)
	chunk.set_block(6, 5, 5, VIDRO)
	assert_eq(_malha(chunk).get_faces().size(), 60, "10 faces: a comum some")


func test_vidro_nao_oclui_o_vizinho_mas_o_vizinho_cheio_esconde_a_face_do_vidro() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, PEDRA)
	chunk.set_block(6, 5, 5, VIDRO)
	## Pedra mostra as 6 faces (vidro não oclui); vidro esconde a face da pedra.
	assert_eq(_malha(chunk).get_faces().size(), 36 + 30)


func test_laje_nao_oclui_o_vizinho() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, PEDRA)
	chunk.set_block(6, 5, 5, LAJE)
	## Pedra com 6 faces; laje sem a face encostada na pedra.
	assert_eq(_malha(chunk).get_faces().size(), 36 + 30)


func _raio_acerta_a_porta(aberta: bool) -> bool:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, PORTA_ABERTA if aberta else PORTA_FECHADA)
	chunk.set_block(5, 6, 5, PORTA_TOPO)
	var corpo := StaticBody3D.new()
	var colisao := CollisionShape3D.new()
	colisao.shape = _malha(chunk).create_trimesh_shape()
	corpo.add_child(colisao)
	add_child(corpo)
	await wait_physics_frames(2)
	## Raio no eixo z passando pelo meio do bloco (x = 5,5).
	var consulta := PhysicsRayQueryParameters3D.create(
		Vector3(5.5, 5.5, 3.0), Vector3(5.5, 5.5, 8.0)
	)
	var acerto := corpo.get_world_3d().direct_space_state.intersect_ray(consulta)
	corpo.free()
	return not acerto.is_empty()


func test_porta_fechada_colide_no_centro() -> void:
	assert_true(await _raio_acerta_a_porta(false))


func test_porta_aberta_nao_colide_no_centro() -> void:
	assert_false(await _raio_acerta_a_porta(true))
