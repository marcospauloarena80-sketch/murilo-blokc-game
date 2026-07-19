extends GutTest
## Ver docs/07-DECISOES.md ADR-025.


func test_direcao_dentro_do_raio_fica_proporcional() -> void:
	var direcao := VirtualJoystickMath.direcao_normalizada(Vector2(30, 0), 60.0)
	assert_almost_eq(direcao.x, 0.5, 0.001)
	assert_almost_eq(direcao.y, 0.0, 0.001)


func test_direcao_fora_do_raio_fica_limitada_a_1() -> void:
	var direcao := VirtualJoystickMath.direcao_normalizada(Vector2(200, 0), 60.0)
	assert_almost_eq(direcao.length(), 1.0, 0.001)


func test_direcao_zero_fica_zero() -> void:
	var direcao := VirtualJoystickMath.direcao_normalizada(Vector2.ZERO, 60.0)
	assert_eq(direcao, Vector2.ZERO)


func test_raio_maximo_zero_nao_gera_divisao_por_zero() -> void:
	var direcao := VirtualJoystickMath.direcao_normalizada(Vector2(10, 10), 0.0)
	assert_eq(direcao, Vector2.ZERO)


func test_forcas_pra_frente() -> void:
	var forcas := VirtualJoystickMath.forcas_dos_eixos(Vector2(0, -1))
	assert_eq(forcas["mover_frente"], 1.0)
	assert_eq(forcas["mover_tras"], 0.0)
	assert_eq(forcas["mover_esquerda"], 0.0)
	assert_eq(forcas["mover_direita"], 0.0)


func test_forcas_diagonal() -> void:
	var forcas := VirtualJoystickMath.forcas_dos_eixos(Vector2(0.7, -0.7))
	assert_almost_eq(forcas["mover_direita"], 0.7, 0.001)
	assert_almost_eq(forcas["mover_frente"], 0.7, 0.001)
	assert_eq(forcas["mover_esquerda"], 0.0)
	assert_eq(forcas["mover_tras"], 0.0)
