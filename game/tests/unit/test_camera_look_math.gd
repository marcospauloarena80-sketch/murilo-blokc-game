extends GutTest
## Ver docs/07-DECISOES.md ADR-025.


func test_delta_yaw_positivo_pra_direita_vira_negativo() -> void:
	assert_lt(CameraLookMath.delta_yaw(10.0, 0.01), 0.0)


func test_delta_yaw_negativo_pra_esquerda_vira_positivo() -> void:
	assert_gt(CameraLookMath.delta_yaw(-10.0, 0.01), 0.0)


func test_delta_yaw_zero_e_zero() -> void:
	assert_eq(CameraLookMath.delta_yaw(0.0, 0.01), 0.0)


func test_novo_pitch_soma_a_diferenca() -> void:
	var resultado := CameraLookMath.novo_pitch(0.0, -10.0, 0.01)
	assert_almost_eq(resultado, 0.1, 0.001)


func test_novo_pitch_nao_passa_do_maximo() -> void:
	var resultado := CameraLookMath.novo_pitch(1.29, -100.0, 0.01)
	assert_eq(resultado, CameraLookMath.PITCH_MAX)


func test_novo_pitch_nao_passa_do_minimo() -> void:
	var resultado := CameraLookMath.novo_pitch(-1.19, 100.0, 0.01)
	assert_eq(resultado, CameraLookMath.PITCH_MIN)
