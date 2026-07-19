extends GutTest
## Ver docs/01-GDD.md §10 (captura) e docs/07-DECISOES.md ADR-021.


func test_chance_maior_com_vida_baixa() -> void:
	var chance_hp_cheio := CaptureService.chance_de_captura(1.0)
	var chance_hp_baixo := CaptureService.chance_de_captura(0.05)
	assert_gt(chance_hp_baixo, chance_hp_cheio)


func test_chance_com_vida_cheia_e_baixa_mas_nao_zero() -> void:
	var chance := CaptureService.chance_de_captura(1.0)
	assert_almost_eq(chance, 0.1, 0.001)


func test_chance_com_vida_zero_e_alta_mas_nao_100_por_cento() -> void:
	var chance := CaptureService.chance_de_captura(0.0)
	assert_lte(chance, CaptureService.CHANCE_MAXIMA)
	assert_gt(chance, 0.9)


func test_chance_e_limitada_entre_minima_e_maxima() -> void:
	var chance_cheio := CaptureService.chance_de_captura(1.0, 5)
	var chance_vazio := CaptureService.chance_de_captura(0.0, 5)
	assert_gte(chance_cheio, CaptureService.CHANCE_MINIMA)
	assert_lte(chance_vazio, CaptureService.CHANCE_MAXIMA)


func test_tier_maior_aumenta_a_chance() -> void:
	var tier_1 := CaptureService.chance_de_captura(0.5, 1)
	var tier_2 := CaptureService.chance_de_captura(0.5, 2)
	assert_gt(tier_2, tier_1)


func test_tentar_capturar_usa_hp_atual_da_instancia() -> void:
	var alvo := CreatureInstance.new("brotinho", 1)
	alvo.vida_atual = 1  # quase desmaiado -> chance alta

	assert_true(CaptureService.tentar_capturar(alvo, 1, 0.05))


func test_tentar_capturar_falha_com_sorteio_alto() -> void:
	var alvo := CreatureInstance.new("brotinho", 1)
	# vida cheia -> chance baixa (~0,1)

	assert_false(CaptureService.tentar_capturar(alvo, 1, 0.99))
