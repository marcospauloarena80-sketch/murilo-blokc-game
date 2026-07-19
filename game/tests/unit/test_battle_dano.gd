extends GutTest
## Ver docs/01-GDD.md §9/§11 e docs/07-DECISOES.md ADR-021.
## multiplicador_elemental + calcular_dano (parte 1/3 dos testes de BattleService,
## separados por causa do limite de métodos públicos por arquivo do gdlint).


func test_vantagem_brasa_sobre_mato() -> void:
	assert_eq(BattleService.multiplicador_elemental("brasa", "mato"), 1.5)


func test_desvantagem_mato_contra_brasa() -> void:
	assert_eq(BattleService.multiplicador_elemental("mato", "brasa"), 0.75)


func test_vantagem_pedra_sobre_faisca() -> void:
	assert_eq(BattleService.multiplicador_elemental("pedra", "faisca"), 1.5)


func test_desvantagem_pedra_contra_vento() -> void:
	assert_eq(BattleService.multiplicador_elemental("pedra", "vento"), 0.75)


func test_vantagem_vento_sobre_pedra() -> void:
	assert_eq(BattleService.multiplicador_elemental("vento", "pedra"), 1.5)


func test_elementos_sem_relacao_sao_neutros() -> void:
	assert_eq(BattleService.multiplicador_elemental("pedra", "gota"), 1.0)


func test_mesmo_elemento_e_neutro() -> void:
	assert_eq(BattleService.multiplicador_elemental("pedra", "pedra"), 1.0)


func test_calcular_dano_formula_basica_sem_variacao() -> void:
	var atacante := CreatureInstance.new("pedrolim", 1)  # forca 8
	var alvo := CreatureInstance.new("brotinho", 1)  # guarda 6, elemento mato
	var ataque := AttackRegistry.get_ataque("pedra_investida")  # poder 6, elemento pedra
	# pedra vs mato = neutro (1.0); dano = 6 * (8/6) * 1.0 * 1.0 = 8
	var dano := BattleService.calcular_dano(atacante, alvo, ataque, 1.0)
	assert_eq(dano, 8)


func test_calcular_dano_aplica_vantagem_elemental() -> void:
	var atacante := CreatureInstance.new("pedrolim", 5)  # elemento pedra
	var alvo := CreatureInstance.new("faiscolt", 5)  # elemento faísca -> pedra tem vantagem (1,5x)
	var ataque := AttackRegistry.get_ataque("pedra_investida")

	var dano := BattleService.calcular_dano(atacante, alvo, ataque, 1.0)
	var razao: float = float(atacante.forca_efetiva()) / float(alvo.guarda_efetiva())
	var esperado: int = max(1, int(round(ataque.poder * razao * 1.5)))

	assert_eq(dano, esperado)


func test_calcular_dano_minimo_e_1() -> void:
	var atacante := CreatureInstance.new("brotinho", 1)
	var alvo := CreatureInstance.new("pedrolim", 30)  # guarda gigante, quase anula o dano
	var ataque := AttackRegistry.get_ataque("mato_investida")
	var dano := BattleService.calcular_dano(atacante, alvo, ataque, 0.9)
	assert_eq(dano, 1)


func test_calcular_dano_variacao_influencia_o_resultado() -> void:
	var atacante := CreatureInstance.new("pedrolim", 5)
	var alvo := CreatureInstance.new("faiscolt", 5)
	var ataque := AttackRegistry.get_ataque("pedra_investida")
	var dano_baixo := BattleService.calcular_dano(atacante, alvo, ataque, 0.9)
	var dano_alto := BattleService.calcular_dano(atacante, alvo, ataque, 1.1)
	assert_gte(dano_alto, dano_baixo)
