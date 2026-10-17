extends GutTest
## Ciclo 8 (8E): túneis de "minhocas" — determinísticos por semente, contínuos e
## sempre abaixo da superfície.

const VIZINHOS: Array[Vector3i] = [
	Vector3i(1, 0, 0),
	Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(0, -1, 0),
	Vector3i(0, 0, 1),
	Vector3i(0, 0, -1),
]


func _maior_regiao_de_ar(chunk: ChunkData) -> int:
	var restante: Dictionary = {}
	for x in range(16):
		for z in range(16):
			for y in range(1, 26):
				if chunk.get_block(x, y, z) == BlockRegistry.AR_ID:
					restante[Vector3i(x, y, z)] = true
	var melhor: int = 0
	while not restante.is_empty():
		var inicio: Vector3i = restante.keys()[0]
		var fila: Array[Vector3i] = [inicio]
		restante.erase(inicio)
		var tamanho: int = 0
		while not fila.is_empty():
			var atual: Vector3i = fila.pop_back()
			tamanho += 1
			for v: Vector3i in VIZINHOS:
				var vizinho := atual + v
				if restante.has(vizinho):
					restante.erase(vizinho)
					fila.append(vizinho)
		melhor = maxi(melhor, tamanho)
	return melhor


func test_mesma_semente_gera_o_mesmo_tunel() -> void:
	var a := WorldGenerator.new(77)
	var b := WorldGenerator.new(77)
	for cx in range(6):
		for cz in range(6):
			assert_eq(
				a.gerar_chunk(cx, cz).dados(),
				b.gerar_chunk(cx, cz).dados(),
				"chunk (%d,%d) igual" % [cx, cz]
			)


func test_ha_ar_conectado_abaixo_da_superficie_em_algum_chunk() -> void:
	var gerador := WorldGenerator.new(2024)
	var maior: int = 0
	for cx in range(8):
		for cz in range(8):
			maior = maxi(maior, _maior_regiao_de_ar(gerador.gerar_chunk(cx, cz)))
	## O bolsão de raio 2 tem 33 células; um túnel de 24 passos passa bem disso.
	assert_gt(maior, 60, "algum chunk tem túnel contínuo de ar no subsolo")


func test_tunel_nao_fura_a_superficie() -> void:
	var gerador := WorldGenerator.new(31)
	for cx in range(8):
		for cz in range(8):
			var chunk := gerador.gerar_chunk(cx, cz)
			for x in range(16):
				for z in range(16):
					var wx := cx * 16 + x
					var wz := cz * 16 + z
					if wx >= 50 and wx <= 85 and wz >= 50 and wz <= 85:
						continue  # vilarejo (8D) aplaina o terreno
					var altura := gerador._altura_em(wx, wz)
					assert_ne(
						chunk.get_block(x, altura, z),
						BlockRegistry.AR_ID,
						"superfície (%d,%d) intacta" % [x, z]
					)
