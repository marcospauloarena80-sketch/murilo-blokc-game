extends GutTest
## Ícones dos itens (Ciclo 6, 6B): todo item do ItemRegistry tem um ícone na
## folha assets/textures/icones_itens.png (gerada por tools/gerar_icones.gd) e o
## desenho cobre o centro do tile — um ícone vazio passaria despercebido no HUD.


func test_todo_item_tem_textura_e_o_centro_do_icone_nao_e_transparente() -> void:
	var ids: Array = ItemRegistry.todos_os_ids()
	assert_gt(ids.size(), 0)
	for item_id: String in ids:
		var textura: Texture2D = IconesItens.textura(item_id)
		assert_not_null(textura, "item %s sem ícone" % item_id)
		var imagem: Image = IconesItens.imagem(item_id)
		assert_not_null(imagem, "item %s sem imagem" % item_id)
		if imagem == null:
			continue
		assert_eq(imagem.get_size(), Vector2i(IconesItens.LADO, IconesItens.LADO))
		var meio: int = IconesItens.LADO / 2
		var centro: Color = imagem.get_pixel(meio, meio)
		assert_gt(centro.a, 0.0, "ícone de %s transparente no centro" % item_id)


func test_nomes_cobrem_exatamente_os_ids_do_registro() -> void:
	for item_id: String in ItemRegistry.todos_os_ids():
		assert_true(IconesItens.NOMES.has(item_id), "falta %s em IconesItens.NOMES" % item_id)
	for nome: String in IconesItens.NOMES:
		assert_not_null(ItemRegistry.get_item(nome), "%s em NOMES não é item" % nome)


func test_id_desconhecido_nao_tem_textura() -> void:
	assert_null(IconesItens.textura("nao_existe"))
	assert_null(IconesItens.imagem("nao_existe"))


func test_textura_e_atlas_sobre_a_folha_na_regiao_do_tile_carregada_uma_vez() -> void:
	var tex := IconesItens.textura("pedra") as AtlasTexture
	assert_not_null(tex)
	if tex == null:
		return
	var i: int = IconesItens.indice("pedra")
	var lado: int = IconesItens.LADO
	var coluna: int = i % IconesItens.COLUNAS
	var linha: int = i / IconesItens.COLUNAS
	assert_eq(tex.region, Rect2(coluna * lado, linha * lado, lado, lado))
	assert_same(IconesItens.textura("pedra"), tex, "mesma instância: carregada uma vez")
	assert_same((IconesItens.textura("tronco") as AtlasTexture).atlas, tex.atlas, "uma folha só")


func test_item_de_bloco_copia_o_tile_lateral_do_atlas_de_blocos() -> void:
	var def: ItemDef = ItemRegistry.get_item("pedra")
	var bloco: BlockDef = BlockRegistry.get_block(def.bloco_id)
	var atlas: Image = (load(AtlasBlocos.CAMINHO_PNG) as Texture2D).get_image()
	if atlas.is_compressed():
		atlas.decompress()
	atlas.convert(Image.FORMAT_RGBA8)
	var i: int = AtlasBlocos.indice(bloco.textura_lado)
	var lado: int = AtlasBlocos.LADO
	var origem := Vector2i((i % AtlasBlocos.COLUNAS) * lado, (i / AtlasBlocos.COLUNAS) * lado)
	var tile: Image = atlas.get_region(Rect2i(origem, Vector2i(lado, lado)))

	var icone: Image = IconesItens.imagem("pedra")

	assert_eq(icone.get_data(), tile.get_data(), "ícone da pedra = tile 'pedra' do atlas")
