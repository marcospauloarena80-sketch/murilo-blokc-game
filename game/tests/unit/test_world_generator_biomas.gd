extends GutTest
## Ver docs/01-GDD.md §3 e docs/07-DECISOES.md ADR-024 (anéis por distância
## do chunk até o centro do mundo, sem blending).


func test_centro_do_mundo_e_campos_dourados() -> void:
	assert_eq(WorldGenerator.bioma_em(64, 64), "campos_dourados")


func test_ponto_a_25_de_distancia_e_floresta_cubica() -> void:
	assert_eq(WorldGenerator.bioma_em(32, 64), "floresta_cubica")


func test_ponto_a_40_de_distancia_e_colinas_de_pedra() -> void:
	assert_eq(WorldGenerator.bioma_em(16, 64), "colinas_de_pedra")


func test_ponto_a_56_de_distancia_e_deserto_de_ambar() -> void:
	assert_eq(WorldGenerator.bioma_em(64, 8), "deserto_de_ambar")


func test_canto_do_mundo_e_picos_gelados() -> void:
	assert_eq(WorldGenerator.bioma_em(0, 0), "picos_gelados")


func test_biomas_retornados_sempre_existem_no_registro() -> void:
	for wx in range(0, 128, 16):
		for wz in range(0, 128, 16):
			var bioma_id := WorldGenerator.bioma_em(wx, wz)
			assert_not_null(
				BiomeRegistry.get_bioma(bioma_id), "bioma '%s' deveria existir" % bioma_id
			)


func test_mesmo_ponto_sempre_retorna_o_mesmo_bioma() -> void:
	var primeiro := WorldGenerator.bioma_em(50, 90)
	var segundo := WorldGenerator.bioma_em(50, 90)
	assert_eq(primeiro, segundo)
