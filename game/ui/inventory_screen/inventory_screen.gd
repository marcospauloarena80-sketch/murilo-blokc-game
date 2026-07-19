class_name InventoryScreen
extends CanvasLayer
## Tela de mochila + craft. Toggle pela ação "inventario". Pausa o jogo
## (reaproveita GameState.PAUSED) enquanto aberta. Ver docs/02-ARQUITETURA.md §4.5.

var _botoes_mochila: Array[Button] = []
var _craft_service := CraftService.new()
var _aberto: bool = false

@onready var _grid_mochila: GridContainer = $Control/Painel/Margem/VBox/GridMochila
@onready var _lista_receitas: VBoxContainer = $Control/Painel/Margem/VBox/ListaReceitas
@onready var _botao_fechar: Button = $Control/Painel/Margem/VBox/BotaoFechar


func _ready() -> void:
	visible = false

	for i in range(24):
		var botao := Button.new()
		botao.custom_minimum_size = Vector2(56, 44)
		botao.pressed.connect(_ao_clicar_slot_mochila.bind(i))
		_grid_mochila.add_child(botao)
		_botoes_mochila.append(botao)

	for receita: RecipeDef in RecipeRegistry.todas():
		_criar_linha_receita(receita)

	_botao_fechar.pressed.connect(_fechar)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario"):
		if _aberto:
			_fechar()
		elif GameState.current_state == GameState.State.PLAYING:
			_abrir()


func _abrir() -> void:
	_aberto = true
	visible = true
	GameState.mudar_estado(GameState.State.PAUSED)
	_atualizar()


func _fechar() -> void:
	_aberto = false
	visible = false
	GameState.mudar_estado(GameState.State.PLAYING)


func _ao_clicar_slot_mochila(indice: int) -> void:
	GameState.mover_para_hotbar(indice)
	_atualizar()


func _criar_linha_receita(receita: RecipeDef) -> void:
	var linha := HBoxContainer.new()
	var rotulo := Label.new()
	rotulo.custom_minimum_size = Vector2(180, 0)
	rotulo.text = receita.nome
	var botao := Button.new()
	botao.text = "Craftar"
	botao.pressed.connect(_ao_craftar.bind(receita))
	linha.add_child(rotulo)
	linha.add_child(botao)
	_lista_receitas.add_child(linha)


func _ao_craftar(receita: RecipeDef) -> void:
	_craft_service.craftar(GameState.inventario_mochila, receita, GameState.tem_bancada())
	_atualizar()


func _process(_delta: float) -> void:
	if visible:
		_atualizar()


func _atualizar() -> void:
	for i in range(24):
		var botao: Button = _botoes_mochila[i]
		var item_id: String = GameState.inventario_mochila.get_item_id(i)
		if item_id == "":
			botao.text = ""
		else:
			var quantidade: int = GameState.inventario_mochila.get_quantidade(i)
			botao.text = "%s\n%d" % [item_id, quantidade]

	var receitas: Array[RecipeDef] = RecipeRegistry.todas()
	for i in range(_lista_receitas.get_child_count()):
		var linha: HBoxContainer = _lista_receitas.get_child(i)
		var receita: RecipeDef = receitas[i]
		var botao_craftar: Button = linha.get_child(1)
		botao_craftar.disabled = not _craft_service.pode_craftar(
			GameState.inventario_mochila, receita, GameState.tem_bancada()
		)
