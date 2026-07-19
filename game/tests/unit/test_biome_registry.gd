extends GutTest
## Ver docs/01-GDD.md §3 e docs/07-DECISOES.md ADR-024.

const BIOMAS := [
	"campos_dourados", "floresta_cubica", "colinas_de_pedra", "deserto_de_ambar", "picos_gelados"
]


func test_5_biomas_existem() -> void:
	for id: String in BIOMAS:
		assert_not_null(BiomeRegistry.get_bioma(id), "bioma '%s' deveria existir" % id)
	assert_eq(BiomeRegistry.todos_os_ids().size(), 5)


func test_cada_bioma_tem_pelo_menos_1_elemento_de_cubelin() -> void:
	for id: String in BIOMAS:
		var bioma := BiomeRegistry.get_bioma(id)
		assert_gt(bioma.elementos_cubelin.size(), 0, "%s deveria ter elemento de Cubelin" % id)


func test_bioma_inexistente_retorna_null() -> void:
	assert_null(BiomeRegistry.get_bioma("nao_existe"))


func test_campos_dourados_tem_mato_e_vento() -> void:
	var bioma := BiomeRegistry.get_bioma("campos_dourados")
	assert_true(bioma.elementos_cubelin.has("mato"))
	assert_true(bioma.elementos_cubelin.has("vento"))
