extends GutTest
## Ver docs/01-GDD.md §3 e docs/07-DECISOES.md ADR-024 — cada bioma tem seu
## próprio material de superfície, senão todos seriam iguais debaixo dos pés.


func _topo_solido(chunk: ChunkData, x: int, z: int) -> int:
	var topo := -1
	for y in range(64):
		if BlockRegistry.e_solido(chunk.get_block(x, y, z)):
			topo = y
	return topo


func test_campos_dourados_tem_grama_no_topo() -> void:
	var gerador := WorldGenerator.new(7)
	var chunk := gerador.gerar_chunk(4, 4)  # campos_dourados (d~11.3)
	var topo := _topo_solido(chunk, 8, 8)
	assert_eq(chunk.get_block(8, topo, 8), 1)


func test_colinas_de_pedra_e_pedra_exposta_sem_arvore() -> void:
	var gerador := WorldGenerator.new(7)
	var chunk := gerador.gerar_chunk(1, 4)  # colinas_de_pedra (d~40.8)
	var topo := _topo_solido(chunk, 8, 8)
	assert_eq(chunk.get_block(8, topo, 8), 3)
	assert_eq(chunk.get_block(8, topo + 1, 8), 0, "sem árvore em cima de pedra exposta")


func test_deserto_de_ambar_e_areia_ou_ambar_no_topo() -> void:
	var gerador := WorldGenerator.new(7)
	var chunk := gerador.gerar_chunk(4, 0)  # deserto_de_ambar (d~56.6)
	for x in range(16):
		for z in range(16):
			var topo := _topo_solido(chunk, x, z)
			var bloco := chunk.get_block(x, topo, z)
			assert_true(bloco == 6 or bloco == 15, "esperado areia ou âmbar, achou %d" % bloco)


func test_picos_gelados_tem_gelo_no_topo() -> void:
	var gerador := WorldGenerator.new(7)
	var chunk := gerador.gerar_chunk(0, 0)  # picos_gelados (d~79.2)
	var topo := _topo_solido(chunk, 8, 8)
	assert_eq(chunk.get_block(8, topo, 8), 14)


func test_floresta_cubica_usa_tronco_raro_nas_arvores() -> void:
	var gerador := WorldGenerator.new(2024)
	var achou := false
	for cx in range(2, 4):
		for cz in range(3, 6):
			if WorldGenerator.bioma_em(cx * 16 + 8, cz * 16 + 8) != "floresta_cubica":
				continue
			var chunk := gerador.gerar_chunk(cx, cz)
			for x in range(16):
				for z in range(16):
					for y in range(64):
						if chunk.get_block(x, y, z) == 13:
							achou = true
	assert_true(achou, "deveria ter achado tronco raro em alguma chunk de Floresta Cúbica")


func test_ambar_aparece_em_area_grande_o_suficiente() -> void:
	var gerador := WorldGenerator.new(2024)
	var achou := false
	for cx in range(8):
		for cz in range(8):
			if WorldGenerator.bioma_em(cx * 16 + 8, cz * 16 + 8) != "deserto_de_ambar":
				continue
			var chunk := gerador.gerar_chunk(cx, cz)
			for x in range(16):
				for z in range(16):
					var topo := _topo_solido(chunk, x, z)
					if chunk.get_block(x, topo, z) == 15:
						achou = true
	assert_true(achou, "âmbar deveria aparecer em algum ponto do Deserto de Âmbar")
