class_name ChestScreen
extends CanvasLayer
## Tela de baú: grid do baú + grid da mochila lado a lado, clique move o
## stack inteiro pro outro lado. Abre via EventBus.chest_requested (F6).
## Ver docs/02-ARQUITETURA.md §4.5 e docs/07-DECISOES.md ADR-018.

var _botoes_bau: Array[Button] = []
var _botoes_mochila: Array[Button] = []
var _aberto: bool = false
var _chave_bau: String = ""

@onready var _grid_bau: GridContainer = $Control/Painel/Margem/VBox/GridBau
@onready var _grid_mochila: GridContainer = $Control/Painel/Margem/VBox/GridMochila
@onready var _botao_fechar: Button = $Control/Painel/Margem/VBox/BotaoFechar


func _ready() -> void:
	visible = false

	for i in range(24):
		var botao_bau := Button.new()
		botao_bau.custom_minimum_size = Vector2(56, 44)
		botao_bau.pressed.connect(_ao_clicar_bau.bind(i))
		_grid_bau.add_child(botao_bau)
		_botoes_bau.append(botao_bau)

		var botao_mochila := Button.new()
		botao_mochila.custom_minimum_size = Vector2(56, 44)
		botao_mochila.pressed.connect(_ao_clicar_mochila.bind(i))
		_grid_mochila.add_child(botao_mochila)
		_botoes_mochila.append(botao_mochila)

	_botao_fechar.pressed.connect(_fechar)
	EventBus.chest_requested.connect(_abrir)


func _abrir(chave: String) -> void:
	_chave_bau = chave
	_aberto = true
	visible = true
	GameState.mudar_estado(GameState.State.PAUSED)
	_atualizar()


func _fechar() -> void:
	_aberto = false
	visible = false
	_chave_bau = ""
	GameState.mudar_estado(GameState.State.PLAYING)


func _ao_clicar_bau(indice: int) -> void:
	_mover_stack(GameState.obter_bau(_chave_bau), GameState.inventario_mochila, indice)
	_atualizar()


func _ao_clicar_mochila(indice: int) -> void:
	_mover_stack(GameState.inventario_mochila, GameState.obter_bau(_chave_bau), indice)
	_atualizar()


func _mover_stack(origem: InventoryModel, destino: InventoryModel, indice: int) -> void:
	var item_id: String = origem.get_item_id(indice)
	if item_id == "":
		return
	var quantidade: int = origem.get_quantidade(indice)
	var sobra: int = destino.adicionar(item_id, quantidade)
	var movido: int = quantidade - sobra
	if movido > 0:
		origem.remover(item_id, movido)


func _process(_delta: float) -> void:
	if visible:
		_atualizar()


func _atualizar() -> void:
	if _chave_bau == "":
		return
	_preencher_grid(_botoes_bau, GameState.obter_bau(_chave_bau))
	_preencher_grid(_botoes_mochila, GameState.inventario_mochila)


func _preencher_grid(botoes: Array[Button], inventario: InventoryModel) -> void:
	for i in range(24):
		var botao: Button = botoes[i]
		var item_id: String = inventario.get_item_id(i)
		if item_id == "":
			botao.text = ""
		else:
			botao.text = "%s\n%d" % [item_id, inventario.get_quantidade(i)]
