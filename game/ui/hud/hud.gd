class_name Hud
extends CanvasLayer
## HUD sempre visível: hotbar refletindo GameState.inventario_hotbar.
## Ver docs/02-ARQUITETURA.md §4.13.

const TAMANHO_SLOT := Vector2(44, 44)

var _botoes: Array[Button] = []
var _chunk_manager: ChunkManager

@onready var _hotbar: HBoxContainer = $Control/HotbarContainer
@onready var _barra_vida: ProgressBar = $Control/BarraVida
@onready var _label_carregando: Label = $Control/LabelCarregando


func _ready() -> void:
	for i in range(8):
		var botao := Button.new()
		botao.custom_minimum_size = TAMANHO_SLOT
		botao.focus_mode = Control.FOCUS_NONE
		_hotbar.add_child(botao)
		_botoes.append(botao)


func _process(_delta: float) -> void:
	visible = GameState.current_state != GameState.State.CHARACTER_CREATION
	if not visible:
		return
	_atualizar_label_carregando()
	for i in range(8):
		_atualizar_slot(i)
	_barra_vida.max_value = GameState.vida_maxima
	_barra_vida.value = GameState.vida_atual


func _atualizar_label_carregando() -> void:
	## Sem isso, o mundo gerando aos poucos (meshing time-sliced, ADR-014)
	## parece o jogo travado — o personagem fica parado até o sinal
	## mundo_gerado, sem nenhum aviso na tela (achado real do usuário na v1.0).
	if _chunk_manager == null:
		_chunk_manager = get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	_label_carregando.visible = _chunk_manager != null and _chunk_manager.tem_chunks_pendentes()


func _atualizar_slot(indice: int) -> void:
	var botao: Button = _botoes[indice]
	var item_id: String = GameState.inventario_hotbar.get_item_id(indice)
	var estilo := StyleBoxFlat.new()

	if item_id == "":
		estilo.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	else:
		var def := ItemRegistry.get_item(item_id)
		estilo.bg_color = def.cor if def != null else Color.MAGENTA

	if indice == GameState.hotbar_selecionado:
		estilo.border_width_left = 3
		estilo.border_width_right = 3
		estilo.border_width_top = 3
		estilo.border_width_bottom = 3
		estilo.border_color = Color.WHITE

	botao.add_theme_stylebox_override("normal", estilo)
	var quantidade: int = GameState.inventario_hotbar.get_quantidade(indice)
	botao.text = str(quantidade) if quantidade > 0 else ""
