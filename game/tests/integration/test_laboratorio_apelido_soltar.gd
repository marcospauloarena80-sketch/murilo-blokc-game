extends GutTest
## Laboratório (Ciclo 9, 9D): apelido, soltar e detalhes do Cubelin.

const LaboratorioScreenScene := preload("res://ui/laboratorio_screen/laboratorio_screen.tscn")


func before_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.deposito_cubelins = []
	GameState.mudar_estado(GameState.State.PLAYING)


func _tela() -> LaboratorioScreen:
	var tela := LaboratorioScreenScene.instantiate() as LaboratorioScreen
	add_child_autofree(tela)
	tela._abrir()
	return tela


func test_nome_exibido_usa_apelido_e_serializa() -> void:
	var c := CreatureInstance.new("brasita", 2)
	assert_eq(c.nome_exibido(), "Brasita")
	c.apelido = "Fofo"
	assert_eq(c.nome_exibido(), "Fofo")
	var volta := CreatureInstance.carregar_serializado(c.serializar())
	assert_eq(volta.apelido, "Fofo")


func test_apelido_limitado_a_12_letras() -> void:
	var c := CreatureInstance.new("brasita", 2)
	GameState.equipe_cubelins = [c]
	var tela := _tela()
	tela.pedir_apelido(c)
	var campo: LineEdit = tela.find_child("CampoApelido", true, false)
	assert_eq(campo.max_length, 12)
	campo.text = "NomeMuitoGrandeDemais"
	tela.confirmar_apelido()
	assert_lte(c.apelido.length(), 12)
	assert_eq(c.apelido, "NomeMuitoGra")


func test_apelido_vazio_volta_ao_nome_da_especie() -> void:
	var c := CreatureInstance.new("brasita", 2)
	c.apelido = "Fofo"
	GameState.equipe_cubelins = [c]
	var tela := _tela()
	tela.pedir_apelido(c)
	(tela.find_child("CampoApelido", true, false) as LineEdit).text = ""
	tela.confirmar_apelido()
	assert_eq(c.nome_exibido(), "Brasita")


func test_soltar_so_no_deposito_e_com_confirmacao() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("brotinho", 1)]
	GameState.deposito_cubelins = [CreatureInstance.new("ventim", 1)]
	var tela := _tela()
	var botoes_soltar := tela.find_children("BotaoSoltar", "Button", true, false)
	assert_eq(botoes_soltar.size(), 1, "só o Cubelin do depósito tem Soltar")
	tela.pedir_soltar(0)
	assert_eq(GameState.deposito_cubelins.size(), 1, "ainda não soltou")
	assert_true((tela.find_child("ConfirmacaoSoltar", true, false) as Control).visible)
	tela.confirmar_soltar()
	assert_eq(GameState.deposito_cubelins.size(), 0)
	assert_eq(GameState.equipe_cubelins.size(), 1)


func test_nao_solta_da_equipe() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("brotinho", 1)]
	var tela := _tela()
	tela.pedir_soltar(0)
	tela.confirmar_soltar()
	assert_eq(GameState.equipe_cubelins.size(), 1)


func test_detalhe_mostra_vida_nivel_e_ataques() -> void:
	var c := CreatureInstance.new("brasita", 6)
	var texto := LaboratorioScreen.texto_detalhe(c)
	assert_string_contains(texto, "Vida %d/%d" % [c.vida_atual, c.vida_maxima_efetiva()])
	assert_string_contains(texto, "Nv.6")
	assert_string_contains(texto, "Ataques:")
