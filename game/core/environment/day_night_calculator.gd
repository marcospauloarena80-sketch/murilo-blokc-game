class_name DayNightCalculator
extends RefCounted
## Calcula parâmetros de iluminação a partir da fase do ciclo dia/noite.
## Puro — não conhece Node3D/Light3D, só devolve números. Ver docs/01-GDD.md §3.


static func calcular(fase_0_a_1: float, fracao_dia: float) -> Dictionary:
	var fase: float = fmod(fase_0_a_1, 1.0)
	if fase < 0.0:
		fase += 1.0

	var eh_dia: bool = fase < fracao_dia
	var progresso: float

	if eh_dia:
		progresso = fase / fracao_dia
	else:
		progresso = (fase - fracao_dia) / (1.0 - fracao_dia)

	var angulo_x_graus: float
	var energia_sol: float
	var energia_ambiente: float

	if eh_dia:
		angulo_x_graus = lerp(-80.0, 80.0, progresso)
		energia_sol = sin(progresso * PI)
		energia_ambiente = lerp(0.3, 0.6, sin(progresso * PI))
	else:
		angulo_x_graus = lerp(100.0, 260.0, progresso)
		energia_sol = 0.05
		energia_ambiente = 0.08

	return {
		"eh_dia": eh_dia,
		"angulo_x_graus": angulo_x_graus,
		"energia_sol": energia_sol,
		"energia_ambiente": energia_ambiente,
	}
