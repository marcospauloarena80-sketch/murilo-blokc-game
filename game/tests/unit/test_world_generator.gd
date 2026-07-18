extends GutTest
## Ver docs/06-RISCOS.md R2 e docs/08-PLANO-TESTES.md — determinismo é requisito de save (ADR-006).


func test_mesma_seed_mesmo_chunk_e_deterministico() -> void:
	var gerador_a := WorldGenerator.new(42)
	var gerador_b := WorldGenerator.new(42)
	var chunk_a := gerador_a.gerar_chunk(0, 0)
	var chunk_b := gerador_b.gerar_chunk(0, 0)
	for x in range(16):
		for z in range(16):
			for y in range(64):
				assert_eq(
					chunk_a.get_block(x, y, z),
					chunk_b.get_block(x, y, z),
					"bloco (%d,%d,%d) deveria ser igual" % [x, y, z]
				)


func test_seeds_diferentes_podem_gerar_mundos_diferentes() -> void:
	var gerador_a := WorldGenerator.new(1)
	var gerador_b := WorldGenerator.new(999)
	var chunk_a := gerador_a.gerar_chunk(0, 0)
	var chunk_b := gerador_b.gerar_chunk(0, 0)
	var algum_diferente := false
	for x in range(16):
		for z in range(16):
			if chunk_a.get_block(x, 35, z) != chunk_b.get_block(x, 35, z):
				algum_diferente = true
	assert_true(
		algum_diferente, "seeds diferentes devem produzir alturas diferentes em algum ponto"
	)


func test_altura_fica_dentro_dos_limites_esperados() -> void:
	var gerador := WorldGenerator.new(7)
	var chunk := gerador.gerar_chunk(2, -3)
	for x in range(16):
		for z in range(16):
			var topo_solido := -1
			for y in range(64):
				if chunk.get_block(x, y, z) == 1:
					topo_solido = y
			assert_true(
				topo_solido >= 15 and topo_solido <= 45,
				"altura da grama fora do esperado: %d" % topo_solido
			)


func test_chunk_gerado_nao_e_totalmente_vazio() -> void:
	var gerador := WorldGenerator.new(123)
	var chunk := gerador.gerar_chunk(0, 0)
	var tem_bloco := false
	for x in range(16):
		for z in range(16):
			if chunk.get_block(x, 30, z) != BlockRegistry.AR_ID:
				tem_bloco = true
	assert_true(tem_bloco, "chunk deveria ter blocos sólidos")
