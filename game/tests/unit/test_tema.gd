extends GutTest
## Frente 6A (Ciclo 6): tema do Vale Dourado gerado por código em
## tools/gerar_tema.gd e registrado em project.godot (gui/theme/custom).
## Nenhum .tscn precisa mudar: o tema vale pra todo Control do projeto.

const CAMINHO_TEMA := "res://ui/theme/tema_vale.tres"


func test_project_settings_aponta_pro_tema() -> void:
	assert_eq(String(ProjectSettings.get_setting("gui/theme/custom", "")), CAMINHO_TEMA)


func test_tema_carrega_com_estilos_e_fonte_padrao() -> void:
	var tema := load(CAMINHO_TEMA) as Theme
	assert_not_null(tema, "o .tres gerado deveria carregar como Theme")
	if tema == null:
		return
	assert_true(tema.has_stylebox("panel", "PanelContainer"))
	assert_true(tema.has_stylebox("normal", "Button"))
	assert_eq(tema.default_font_size, 18)


func test_botao_na_cena_herda_fundo_azul_do_tema() -> void:
	var botao := Button.new()
	add_child_autofree(botao)
	var estilo := botao.get_theme_stylebox("normal") as StyleBoxFlat
	assert_not_null(estilo, "Button/normal deveria ser um StyleBoxFlat do tema")
	if estilo == null:
		return
	assert_eq(estilo.bg_color.to_html(false), "3a86ff")
