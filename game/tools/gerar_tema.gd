extends SceneTree
## Gera ui/theme/tema_vale.tres: o tema do Vale Dourado (Ciclo 6, Frente 6A),
## montado por código (sem asset de terceiro) e registrado em project.godot
## como gui/theme/custom, então vale pra todo Control sem mexer nos .tscn.
## Determinístico: cada sub-recurso tem id fixo, então rodar de novo produz o
## mesmo .tres. Uso: godot --headless -s res://tools/gerar_tema.gd

const CAMINHO_TRES := "res://ui/theme/tema_vale.tres"

## Paleta do Vale: noite azulada nos painéis, dourado nos destaques.
const FUNDO_PAINEL := Color(0.08, 0.1, 0.16, 0.86)
const DOURADO := Color(0.95, 0.78, 0.35)
const AZUL := Color("#3a86ff")
const AZUL_PRESSIONADO := Color("#2f6fd1")
const DOURADO_HOVER := Color("#f2c14e")
const TEXTO_ESCURO := Color(0.12, 0.1, 0.06)
const CINZA_DESATIVADO := Color(0.55, 0.57, 0.62, 0.45)
const FUNDO_CAMPO := Color(0.05, 0.07, 0.12, 0.9)
const BORDA_CAMPO := Color(0.35, 0.45, 0.7)


func _init() -> void:
	var tema := Theme.new()
	tema.default_font_size = 18
	_painel(tema)
	_botao(tema)
	_rotulo(tema)
	_barra_progresso(tema)
	_campo_texto(tema)
	_caixa_marcar(tema)
	var caminho := ProjectSettings.globalize_path(CAMINHO_TRES)
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	var erro := ResourceSaver.save(tema, CAMINHO_TRES)
	print("TEMA ", caminho, " ", error_string(erro))
	quit()


## Cria um StyleBoxFlat com fundo, cantos e borda; `id` fixa o nome do
## sub-recurso no .tres pra o arquivo gerado ser sempre igual.
func _caixa(
	id: String, fundo: Color, cantos: int, borda: int = 0, cor_borda := DOURADO
) -> StyleBoxFlat:
	var caixa := StyleBoxFlat.new()
	caixa.resource_scene_unique_id = id
	caixa.bg_color = fundo
	caixa.set_corner_radius_all(cantos)
	if borda > 0:
		caixa.set_border_width_all(borda)
		caixa.border_color = cor_borda
	return caixa


## Margens internas: `horizontal` nos lados, `vertical` em cima e embaixo.
func _margens(caixa: StyleBoxFlat, horizontal: int, vertical: int) -> void:
	caixa.set_content_margin(SIDE_LEFT, horizontal)
	caixa.set_content_margin(SIDE_RIGHT, horizontal)
	caixa.set_content_margin(SIDE_TOP, vertical)
	caixa.set_content_margin(SIDE_BOTTOM, vertical)


## Caixa só de contorno (fundo não desenhado), usada pro foco do teclado.
func _contorno(id: String, cantos: int) -> StyleBoxFlat:
	var caixa := _caixa(id, Color.TRANSPARENT, cantos, 2)
	caixa.draw_center = false
	return caixa


func _painel(tema: Theme) -> void:
	var painel := _caixa("painel", FUNDO_PAINEL, 12, 2)
	painel.set_content_margin_all(14)
	tema.set_stylebox("panel", "PanelContainer", painel)


func _botao(tema: Theme) -> void:
	var estilos := {
		"normal": _caixa("botao_normal", AZUL, 8),
		"hover": _caixa("botao_hover", DOURADO_HOVER, 8),
		"pressed": _caixa("botao_pressed", AZUL_PRESSIONADO, 8),
		"disabled": _caixa("botao_disabled", CINZA_DESATIVADO, 8),
	}
	for nome: String in estilos:
		var caixa: StyleBoxFlat = estilos[nome]
		_margens(caixa, 10, 6)
		tema.set_stylebox(nome, "Button", caixa)
	tema.set_stylebox("focus", "Button", _contorno("botao_focus", 8))
	tema.set_font_size("font_size", "Button", 18)
	tema.set_color("font_color", "Button", Color.WHITE)
	tema.set_color("font_focus_color", "Button", Color.WHITE)
	tema.set_color("font_pressed_color", "Button", Color.WHITE)
	tema.set_color("font_hover_color", "Button", TEXTO_ESCURO)
	tema.set_color("font_hover_pressed_color", "Button", TEXTO_ESCURO)
	tema.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.5))


func _rotulo(tema: Theme) -> void:
	tema.set_color("font_outline_color", "Label", Color.BLACK)
	tema.set_constant("outline_size", "Label", 3)


func _barra_progresso(tema: Theme) -> void:
	tema.set_stylebox("background", "ProgressBar", _caixa("barra_fundo", FUNDO_CAMPO, 6))
	tema.set_stylebox("fill", "ProgressBar", _caixa("barra_cheia", DOURADO, 6))


func _campo_texto(tema: Theme) -> void:
	var normal := _caixa("campo_normal", FUNDO_CAMPO, 8, 1, BORDA_CAMPO)
	_margens(normal, 10, 6)
	tema.set_stylebox("normal", "LineEdit", normal)
	tema.set_stylebox("read_only", "LineEdit", _caixa("campo_leitura", CINZA_DESATIVADO, 8))
	tema.set_stylebox("focus", "LineEdit", _contorno("campo_focus", 8))
	tema.set_color("font_color", "LineEdit", Color.WHITE)
	tema.set_color("font_placeholder_color", "LineEdit", Color(1, 1, 1, 0.45))
	tema.set_color("caret_color", "LineEdit", DOURADO)
	tema.set_color("selection_color", "LineEdit", Color(AZUL, 0.5))


func _caixa_marcar(tema: Theme) -> void:
	tema.set_stylebox("focus", "CheckBox", _contorno("marcar_focus", 6))
	tema.set_font_size("font_size", "CheckBox", 18)
	tema.set_color("font_color", "CheckBox", Color.WHITE)
	tema.set_color("font_hover_color", "CheckBox", DOURADO_HOVER)
	tema.set_color("font_pressed_color", "CheckBox", Color.WHITE)
	tema.set_color("font_disabled_color", "CheckBox", Color(1, 1, 1, 0.5))
