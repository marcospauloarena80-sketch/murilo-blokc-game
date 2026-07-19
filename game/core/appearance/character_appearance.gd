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


func serializar() -> Dictionary:
	## Color não é JSON-safe nativamente — vira array [r,g,b,a].
	return {
		"cor_pele": _cor_para_array(cor_pele),
		"cor_cabelo": _cor_para_array(cor_cabelo),
		"cor_camisa": _cor_para_array(cor_camisa),
		"cor_calca": _cor_para_array(cor_calca),
	}


func carregar_serializado(dados: Dictionary) -> void:
	cor_pele = _array_para_cor(dados.get("cor_pele", []), PALETA_PELE[0])
	cor_cabelo = _array_para_cor(dados.get("cor_cabelo", []), PALETA_CABELO[0])
	cor_camisa = _array_para_cor(dados.get("cor_camisa", []), PALETA_CAMISA[0])
	cor_calca = _array_para_cor(dados.get("cor_calca", []), PALETA_CALCA[0])


static func _cor_para_array(cor: Color) -> Array:
	return [cor.r, cor.g, cor.b, cor.a]


static func _array_para_cor(dados: Array, padrao: Color) -> Color:
	if dados.size() < 4:
		return padrao
	return Color(dados[0], dados[1], dados[2], dados[3])
