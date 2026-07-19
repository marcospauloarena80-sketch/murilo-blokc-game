class_name VirtualJoystickMath
extends RefCounted
## Matemática pura do joystick virtual de movimento (F12, ADR-025). Sem Node,
## testável direto — a Control só desenha e chama isso.


static func direcao_normalizada(offset: Vector2, raio_maximo: float) -> Vector2:
	if raio_maximo <= 0.0:
		return Vector2.ZERO
	var limitado := offset
	if limitado.length() > raio_maximo:
		limitado = limitado.normalized() * raio_maximo
	return limitado / raio_maximo


static func forcas_dos_eixos(direcao: Vector2) -> Dictionary:
	return {
		"mover_direita": max(0.0, direcao.x),
		"mover_esquerda": max(0.0, -direcao.x),
		"mover_tras": max(0.0, direcao.y),
		"mover_frente": max(0.0, -direcao.y),
	}
