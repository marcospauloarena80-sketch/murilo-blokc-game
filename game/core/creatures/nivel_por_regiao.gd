class_name NivelPorRegiao
extends RefCounted
## Nível dos Cubelins selvagens por bioma (Ciclo 9, 9A): quanto mais longe do
## centro do mundo, mais forte. Faixas inclusivas por anel de bioma.

const FAIXAS: Dictionary = {
	"campos_dourados": Vector2i(3, 5),
	"floresta_cubica": Vector2i(5, 8),
	"colinas_de_pedra": Vector2i(8, 12),
	"deserto_de_ambar": Vector2i(12, 16),
	"picos_gelados": Vector2i(16, 20),
}
const FAIXA_PADRAO: Vector2i = Vector2i(3, 5)


static func faixa(bioma_id: String) -> Vector2i:
	return FAIXAS.get(bioma_id, FAIXA_PADRAO)


static func sortear(bioma_id: String, rng: RandomNumberGenerator) -> int:
	var limites: Vector2i = faixa(bioma_id)
	return rng.randi_range(limites.x, limites.y)
