class_name Hud
extends CanvasLayer
## HUD sempre visível: hotbar refletindo GameState.inventario_hotbar, objetivo
## atual e avisos curtos (item coletado, missão concluída). Ver
## docs/02-ARQUITETURA.md §4.13. Objetivo e avisos entraram no ADR-027: jogando
## o build real, o jogador não tinha como saber o que fazer nem o que aconteceu.

const TAMANHO_SLOT := Vector2(44, 44)
const DURACAO_AVISO_SEG: float = 3.0
const DURACAO_AVISO_IMPORTANTE_SEG: float = 5.0

var _botoes: Array[Button] = []
var _chunk_manager: ChunkManager
var _label_objetivo: Label
var _label_aviso: Label
var _tempo_aviso: float = 0.0
var _aviso_importante: bool = false

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

	_label_objetivo = _criar_label(18)
	_label_objetivo.position = Vector2(16, 14)
	_label_aviso = _criar_label(24)
	_label_aviso.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label_aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_aviso.position.y = 110
	_label_aviso.visible = false
	EventBus.item_collected.connect(_ao_coletar_item)
	EventBus.quest_completed.connect(_ao_concluir_missao)


func _criar_label(tamanho: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(label)
	return label


static func texto_objetivo() -> String:
	var quest := GameState.quest_atual()
	if quest != null:
		var feito: int = mini(GameState.progresso_quest_atual, quest.quantidade_alvo)
		return "Objetivo: %s (%d/%d)" % [quest.descricao, feito, quest.quantidade_alvo]
	if GameState.quests_concluidas.is_empty():
		return "Objetivo: fale com a Professora Lina (mire nela e aperte E)"
	return ""


func _ao_coletar_item(item_id: String, quantidade: int) -> void:
	if _aviso_importante and _tempo_aviso > 0.0:
		return
	var def := ItemRegistry.get_item(item_id)
	_mostrar_aviso("+%d %s" % [quantidade, def.nome if def != null else item_id], false)


func _ao_concluir_missao(quest_id: String) -> void:
	var quest := QuestRegistry.get_quest(quest_id)
	if quest == null:
		return
	var partes: Array[String] = ["Missão concluída: %s!" % quest.nome]
	for item_id: String in quest.recompensa_itens:
		var def := ItemRegistry.get_item(item_id)
		var nome: String = def.nome if def != null else item_id
		partes.append("+%d %s" % [int(quest.recompensa_itens[item_id]), nome])
	if quest.recompensa_cubelin != "":
		var especie := CreatureRegistry.get_creature(quest.recompensa_cubelin)
		var nome_especie: String = especie.nome if especie != null else quest.recompensa_cubelin
		partes.append("Novo Cubelin na equipe: %s!" % nome_especie)
	_mostrar_aviso("\n".join(PackedStringArray(partes)), true)


func _mostrar_aviso(texto: String, importante: bool) -> void:
	_label_aviso.text = texto
	_label_aviso.visible = true
	_aviso_importante = importante
	_tempo_aviso = DURACAO_AVISO_IMPORTANTE_SEG if importante else DURACAO_AVISO_SEG


func _process(delta: float) -> void:
	visible = GameState.current_state != GameState.State.CHARACTER_CREATION
	if not visible:
		return
	_atualizar_label_carregando()
	_label_objetivo.text = texto_objetivo()
	if _tempo_aviso > 0.0:
		_tempo_aviso -= delta
		_label_aviso.visible = _tempo_aviso > 0.0
	for i in range(8):
		_atualizar_slot(i)
	_barra_vida.max_value = GameState.vida_maxima
	_barra_vida.value = GameState.vida_atual


func _atualizar_label_carregando() -> void:
	## Aviso só enquanto a área em volta do jogador carrega (o personagem fica
	## parado até area_inicial_pronta); o resto do mundo carrega em segundo
	## plano sem aviso (ADR-026).
	if _chunk_manager == null:
		_chunk_manager = get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	_label_carregando.visible = _chunk_manager != null and not _chunk_manager.area_pronta


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
