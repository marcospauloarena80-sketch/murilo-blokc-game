extends GutTest
## Blocos em cruz e horta (Ciclo 8, frente 8A): tabelas do registro, malha do
## mesher (sem colisão, sem oclusão, planos na altura do BlockDef), itens,
## receitas e drops.

const MUDA: int = 17
const COGUMELO: int = 18
const TRIGO_1: int = 19
const TRIGO_2: int = 20
const TRIGO_3: int = 21
const TERRA_ARADA: int = 22


func _vizinho_vazio(_x: int, _y: int, _z: int) -> bool:
	return false


func test_ids_reservados_da_frente_existem() -> void:
	for id: int in range(MUDA, TERRA_ARADA + 1):
		assert_not_null(BlockRegistry.get_block(id), "bloco %d sem BlockDef" % id)


func test_blocos_em_cruz_nao_colidem_nem_ocluem() -> void:
	var solidos := BlockRegistry.tabela_solidos()
	var oclusao := BlockRegistry.tabela_oclusao()
	var cruzes := BlockRegistry.tabela_cruz()
	for id: int in [MUDA, COGUMELO, TRIGO_1, TRIGO_2, TRIGO_3]:
		assert_eq(cruzes[id], 1, "bloco %d é cruz" % id)
		assert_eq(solidos[id], 0, "bloco %d não colide" % id)
		assert_eq(oclusao[id], 0, "bloco %d não oclui" % id)
		assert_false(BlockRegistry.e_solido(id))
		assert_false(BlockRegistry.e_oclusor(id))


func test_cubos_continuam_solidos_e_oclusores() -> void:
	for id: int in [1, 2, 3, 4, TERRA_ARADA]:
		assert_eq(BlockRegistry.tabela_solidos()[id], 1)
		assert_eq(BlockRegistry.tabela_oclusao()[id], 1)
		assert_eq(BlockRegistry.tabela_cruz()[id], 0)
	assert_eq(BlockRegistry.tabela_oclusao()[BlockRegistry.AGUA_ID], 0, "água não oclui")
	assert_eq(BlockRegistry.tabela_oclusao()[0], 0, "ar não oclui")


func test_todo_bloco_tem_textura_no_atlas() -> void:
	for id: int in range(1, TERRA_ARADA + 1):
		if id == BlockRegistry.AGUA_ID:
			continue  # a água tem material próprio, fora do atlas
		var bloco := BlockRegistry.get_block(id)
		assert_gte(AtlasBlocos.indice(bloco.textura_lado), 0, "%s sem textura" % bloco.nome)
		if bloco.textura_topo != "":
			assert_gte(AtlasBlocos.indice(bloco.textura_topo), 0, "%s sem topo" % bloco.nome)


func test_estagios_de_crescimento_encadeiam() -> void:
	assert_eq(BlockRegistry.get_block(TRIGO_1).cresce_para, TRIGO_2)
	assert_eq(BlockRegistry.get_block(TRIGO_2).cresce_para, TRIGO_3)
	assert_eq(BlockRegistry.get_block(TRIGO_3).cresce_para, 0, "maduro não cresce mais")
	assert_gt(BlockRegistry.get_block(TRIGO_1).tempo_crescimento_seg, 0.0)
	assert_gt(BlockRegistry.get_block(MUDA).cresce_para, 0)


func test_so_cruz_sozinha_nao_gera_colisao() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 6, 5, MUDA)
	var malha := ChunkMesher.new().construir_malha(chunk, _vizinho_vazio)
	assert_null(malha, "muda não entra na malha de colisão")


func test_cruz_ao_lado_de_cubo_nao_esconde_nenhuma_face() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(6, 6, 5, 3)
	chunk.set_block(5, 6, 5, MUDA)
	var malha := ChunkMesher.new().construir_malha(chunk, _vizinho_vazio)
	assert_eq(malha.get_faces().size(), 36, "o cubo mantém as 6 faces")


func test_cruz_sai_na_decoracao_na_altura_do_bloco() -> void:
	var chunk := ChunkData.new()
	chunk.set_block(5, 5, 5, 1)
	chunk.set_block(5, 6, 5, MUDA)
	var detalhes := ChunkMesher.new().construir_detalhes(chunk, 1)
	var decoracao: ArrayMesh = detalhes["decoracao"]
	assert_not_null(decoracao, "muda vira malha de decoração")
	var vertices: PackedVector3Array = decoracao.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_eq(vertices.size(), 8, "dois planos cruzados = 8 vértices")
	var minimo: float = 99.0
	var maximo: float = -99.0
	for v: Vector3 in vertices:
		minimo = minf(minimo, v.y)
		maximo = maxf(maximo, v.y)
		assert_almost_eq(v.x + v.z, 11.0, 0.9, "centrada na célula (5,5)")
	assert_almost_eq(minimo, 6.0, 0.001)
	assert_almost_eq(maximo, 6.0 + BlockRegistry.get_block(MUDA).altura_cruz, 0.001)


func test_altura_do_trigo_cresce_a_cada_estagio() -> void:
	var a1: float = BlockRegistry.get_block(TRIGO_1).altura_cruz
	var a2: float = BlockRegistry.get_block(TRIGO_2).altura_cruz
	var a3: float = BlockRegistry.get_block(TRIGO_3).altura_cruz
	assert_lt(a1, a2)
	assert_lt(a2, a3)


func test_itens_da_horta() -> void:
	assert_eq(ItemRegistry.get_item("semente").bloco_id, TRIGO_1)
	assert_eq(ItemRegistry.get_item("muda").bloco_id, MUDA)
	assert_eq(ItemRegistry.get_item("cogumelo").bloco_id, COGUMELO)
	assert_true(ItemRegistry.get_item("cogumelo").eh_comida)
	assert_eq(ItemRegistry.get_item("cogumelo").restaura_fome, 3)
	assert_eq(ItemRegistry.get_item("pao").restaura_fome, 8)
	assert_true(ItemRegistry.get_item("pao").eh_comida)
	assert_true(ItemRegistry.get_item("enxada_madeira").pode_arar)
	assert_false(ItemRegistry.get_item("picareta_madeira").pode_arar)


func test_pao_pede_tres_trigos_e_fornalha() -> void:
	var receita := RecipeRegistry.get_receita("pao")
	assert_not_null(receita)
	assert_eq(receita.ingredientes, {"trigo": 3})
	assert_eq(receita.resultado_id, "pao")
	assert_true(receita.exige_fornalha)
	assert_not_null(ItemRegistry.get_item(receita.resultado_id))


func test_enxada_se_crafta_na_bancada() -> void:
	var receita := RecipeRegistry.get_receita("enxada_madeira")
	assert_not_null(receita)
	assert_true(receita.exige_bancada)
	assert_eq(receita.resultado_id, "enxada_madeira")


func test_drops_dos_blocos_da_horta() -> void:
	assert_eq(BlockRegistry.get_block(MUDA).drop_id, "muda")
	assert_eq(BlockRegistry.get_block(TRIGO_1).drop_id, "semente")
	assert_eq(BlockRegistry.get_block(TRIGO_3).drop_id, "trigo")
	assert_eq(BlockRegistry.get_block(TRIGO_3).drop_extra_id, "semente")
	assert_eq(BlockRegistry.get_block(TRIGO_3).drop_extra_min, 1)
	assert_eq(BlockRegistry.get_block(TRIGO_3).drop_extra_max, 2)
	assert_eq(BlockRegistry.get_block(5).drop_extra_id, "muda")
	assert_almost_eq(BlockRegistry.get_block(5).drop_extra_chance, 0.15, 0.0001)
	assert_eq(BlockRegistry.get_block(1).drop_extra_id, "semente")
	assert_almost_eq(BlockRegistry.get_block(1).drop_extra_chance, 0.1, 0.0001)
