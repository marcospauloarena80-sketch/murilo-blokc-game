extends GutTest
## Ciclo 8 (Frente 8C): registro dos blocos 23 a 30 e dos itens e receitas.

const IDS: Array[int] = [23, 24, 25, 26, 27, 28, 29, 30]


func test_ids_23_a_30_existem_com_textura_no_atlas() -> void:
	for id: int in IDS:
		var bloco := BlockRegistry.get_block(id)
		assert_not_null(bloco, "bloco %d" % id)
		if bloco == null:
			continue
		assert_eq(bloco.id, id)
		assert_true(bloco.solido, "%s colide" % bloco.nome)
		assert_gte(AtlasBlocos.indice(bloco.textura_lado), 0, "textura de %s" % bloco.nome)


func test_tiles_dos_blocos_sao_opacos_menos_o_miolo_do_vidro() -> void:
	## O shader do terreno descarta alpha < 0,5: tile com furo por engano
	## viraria buraco no mundo.
	var atlas: Image = (load(AtlasBlocos.CAMINHO_PNG) as Texture2D).get_image()
	if atlas.is_compressed():
		atlas.decompress()
	atlas.convert(Image.FORMAT_RGBA8)
	var lado: int = AtlasBlocos.LADO
	for id: int in range(1, 31):
		var bloco := BlockRegistry.get_block(id)
		if bloco == null or id == BlockRegistry.AGUA_ID or bloco.transparente:
			continue
		for nome: String in [bloco.textura_lado, bloco.textura_topo, bloco.textura_base]:
			if nome == "":
				continue
			var i: int = AtlasBlocos.indice(nome)
			var origem := Vector2i(
				(i % AtlasBlocos.COLUNAS) * lado, (i / AtlasBlocos.COLUNAS) * lado
			)
			var tile := atlas.get_region(Rect2i(origem, Vector2i(lado, lado)))
			for y: int in range(lado):
				for x: int in range(lado):
					if tile.get_pixel(x, y).a < 1.0:
						fail_test("tile %s do bloco %d tem pixel transparente" % [nome, id])
						return
	pass_test("tiles opacos")


func test_vidro_tem_miolo_transparente_e_moldura_opaca() -> void:
	var atlas: Image = (load(AtlasBlocos.CAMINHO_PNG) as Texture2D).get_image()
	if atlas.is_compressed():
		atlas.decompress()
	var i: int = AtlasBlocos.indice("vidro")
	var lado: int = AtlasBlocos.LADO
	var origem := Vector2i((i % AtlasBlocos.COLUNAS) * lado, (i / AtlasBlocos.COLUNAS) * lado)
	assert_eq(atlas.get_pixel(origem.x + 16, origem.y + 24).a, 0.0, "miolo transparente")
	assert_eq(atlas.get_pixel(origem.x, origem.y + 10).a, 1.0, "moldura opaca")


func test_formas_dos_blocos() -> void:
	assert_eq(BlockRegistry.get_block(23).forma, "cubo")
	assert_eq(BlockRegistry.get_block(24).forma, "vidro")
	assert_true(BlockRegistry.get_block(24).transparente)
	assert_eq(BlockRegistry.get_block(25).forma, "laje")
	assert_eq(BlockRegistry.get_block(26).forma, "escada")
	for id: int in [27, 28, 29]:
		assert_eq(BlockRegistry.get_block(id).forma, "porta")
	assert_eq(BlockRegistry.get_block(30).forma, "cerca")


func test_so_cubo_cheio_oclui() -> void:
	assert_true(BlockRegistry.e_oclusor(3))
	assert_true(BlockRegistry.e_oclusor(23))
	for id: int in [24, 25, 26, 27, 28, 29, 30]:
		assert_false(BlockRegistry.e_oclusor(id), "bloco %d não oclui" % id)
	assert_false(BlockRegistry.e_oclusor(0))
	assert_false(BlockRegistry.e_oclusor(BlockRegistry.AGUA_ID))


func test_itens_colocaveis_apontam_para_os_blocos() -> void:
	var esperado: Dictionary = {
		"tabua": 23, "vidro": 24, "laje": 25, "escada": 26, "porta": 27, "cerca": 30
	}
	for item_id: String in esperado:
		var def := ItemRegistry.get_item(item_id)
		assert_not_null(def, item_id)
		if def != null:
			assert_eq(def.bloco_id, esperado[item_id], item_id)


func test_blocos_dropam_o_proprio_item_e_o_topo_da_porta_nao_dropa() -> void:
	assert_eq(BlockRegistry.get_block(23).drop_id, "tabua")
	assert_eq(BlockRegistry.get_block(24).drop_id, "vidro")
	assert_eq(BlockRegistry.get_block(27).drop_id, "porta")
	assert_eq(BlockRegistry.get_block(28).drop_id, "porta")
	assert_eq(BlockRegistry.get_block(29).drop_id, "")


func test_receitas() -> void:
	var vidro := RecipeRegistry.get_receita("vidro")
	assert_eq(vidro.ingredientes, {"areia": 1})
	assert_true(vidro.exige_fornalha)
	var laje := RecipeRegistry.get_receita("laje")
	assert_eq(laje.ingredientes, {"tabua": 3})
	assert_eq(laje.resultado_quantidade, 6)
	var escada := RecipeRegistry.get_receita("escada")
	assert_eq(escada.ingredientes, {"tabua": 6})
	assert_eq(escada.resultado_quantidade, 4)
	assert_eq(RecipeRegistry.get_receita("porta").ingredientes, {"tabua": 6})
	var cerca := RecipeRegistry.get_receita("cerca")
	assert_eq(cerca.ingredientes, {"tabua": 4, "graveto": 2})
	assert_eq(cerca.resultado_quantidade, 3)
