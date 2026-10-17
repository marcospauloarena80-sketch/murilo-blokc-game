class_name LaboratorioScreen
extends CanvasLayer
## Laboratório da Professora Lina (F9): gerencia GameState.deposito_cubelins
## e GameState.equipe_cubelins. Abre via EventBus.laboratorio_requested.
## Ver docs/01-GDD.md §12 e docs/07-DECISOES.md ADR-022.

const TAMANHO_MAX_APELIDO: int = 12

var _aberto: bool = false
var _editor_apelido: HBoxContainer
var _campo_apelido: LineEdit
var _confirmacao_soltar: HBoxContainer
var _alvo_apelido: CreatureInstance
var _indice_soltar: int = -1

@onready var _grid_equipe: VBoxContainer = $Control/Painel/Margem/VBox/GridEquipe
@onready var _grid_deposito: VBoxContainer = $Control/Painel/Margem/VBox/GridDeposito
@onready var _botao_fechar: Button = $Control/Painel/Margem/VBox/BotaoFechar


func _ready() -> void:
	visible = false
	_botao_fechar.pressed.connect(_fechar)
	_criar_editores()
	EventBus.laboratorio_requested.connect(_abrir)


func _abrir() -> void:
	_aberto = true
	visible = true
	_editor_apelido.visible = false
	_confirmacao_soltar.visible = false
	GameState.abrir_tela("laboratorio")
	_atualizar()


func _fechar() -> void:
	_aberto = false
	visible = false
	GameState.fechar_tela("laboratorio")


func _ao_clicar_equipe(indice: int) -> void:
	if indice < 0 or indice >= GameState.equipe_cubelins.size():
		return
	var instancia: CreatureInstance = GameState.equipe_cubelins[indice]
	GameState.equipe_cubelins.remove_at(indice)
	GameState.deposito_cubelins.append(instancia)
	EventBus.team_changed.emit()
	_atualizar()


func _ao_clicar_deposito(indice: int) -> void:
	if indice < 0 or indice >= GameState.deposito_cubelins.size():
		return
	if GameState.equipe_cubelins.size() >= GameState.MAX_EQUIPE:
		return
	var instancia: CreatureInstance = GameState.deposito_cubelins[indice]
	GameState.deposito_cubelins.remove_at(indice)
	GameState.equipe_cubelins.append(instancia)
	EventBus.team_changed.emit()
	_atualizar()


func _atualizar() -> void:
	for filho in _grid_equipe.get_children():
		filho.queue_free()
	for filho in _grid_deposito.get_children():
		filho.queue_free()
	for i in range(GameState.equipe_cubelins.size()):
		var instancia: CreatureInstance = GameState.equipe_cubelins[i]
		var botao := Button.new()
		botao.text = "%s Nv.%d (equipe)" % [instancia.nome_exibido(), instancia.nivel]
		botao.pressed.connect(_ao_clicar_equipe.bind(i))
		_grid_equipe.add_child(_linha(botao, instancia, -1))

	for i in range(GameState.deposito_cubelins.size()):
		var instancia: CreatureInstance = GameState.deposito_cubelins[i]
		var botao := Button.new()
		botao.text = "%s Nv.%d (depósito)" % [instancia.nome_exibido(), instancia.nivel]
		botao.disabled = GameState.equipe_cubelins.size() >= GameState.MAX_EQUIPE
		botao.pressed.connect(_ao_clicar_deposito.bind(i))
		_grid_deposito.add_child(_linha(botao, instancia, i))


## Linha de um Cubelin (Ciclo 9, 9D): botão de mover, vida/ataques, Apelido e,
## só no depósito (indice_deposito >= 0), Soltar.
func _linha(botao: Button, instancia: CreatureInstance, indice_deposito: int) -> VBoxContainer:
	var linha := VBoxContainer.new()
	var topo := HBoxContainer.new()
	botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(botao)
	var botao_apelido := Button.new()
	botao_apelido.name = "BotaoApelido"
	botao_apelido.text = "Apelido"
	botao_apelido.pressed.connect(pedir_apelido.bind(instancia))
	topo.add_child(botao_apelido)
	if indice_deposito >= 0:
		var botao_soltar := Button.new()
		botao_soltar.name = "BotaoSoltar"
		botao_soltar.text = "Soltar"
		botao_soltar.pressed.connect(pedir_soltar.bind(indice_deposito))
		topo.add_child(botao_soltar)
	linha.add_child(topo)
	var detalhe := Label.new()
	detalhe.name = "Detalhe"
	detalhe.text = texto_detalhe(instancia)
	detalhe.add_theme_font_size_override("font_size", 12)
	linha.add_child(detalhe)
	return linha


static func texto_detalhe(instancia: CreatureInstance) -> String:
	var nomes: Array[String] = []
	for ataque_id: String in instancia.ataques_conhecidos:
		var ataque := AttackRegistry.get_ataque(ataque_id)
		nomes.append(ataque.nome if ataque != null else ataque_id)
	return (
		"Vida %d/%d  Nv.%d  Ataques: %s"
		% [
			instancia.vida_atual,
			instancia.vida_maxima_efetiva(),
			instancia.nivel,
			", ".join(PackedStringArray(nomes))
		]
	)


func _criar_editores() -> void:
	var vbox: VBoxContainer = _botao_fechar.get_parent()
	_editor_apelido = HBoxContainer.new()
	_editor_apelido.name = "EditorApelido"
	_editor_apelido.visible = false
	_campo_apelido = LineEdit.new()
	_campo_apelido.name = "CampoApelido"
	_campo_apelido.max_length = TAMANHO_MAX_APELIDO
	_campo_apelido.placeholder_text = "Apelido (até %d letras)" % TAMANHO_MAX_APELIDO
	_campo_apelido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campo_apelido.text_submitted.connect(func(_t: String) -> void: confirmar_apelido())
	_editor_apelido.add_child(_campo_apelido)
	var ok := Button.new()
	ok.name = "BotaoApelidoOk"
	ok.text = "Salvar"
	ok.pressed.connect(confirmar_apelido)
	_editor_apelido.add_child(ok)
	var cancelar := Button.new()
	cancelar.text = "Cancelar"
	cancelar.pressed.connect(func() -> void: _editor_apelido.visible = false)
	_editor_apelido.add_child(cancelar)
	vbox.add_child(_editor_apelido)
	vbox.move_child(_editor_apelido, _botao_fechar.get_index())

	_confirmacao_soltar = HBoxContainer.new()
	_confirmacao_soltar.name = "ConfirmacaoSoltar"
	_confirmacao_soltar.visible = false
	var pergunta := Label.new()
	pergunta.text = "Tem certeza?"
	_confirmacao_soltar.add_child(pergunta)
	var sim := Button.new()
	sim.name = "BotaoSoltarSim"
	sim.text = "Sim, soltar"
	sim.pressed.connect(confirmar_soltar)
	_confirmacao_soltar.add_child(sim)
	var nao := Button.new()
	nao.name = "BotaoSoltarNao"
	nao.text = "Não"
	nao.pressed.connect(func() -> void: _confirmacao_soltar.visible = false)
	_confirmacao_soltar.add_child(nao)
	vbox.add_child(_confirmacao_soltar)
	vbox.move_child(_confirmacao_soltar, _botao_fechar.get_index())


func pedir_apelido(instancia: CreatureInstance) -> void:
	_alvo_apelido = instancia
	_confirmacao_soltar.visible = false
	_campo_apelido.text = instancia.apelido
	_editor_apelido.visible = true
	_campo_apelido.grab_focus()


func confirmar_apelido() -> void:
	if _alvo_apelido == null:
		return
	## Vazio volta ao nome da espécie.
	_alvo_apelido.apelido = _campo_apelido.text.strip_edges().left(TAMANHO_MAX_APELIDO)
	_alvo_apelido = null
	_editor_apelido.visible = false
	_atualizar()


func pedir_soltar(indice_deposito: int) -> void:
	if indice_deposito < 0 or indice_deposito >= GameState.deposito_cubelins.size():
		return
	_indice_soltar = indice_deposito
	_editor_apelido.visible = false
	_confirmacao_soltar.visible = true


func confirmar_soltar() -> void:
	if _indice_soltar >= 0 and _indice_soltar < GameState.deposito_cubelins.size():
		## Só o depósito solta Cubelin: a equipe nunca fica vazia por acidente.
		GameState.deposito_cubelins.remove_at(_indice_soltar)
	_indice_soltar = -1
	_confirmacao_soltar.visible = false
	_atualizar()
