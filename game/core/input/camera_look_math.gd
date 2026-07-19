class_name CameraLookMath
extends RefCounted
## Matemática pura de rotação de câmera por mouse/arrasto de tela (F12).
## Sem Node, testável direto. Ver docs/07-DECISOES.md ADR-025.

const PITCH_MIN: float = -1.2  ## ~-69°, olhar quase reto pra baixo
const PITCH_MAX: float = 1.3  ## ~74°, olhar quase reto pra cima


static func delta_yaw(delta_x: float, sensibilidade: float) -> float:
	return -delta_x * sensibilidade


static func novo_pitch(pitch_atual: float, delta_y: float, sensibilidade: float) -> float:
	return clamp(pitch_atual - delta_y * sensibilidade, PITCH_MIN, PITCH_MAX)
