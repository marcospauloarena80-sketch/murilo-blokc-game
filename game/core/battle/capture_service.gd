class_name CaptureService
extends RefCounted
## Chance de captura de Cubelin selvagem (F8). Pura e testável — sorteio
## sempre injetado por parâmetro, nunca chamado internamente. Ver
## docs/01-GDD.md §10 e docs/07-DECISOES.md ADR-021.

const CHANCE_MINIMA: float = 0.05
const CHANCE_MAXIMA: float = 0.95


static func chance_de_captura(hp_percentual: float, tier: int = 1) -> float:
	var hp_clampado: float = clamp(hp_percentual, 0.0, 1.0)
	var base: float = (1.0 - hp_clampado) * 0.9 + 0.1  # 0,1 com hp cheio .. 1,0 quase desmaiado
	var com_tier: float = base * (1.0 + 0.2 * (tier - 1))  # tier 1 = sem bônus (única tier no MVP)
	return clamp(com_tier, CHANCE_MINIMA, CHANCE_MAXIMA)


static func tentar_capturar(alvo: CreatureInstance, tier: int, sorteio: float) -> bool:
	var hp_percentual: float = float(alvo.vida_atual) / float(max(1, alvo.vida_maxima_efetiva()))
	return sorteio < chance_de_captura(hp_percentual, tier)
