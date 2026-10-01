class_name DayNightCalculator
extends RefCounted
## Calcula parâmetros de iluminação a partir da fase do ciclo dia/noite.
## Puro — não conhece Node3D/Light3D, só devolve números. Ver docs/01-GDD.md §3.
## Ciclo 4 (ADR-027): o sol (e a lua, à noite) faz um arco de leste a oeste,
## alto ao meio-dia. Antes ele só girava no eixo X de -80° a +80°: ao meio-dia
## a luz ficava na horizontal e no fim da tarde vinha de baixo do chão. A
## paleta do céu também sai daqui, interpolada entre momentos do ciclo.

const ELEVACAO_MAX_SOL: float = 62.0
const ELEVACAO_MAX_LUA: float = 48.0
const ELEVACAO_MIN: float = 6.0  ## nunca rente ao chão: sombra infinita e luz por baixo

## [fase do ciclo, topo do céu, horizonte, cor da luz]. Fase 0 = nascer do sol;
## dia vai até FRACAO_DIA (2/3); depois noite até 1.
const _PALETA: Array = [
	[0.0, "6a7fd1", "ffb38a", "ffc28a"],
	[0.07, "4a90ff", "cfe9ff", "fff1dc"],
	[0.33, "3a86ff", "bfe2ff", "fff8ec"],
	[0.585, "4a8cf0", "d6e6ff", "ffeedd"],
	[0.645, "5b5fc0", "ff9466", "ff9a5a"],
	[0.7, "262a6b", "8a4f8f", "8a7cd0"],
	[0.77, "070b24", "1c2650", "8fa6ff"],
	[0.955, "0a1030", "2a3266", "8fa6ff"],
	[1.0, "6a7fd1", "ffb38a", "ffc28a"],
]


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

	var energia_sol: float
	var energia_ambiente: float
	var elevacao: float

	if eh_dia:
		energia_sol = sin(progresso * PI)
		energia_ambiente = lerp(0.3, 0.6, sin(progresso * PI))
		elevacao = maxf(ELEVACAO_MIN, sin(progresso * PI) * ELEVACAO_MAX_SOL)
	else:
		energia_sol = 0.05
		energia_ambiente = 0.3  ## noite azulada e legível, não breu (Ciclo 4)
		elevacao = maxf(ELEVACAO_MIN, sin(progresso * PI) * ELEVACAO_MAX_LUA)

	var cores := _cores_do_ceu(fase)
	return {
		"eh_dia": eh_dia,
		## Rotação da DirectionalLight3D: x inclina a luz pra baixo (elevação),
		## y gira de leste (+90) pra oeste (-90) ao longo do dia ou da noite.
		"angulo_x_graus": -elevacao,
		"angulo_y_graus": lerp(90.0, -90.0, progresso),
		"energia_sol": energia_sol,
		"energia_ambiente": energia_ambiente,
		"cor_ceu_topo": cores[0],
		"cor_ceu_horizonte": cores[1],
		"cor_luz": cores[2],
		"noite": _intensidade_da_noite(fase, fracao_dia),
	}


static func _cores_do_ceu(fase: float) -> Array[Color]:
	for i: int in range(_PALETA.size() - 1):
		var a: Array = _PALETA[i]
		var b: Array = _PALETA[i + 1]
		if fase >= float(a[0]) and fase <= float(b[0]):
			var t: float = (fase - float(a[0])) / maxf(0.0001, float(b[0]) - float(a[0]))
			t = smoothstep(0.0, 1.0, t)
			return [
				Color.html(a[1]).lerp(Color.html(b[1]), t),
				Color.html(a[2]).lerp(Color.html(b[2]), t),
				Color.html(a[3]).lerp(Color.html(b[3]), t),
			]
	var ultimo: Array = _PALETA[_PALETA.size() - 1]
	return [Color.html(ultimo[1]), Color.html(ultimo[2]), Color.html(ultimo[3])]


static func _intensidade_da_noite(fase: float, fracao_dia: float) -> float:
	## 0 de dia, 1 no meio da noite; estrelas e lua acendem no crepúsculo.
	if fase < fracao_dia:
		return 0.0
	var entrada: float = smoothstep(fracao_dia, fracao_dia + 0.08, fase)
	var saida: float = 1.0 - smoothstep(0.95, 1.0, fase)
	return minf(entrada, saida)
