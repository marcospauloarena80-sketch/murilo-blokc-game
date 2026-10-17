extends GutTest
## Ciclo 8 (8D): vilarejo com casas dos NPCs do centro e arenas dos guardiões.

const SEMENTES: Array[int] = [
	1,
	2,
	3,
	7,
	42,
	99,
	123,
	256,
	777,
	1000,
	1337,
	2024,
	4096,
	5555,
	9001,
	12345,
	31337,
	65535,
	99999,
	424242
]


func _chunks_do_vilarejo(gerador: WorldGenerator) -> Dictionary:
	var chunks: Dictionary = {}
	for cx in range(2, 6):
		for cz in range(2, 6):
			chunks[Vector2i(cx, cz)] = gerador.gerar_chunk(cx, cz)
	return chunks


func _bloco(chunks: Dictionary, x: int, y: int, z: int) -> int:
	var chunk: ChunkData = chunks[Vector2i(floori(x / 16.0), floori(z / 16.0))]
	return chunk.get_block(x & 15, y, z & 15)


func _contar(npc_id: String, id: int) -> int:
	var n: int = 0
	for b: Dictionary in Vilarejo.casa_para(npc_id):
		if b["id"] == id:
			n += 1
	return n


func test_casa_tem_porta_e_dois_vidros() -> void:
	for npc_id: String in Vilarejo.ids_com_casa():
		assert_eq(_contar(npc_id, BlockRegistry.PORTA_FECHADA_ID), 1, "porta de %s" % npc_id)
		assert_eq(_contar(npc_id, BlockRegistry.PORTA_TOPO_ID), 1, "topo da porta de %s" % npc_id)
		assert_eq(_contar(npc_id, Vilarejo.VIDRO_ID), 2, "vidros de %s" % npc_id)
		assert_eq(_contar(npc_id, Vilarejo.TOCHA_ID), 1, "tocha de %s" % npc_id)


func test_casa_cabe_em_7x5x7_e_so_os_quatro_do_centro_tem_casa() -> void:
	assert_eq(Vilarejo.ids_com_casa().size(), 4)
	assert_eq(Vilarejo.ids_com_arena().size(), 5)
	for b: Dictionary in Vilarejo.casa_para("lina"):
		var p: Vector3i = b["pos"]
		assert_true(p.x >= 0 and p.x < 7 and p.z >= 0 and p.z < 7 and p.y >= 0 and p.y < 5)


func test_porta_fica_voltada_para_o_centro_do_mundo() -> void:
	for npc_id: String in Vilarejo.ids_com_casa():
		var canto := Vilarejo.canto_da_casa(npc_id)
		for b: Dictionary in Vilarejo.casa_para(npc_id):
			if b["id"] != BlockRegistry.PORTA_FECHADA_ID:
				continue
			var p: Vector3i = b["pos"]
			var mundo := Vector2(canto.x + p.x + 0.5, canto.y + p.z + 0.5)
			var centro_casa := Vector2(Vilarejo.centro_da_casa(npc_id)) + Vector2(0.5, 0.5)
			var para_porta := mundo - centro_casa
			var para_centro := WorldGenerator.CENTRO_MUNDO - centro_casa
			assert_gt(para_porta.dot(para_centro), 0.0, "porta de %s voltada ao centro" % npc_id)


func test_footprint_aplainado_em_20_sementes() -> void:
	for semente: int in SEMENTES:
		var gerador := WorldGenerator.new(semente)
		var nivel := gerador.nivel_do_vilarejo()
		var chunks := _chunks_do_vilarejo(gerador)
		for npc_id: String in Vilarejo.POSICOES_NPCS:
			for c: Vector2i in Vilarejo.colunas_do_footprint(npc_id):
				assert_true(
					BlockRegistry.e_solido(_bloco(chunks, c.x, nivel, c.y)),
					"piso em %s (semente %d)" % [c, semente]
				)
				assert_true(
					BlockRegistry.e_solido(_bloco(chunks, c.x, nivel - 1, c.y)),
					"chão sob o piso em %s (semente %d)" % [c, semente]
				)
		## Sem árvore nem água dentro do footprint das casas.
		for npc_id: String in Vilarejo.ids_com_casa():
			for c: Vector2i in Vilarejo.colunas_do_footprint(npc_id):
				for y in range(nivel, 64):
					var id := _bloco(chunks, c.x, y, c.y)
					assert_false(id in [4, 5, 13, 16], "resto de árvore/água em %s" % c)


func test_casa_aplicada_tem_porta_e_vidros_no_mundo() -> void:
	var gerador := WorldGenerator.new(42)
	var nivel := gerador.nivel_do_vilarejo()
	var chunks := _chunks_do_vilarejo(gerador)
	for npc_id: String in Vilarejo.ids_com_casa():
		var canto := Vilarejo.canto_da_casa(npc_id)
		var vidros: int = 0
		var portas: int = 0
		for i in range(7):
			for j in range(7):
				for y in range(1, 4):
					var id := _bloco(chunks, canto.x + i, nivel + y, canto.y + j)
					if id == Vilarejo.VIDRO_ID:
						vidros += 1
					if id == BlockRegistry.PORTA_FECHADA_ID:
						portas += 1
		assert_eq(vidros, 2, "vidros de %s no mundo" % npc_id)
		assert_eq(portas, 1, "porta de %s no mundo" % npc_id)


func test_npc_fica_sobre_o_piso_e_nao_dentro_de_parede() -> void:
	for semente: int in [5, 42, 777]:
		var gerador := WorldGenerator.new(semente)
		var nivel := gerador.nivel_do_vilarejo()
		var chunks := _chunks_do_vilarejo(gerador)
		for npc_id: String in Vilarejo.POSICOES_NPCS:
			var pos := Vilarejo.posicao_do_npc(npc_id, nivel)
			var x := floori(pos.x)
			var z := floori(pos.z)
			assert_true(BlockRegistry.e_solido(_bloco(chunks, x, nivel, z)), "piso de %s" % npc_id)
			assert_eq(pos.y, float(nivel) + 1.0)
			assert_eq(_bloco(chunks, x, nivel + 1, z), BlockRegistry.AR_ID, "pés de %s" % npc_id)
			assert_eq(_bloco(chunks, x, nivel + 2, z), BlockRegistry.AR_ID, "cabeça de %s" % npc_id)


func test_mesma_semente_mesmo_resultado() -> void:
	var a := WorldGenerator.new(31337).gerar_chunk(4, 4)
	var b := WorldGenerator.new(31337).gerar_chunk(4, 4)
	assert_eq(a.dados(), b.dados())
	var outro := WorldGenerator.new(31338).gerar_chunk(4, 4)
	assert_ne(a.dados(), outro.dados())


func test_arena_tem_anel_de_pedra_com_piso() -> void:
	var gerador := WorldGenerator.new(42)
	var nivel := gerador.nivel_do_vilarejo()
	var chunks := _chunks_do_vilarejo(gerador)
	var c := Vilarejo.centro_da_arena("guardiao_pedra")
	assert_eq(_bloco(chunks, c.x, nivel, c.y), Vilarejo.PEDRA_ID)
	assert_eq(_bloco(chunks, c.x + 4, nivel, c.y), Vilarejo.PEDRA_ID)
	assert_eq(_bloco(chunks, c.x + 3, nivel + 1, c.y + 2), Vilarejo.PEDRA_ID, "mureta na borda")
