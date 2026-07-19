extends GutTest
## Ver docs/01-GDD.md §3 e docs/07-DECISOES.md ADR-024 — bolsão pequeno e
## determinístico, nunca geração 3D completa (hedge do ADR-020 fechado).


func test_alguma_chunk_tem_bolsao_de_caverna() -> void:
	var gerador := WorldGenerator.new(2024)
	var achou_ar_no_subsolo := false
	for cx in range(8):
		for cz in range(8):
			var chunk := gerador.gerar_chunk(cx, cz)
			for x in range(16):
				for z in range(16):
					for y in range(8, 20):
						if chunk.get_block(x, y, z) == BlockRegistry.AR_ID:
							achou_ar_no_subsolo = true
	assert_true(achou_ar_no_subsolo, "algum bolsão de caverna deveria existir em 64 chunks")


func test_bolsao_nao_vaza_pra_superficie() -> void:
	var gerador := WorldGenerator.new(2024)
	for cx in range(8):
		for cz in range(8):
			var chunk := gerador.gerar_chunk(cx, cz)
			for x in range(16):
				for z in range(16):
					var topo := -1
					for y in range(64):
						if BlockRegistry.e_solido(chunk.get_block(x, y, z)):
							topo = y
					assert_true(
						topo >= 15, "coluna (%d,%d) sem chão sólido — caverna vazou" % [x, z]
					)


func test_chunk_com_caverna_ganha_uma_tocha() -> void:
	var gerador := WorldGenerator.new(2024)
	for cx in range(8):
		for cz in range(8):
			var chunk := gerador.gerar_chunk(cx, cz)
			var luzes := gerador.luzes_locais_da_ultima_chunk()
			if luzes.is_empty():
				continue
			var pos: Vector3i = luzes[0]
			assert_eq(
				chunk.get_block(pos.x, pos.y, pos.z), 9, "tocha deveria estar na posição registrada"
			)
			return
	fail_test("nenhuma chunk com caverna encontrada nas 64 varridas")


func test_mesma_seed_gera_mesmas_luzes() -> void:
	var gerador_a := WorldGenerator.new(2024)
	var gerador_b := WorldGenerator.new(2024)
	gerador_a.gerar_chunk(0, 0)
	gerador_b.gerar_chunk(0, 0)
	assert_eq(gerador_a.luzes_locais_da_ultima_chunk(), gerador_b.luzes_locais_da_ultima_chunk())
