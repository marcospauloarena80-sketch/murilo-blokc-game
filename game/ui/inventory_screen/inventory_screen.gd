class_name InventoryScreen
extends CanvasLayer
## Tela de mochila + craft. Toggle pela ação "inventario". Pausa o jogo
## (reaproveita GameState.PAUSED) enquanto aberta. Ver docs/02-ARQUITETURA.md §4.5.

const LADO_ICONE_RECEITA: int = 20

var _botoes_mochila: Array[Button] = []
var _slots_mochila: Array[SlotItem] = []
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
		_slots_mochila.append(SlotItem.decorar(botao))

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
	GameState.abrir_tela("inventario")
	_atualizar()


func _fechar() -> void:
	_aberto = false
	visible = false
	GameState.fechar_tela("inventario")


func _ao_clicar_slot_mochila(indice: int) -> void:
	GameState.mover_para_hotbar(indice)
	_atualizar()


func _criar_linha_receita(receita: RecipeDef) -> void:
	## "[ícone] Nome   3x [ícone] 2x [ícone]   Craftar" — o botão é sempre o
	## último filho (ver _atualizar).
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	linha.add_child(SlotItem.icone_solto(receita.resultado_id, LADO_ICONE_RECEITA))
	var rotulo := Label.new()
	rotulo.custom_minimum_size = Vector2(150, 0)
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rotulo.text = receita.nome
	linha.add_child(rotulo)
	for ingrediente_id: String in receita.ingredientes:
		var quantidade := Label.new()
		quantidade.text = "%dx" % int(receita.ingredientes[ingrediente_id])
		linha.add_child(quantidade)
		linha.add_child(SlotItem.icone_solto(ingrediente_id, LADO_ICONE_RECEITA))
	var botao := Button.new()
	botao.text = "Craftar"
	botao.pressed.connect(_ao_craftar.bind(receita))
	linha.add_child(botao)
	_lista_receitas.add_child(linha)


func _receita_desbloqueada(receita: RecipeDef) -> bool:
	var quest_ok := (
		receita.requer_quest == "" or GameState.quests_concluidas.has(receita.requer_quest)
	)
	var insignia_ok := (
		receita.requer_insignia == "" or GameState.tem_insignia(receita.requer_insignia)
	)
	return quest_ok and insignia_ok


func _ao_craftar(receita: RecipeDef) -> void:
	var sucesso := _craft_service.craftar(
		GameState.inventario_mochila,
		receita,
		GameState.tem_bancada(),
		GameState.tem_fornalha(),
		_receita_desbloqueada(receita)
	)
	if sucesso:
		EventBus.recipe_crafted.emit(receita.id)
	_atualizar()


func _process(_delta: float) -> void:
	if visible:
		_atualizar()


func _atualizar() -> void:
	for i in range(24):
		_slots_mochila[i].mostrar(
			GameState.inventario_mochila.get_item_id(i),
			GameState.inventario_mochila.get_quantidade(i)
		)

	var receitas: Array[RecipeDef] = RecipeRegistry.todas()
	for i in range(_lista_receitas.get_child_count()):
		var linha: HBoxContainer = _lista_receitas.get_child(i)
		var receita: RecipeDef = receitas[i]
		var botao_craftar: Button = linha.get_child(linha.get_child_count() - 1)
		botao_craftar.disabled = not _craft_service.pode_craftar(
			GameState.inventario_mochila,
			receita,
			GameState.tem_bancada(),
			GameState.tem_fornalha(),
			_receita_desbloqueada(receita)
		)
