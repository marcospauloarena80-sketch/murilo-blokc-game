extends GutTest
## Lagos (Ciclo 4, ADR-027): vales abaixo de NIVEL_AGUA enchem de água com
## fundo de areia; no Deserto de Âmbar ficam secos; nos Picos Gelados o lago é
## gelo sólido até o nível da água (sem água por baixo), senão quem quebra o
## gelo cai numa armadilha de onde o pulo não alcança a borda.

const AREIA_ID: int = 6
const GELO_ID: int = 14
const TRONCOS: Array[int] = [4, 13]
const FOLHAS_ID: int = 5


func _chunks_do_bioma(bioma: String) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for cx in range(8):
		for cz in range(8):
			if WorldGenerator.bioma_em(cx * 16 + 8, cz * 16 + 8) == bioma:
				coords.append(Vector2i(cx, cz))
	return coords


func _tem_bloco(chunk: ChunkData, id: int) -> bool:
	for x in range(16):
		for z in range(16):
			for y in range(64):
				if chunk.get_block(x, y, z) == id:
					return true
	return false


func test_bioma_com_agua_enche_o_vale_com_agua_e_fundo_de_areia_sem_arvore() -> void:
	var gerador := WorldGenerator.new(7)
	var colunas_baixas := 0
	for bioma: String in ["campos_dourados", "floresta_cubica"]:
		for coord: Vector2i in _chunks_do_bioma(bioma):
			var chunk := gerador.gerar_chunk(coord.x, coord.y)
			for lx in range(16):
				for lz in range(16):
					var altura: int = gerador._altura_em(coord.x * 16 + lx, coord.y * 16 + lz)
					if altura > WorldGenerator.NIVEL_AGUA + 1:
						continue
					var tem_tronco := false
					for y in range(64):
						if chunk.get_block(lx, y, lz) in TRONCOS:
							tem_tronco = true
					assert_false(tem_tronco, "sem tronco na coluna baixa (%d,%d)" % [lx, lz])
					if altura > WorldGenerator.NIVEL_AGUA - 1:
						continue
					colunas_baixas += 1
					assert_eq(chunk.get_block(lx, altura, lz), AREIA_ID, "fundo de areia")
					assert_eq(
						chunk.get_block(lx, altura - 1, lz), AREIA_ID, "areia abaixo do fundo"
					)
					for y in range(altura + 1, WorldGenerator.NIVEL_AGUA + 1):
						assert_eq(
							chunk.get_block(lx, y, lz),
							BlockRegistry.AGUA_ID,
							"água de altura+1 até o nível em (%d,%d) y=%d" % [lx, lz, y]
						)
					assert_ne(
						chunk.get_block(lx, WorldGenerator.NIVEL_AGUA + 1, lz),
						FOLHAS_ID,
						"sem folha logo acima do lago"
					)
	assert_gt(colunas_baixas, 0, "o teste precisa achar ao menos uma coluna de lago")


func test_picos_gelados_lago_e_gelo_solido_sem_agua() -> void:
	var gerador := WorldGenerator.new(7)
	var colunas_baixas := 0
	for coord: Vector2i in _chunks_do_bioma("picos_gelados"):
		var chunk := gerador.gerar_chunk(coord.x, coord.y)
		assert_false(_tem_bloco(chunk, BlockRegistry.AGUA_ID), "Picos Gelados não têm água")
		for lx in range(16):
			for lz in range(16):
				var altura: int = gerador._altura_em(coord.x * 16 + lx, coord.y * 16 + lz)
				if altura >= WorldGenerator.NIVEL_AGUA:
					continue
				colunas_baixas += 1
				for y in range(altura + 1, WorldGenerator.NIVEL_AGUA + 1):
					assert_eq(
						chunk.get_block(lx, y, lz),
						GELO_ID,
						"gelo sólido de altura+1 até o nível em (%d,%d) y=%d" % [lx, lz, y]
					)
	assert_gt(colunas_baixas, 0, "o teste precisa achar ao menos uma coluna de lago")


func test_deserto_de_ambar_fica_seco() -> void:
	var gerador := WorldGenerator.new(7)
	var chunks := _chunks_do_bioma("deserto_de_ambar")
	assert_gt(chunks.size(), 0)
	for coord: Vector2i in chunks:
		var chunk := gerador.gerar_chunk(coord.x, coord.y)
		assert_false(_tem_bloco(chunk, BlockRegistry.AGUA_ID), "deserto não deve ter água")
