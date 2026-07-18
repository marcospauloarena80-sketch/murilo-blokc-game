extends GutTest
## Ver docs/07-DECISOES.md ADR-015.


func test_paletas_tem_pelo_menos_uma_cor() -> void:
	assert_gt(CharacterAppearance.PALETA_PELE.size(), 0)
	assert_gt(CharacterAppearance.PALETA_CABELO.size(), 0)
	assert_gt(CharacterAppearance.PALETA_CAMISA.size(), 0)
	assert_gt(CharacterAppearance.PALETA_CALCA.size(), 0)


func test_aparencia_padrao_usa_primeira_cor_de_cada_paleta() -> void:
	var aparencia := CharacterAppearance.new()
	assert_eq(aparencia.cor_pele, CharacterAppearance.PALETA_PELE[0])
	assert_eq(aparencia.cor_cabelo, CharacterAppearance.PALETA_CABELO[0])
	assert_eq(aparencia.cor_camisa, CharacterAppearance.PALETA_CAMISA[0])
	assert_eq(aparencia.cor_calca, CharacterAppearance.PALETA_CALCA[0])


func test_aparencia_e_independente_por_instancia() -> void:
	var a := CharacterAppearance.new()
	var b := CharacterAppearance.new()
	a.cor_pele = Color.BLACK
	assert_ne(b.cor_pele, Color.BLACK, "mudar uma instância não deve afetar outra")
