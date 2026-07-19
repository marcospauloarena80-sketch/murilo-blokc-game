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
	## Chunk (4,4) é Campos Dourados (F11, ADR-024) — com árvores permitidas,
	## preserva a variância original entre seeds que este teste depende.
	var gerador_a := WorldGenerator.new(1)
	var gerador_b := WorldGenerator.new(999)
	var chunk_a := gerador_a.gerar_chunk(4, 4)
	var chunk_b := gerador_b.gerar_chunk(4, 4)
	var algum_diferente := false
	for x in range(16):
		for z in range(16):
			if chunk_a.get_block(x, 35, z) != chunk_b.get_block(x, 35, z):
				algum_diferente = true
	assert_true(
		algum_diferente, "seeds diferentes devem produzir alturas diferentes em algum ponto"
	)


func test_altura_fica_dentro_dos_limites_esperados() -> void:
	## Material de superfície varia por bioma desde a F11 (ADR-024) — detecta
	## o topo sólido genericamente, não só grama, pra continuar válido em
	## qualquer bioma que este chunk caia.
	var gerador := WorldGenerator.new(7)
	var chunk := gerador.gerar_chunk(2, -3)
	for x in range(16):
		for z in range(16):
			var topo_solido := -1
			for y in range(64):
				if BlockRegistry.e_solido(chunk.get_block(x, y, z)):
					topo_solido = y
			assert_true(
				topo_solido >= 15 and topo_solido <= 45,
				"altura do topo fora do esperado: %d" % topo_solido
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


func test_minerio_aparece_no_subsolo_em_area_grande_o_suficiente() -> void:
	# Um chunk sozinho pode não ter minério (raro); varre vários pra garantir
	# que a substituição realmente acontece em algum lugar.
	var gerador := WorldGenerator.new(2024)
	var achou_carvao := false
	var achou_ferrite := false
	for cx in range(4):
		for cz in range(4):
			var chunk := gerador.gerar_chunk(cx, cz)
			for x in range(16):
				for z in range(16):
					for y in range(20):
						var id := chunk.get_block(x, y, z)
						if id == 10:
							achou_carvao = true
						elif id == 11:
							achou_ferrite = true
	assert_true(achou_carvao, "carvão deveria aparecer em alguma das 16 chunks varridas")
	assert_true(achou_ferrite, "ferrite deveria aparecer em alguma das 16 chunks varridas")


func test_cristal_dourado_aparece_em_area_grande_o_suficiente() -> void:
	## Bem mais raro que ferrite/carvão (F10, ADR-023) — precisa de mais chunks.
	var gerador := WorldGenerator.new(2024)
	var achou := false
	for cx in range(8):
		for cz in range(8):
			var chunk := gerador.gerar_chunk(cx, cz)
			for x in range(16):
				for z in range(16):
					for y in range(20):
						if chunk.get_block(x, y, z) == 12:
							achou = true
	assert_true(achou, "cristal dourado deveria aparecer em alguma das 64 chunks varridas")


func test_minerio_so_substitui_pedra_nao_terra_nem_grama() -> void:
	## Chunk (0,0) cai em Picos Gelados (F11, ADR-024) — topo é gelo, não
	## grama, mas a camada logo abaixo continua terra (nunca minério).
	var gerador := WorldGenerator.new(5)
	var chunk := gerador.gerar_chunk(0, 0)
	for x in range(16):
		for z in range(16):
			var topo_solido := -1
			for y in range(64):
				if BlockRegistry.e_solido(chunk.get_block(x, y, z)):
					topo_solido = y
			assert_eq(
				chunk.get_block(x, topo_solido - 1, z),
				2,
				"camada logo abaixo do topo deveria ser terra"
			)
