class_name CharacterAppearance
extends Resource
## Aparência do Murilo: só cor, sem itens equipáveis (ADR-015).
## Ver docs/01-GDD.md "Personalização do Murilo" e docs/02-ARQUITETURA.md.

const PALETA_PELE: Array[Color] = [
	Color("#ffdbac"),
	Color("#f1c27d"),
	Color("#e0ac69"),
	Color("#c68642"),
	Color("#8d5524"),
	Color("#4a2c14"),
]
const PALETA_CABELO: Array[Color] = [
	Color("#2c1b10"),
	Color("#5a3825"),
	Color("#a0522d"),
	Color("#d2b48c"),
	Color("#e8d44d"),
	Color("#1c1c1c"),
]
const PALETA_CAMISA: Array[Color] = [
	Color("#e74c3c"),
	Color("#3498db"),
	Color("#2ecc71"),
	Color("#f1c40f"),
	Color("#9b59b6"),
	Color("#ecf0f1"),
	Color("#e67e22"),
	Color("#34495e"),
]
const PALETA_CALCA: Array[Color] = [
	Color("#2c3e50"),
	Color("#7f8c8d"),
	Color("#34495e"),
	Color("#5d4037"),
	Color("#1c1c1c"),
	Color("#455a64"),
	Color("#3e2723"),
	Color("#616161"),
]

@export var cor_pele: Color = PALETA_PELE[0]
@export var cor_cabelo: Color = PALETA_CABELO[0]
@export var cor_camisa: Color = PALETA_CAMISA[0]
@export var cor_calca: Color = PALETA_CALCA[0]
