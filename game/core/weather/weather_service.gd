class_name WeatherService
extends RefCounted
## Lógica pura de sorteio de clima (F11, ADR-024). Sorteio sempre injetado
## por parâmetro — nunca chamado internamente — mesmo padrão de
## BattleService/CaptureService (ADR-021). Visual + spawn, sem dano
## (docs/01-GDD.md §3).

enum Estado { NENHUM, CHUVA, TEMPESTADE }

const CHANCE_NENHUM: float = 0.6
const CHANCE_CHUVA: float = 0.3
## Restante (0.1) vira tempestade.


static func sortear_estado(sorteio: float) -> Estado:
	if sorteio < CHANCE_NENHUM:
		return Estado.NENHUM
	if sorteio < CHANCE_NENHUM + CHANCE_CHUVA:
		return Estado.CHUVA
	return Estado.TEMPESTADE
