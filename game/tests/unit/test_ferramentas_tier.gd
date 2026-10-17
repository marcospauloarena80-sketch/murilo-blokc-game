extends GutTest
## Ciclo 8 (8E): tier mínimo para quebrar e multiplicador só com a ferramenta certa.


func _bloco(id: int) -> BlockDef:
	return BlockRegistry.get_block(id)


func _item(id: String) -> ItemDef:
	return ItemRegistry.get_item(id)


func test_tiers_das_picaretas() -> void:
	assert_eq(_item("picareta_madeira").tier, 1)
	assert_eq(_item("picareta_pedra").tier, 2)
	assert_eq(_item("picareta_ferrite").tier, 3)
	assert_eq(_item("picareta_cristal_dourado").tier, 4)
	assert_eq(_item("picareta_madeira").tipo_ferramenta, "picareta")
	assert_eq(_item("machado_madeira").tipo_ferramenta, "machado")


func test_tiers_minimos_dos_blocos() -> void:
	assert_eq(_bloco(3).tier_minimo, 1, "pedra")
	assert_eq(_bloco(10).tier_minimo, 1, "carvão")
	assert_eq(_bloco(11).tier_minimo, 2, "ferrite")
	assert_eq(_bloco(12).tier_minimo, 3, "cristal")
	assert_eq(_bloco(15).tier_minimo, 1, "âmbar")
	for id: int in [1, 2, 5, 6]:
		assert_eq(_bloco(id).tier_minimo, 0, "terra, grama, folhas e areia quebram na mão")
	assert_eq(_bloco(4).ferramenta_ideal, "machado")
	assert_eq(_bloco(4).tier_minimo, 0)


func test_ferrite_nao_quebra_com_picareta_de_madeira() -> void:
	assert_false(Ferramentas.pode_quebrar(_bloco(11), _item("picareta_madeira")))
	assert_true(Ferramentas.pode_quebrar(_bloco(11), _item("picareta_pedra")))
	assert_true(Ferramentas.pode_quebrar(_bloco(11), _item("picareta_cristal_dourado")))


func test_pedra_exige_picareta_e_nao_quebra_na_mao_nem_com_machado() -> void:
	assert_false(Ferramentas.pode_quebrar(_bloco(3), null))
	assert_false(Ferramentas.pode_quebrar(_bloco(3), _item("machado_ferrite")))
	assert_true(Ferramentas.pode_quebrar(_bloco(3), _item("picareta_madeira")))


func test_bloco_sem_tier_quebra_na_mao() -> void:
	assert_true(Ferramentas.pode_quebrar(_bloco(2), null))
	assert_true(Ferramentas.pode_quebrar(_bloco(4), null), "tronco quebra na mão")


func test_ferramenta_errada_usa_multiplicador_1() -> void:
	assert_eq(Ferramentas.multiplicador(_bloco(4), _item("picareta_pedra")), 1.0)
	assert_eq(Ferramentas.multiplicador(_bloco(4), _item("machado_madeira")), 2.0)
	assert_eq(Ferramentas.multiplicador(_bloco(3), _item("picareta_pedra")), 3.5)
	assert_eq(Ferramentas.multiplicador(_bloco(3), _item("machado_ferrite")), 1.0)


func test_bloco_sem_ferramenta_ideal_aceita_qualquer_ferramenta() -> void:
	assert_eq(Ferramentas.multiplicador(_bloco(2), _item("picareta_pedra")), 3.5)
	assert_eq(Ferramentas.multiplicador(_bloco(2), null), 1.0)


func test_aviso_pede_picareta_melhor() -> void:
	assert_eq(Ferramentas.aviso_tier(_bloco(11)), "Precisa de picareta melhor")
