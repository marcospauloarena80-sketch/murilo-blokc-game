class_name Hud
extends CanvasLayer
## HUD sempre visível: hotbar refletindo GameState.inventario_hotbar, objetivo
## atual e avisos curtos (item coletado, missão concluída). Ver
## docs/02-ARQUITETURA.md §4.13. Objetivo e avisos entraram no ADR-027: jogando
## o build real, o jogador não tinha como saber o que fazer nem o que aconteceu.

const TAMANHO_SLOT := Vector2(44, 44)
const COR_SLOT_VAZIO := Color(0.15, 0.15, 0.15, 0.6)
const DURACAO_AVISO_SEG: float = 3.0
const DURACAO_AVISO_IMPORTANTE_SEG: float = 5.0
## Dica de tecla mostrada ao lado do nome do alvo sob a mira (Ciclo 5, 5E).
const DICA_POR_TIPO: Dictionary = {"npc": "E falar", "criatura": "E desafiar", "bloco": "Q quebrar"}

var _botoes: Array[Button] = []
## Ícone + quantidade de cada slot (Ciclo 6, 6B); antes o slot era um botão
## pintado com a cor do item e o número como texto.
var _slots: Array[SlotItem] = []
## Um par (normal, selecionado) por slot, criado uma vez: antes, _process criava
## um StyleBoxFlat novo para os 8 slots em todo quadro.
var _estilos_normal: Array[StyleBoxFlat] = []
var _estilos_selecionado: Array[StyleBoxFlat] = []
var _ultimo_selecionado: Array[bool] = []
var _chunk_manager: ChunkManager
var _label_objetivo: Label
var _label_aviso: Label
var _label_alvo: Label
var _jogador: Player
var _tempo_aviso: float = 0.0
var _aviso_importante: bool = false

@onready var _hotbar: HBoxContainer = $Control/HotbarContainer
@onready var _barra_vida: ProgressBar = $Control/BarraVida
@onready var _label_carregando: Label = $Control/LabelCarregando
@onready var _mira: Label = $Control/Mira


func _ready() -> void:
	for i in range(8):
		var botao := Button.new()
		botao.custom_minimum_size = TAMANHO_SLOT
		botao.focus_mode = Control.FOCUS_NONE
		_hotbar.add_child(botao)
		_botoes.append(botao)
		_slots.append(SlotItem.decorar(botao))

		var normal := StyleBoxFlat.new()
		normal.bg_color = COR_SLOT_VAZIO
		var selecionado := StyleBoxFlat.new()
		selecionado.bg_color = COR_SLOT_VAZIO
		selecionado.set_border_width_all(3)
		selecionado.border_color = Color.WHITE
		botao.add_theme_stylebox_override("normal", normal)
		_estilos_normal.append(normal)
		_estilos_selecionado.append(selecionado)
		_ultimo_selecionado.append(false)

	_label_objetivo = _criar_label(18)
	_label_objetivo.position = Vector2(16, 14)
	_label_aviso = _criar_label(24)
	_label_aviso.set_anchors_preset(Control.PRESET_CENTER_TOP)
	## set_anchors_preset preserva a posição atual (x=0) recalculando os offsets;
	## zerando-os o label fica centrado e cresce para os dois lados a partir do
	## meio da tela. Antes, metade do texto ficava fora da borda esquerda.
	_label_aviso.offset_left = 0
	_label_aviso.offset_right = 0
	_label_aviso.offset_top = 110
	_label_aviso.offset_bottom = 110
	_label_aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_aviso.visible = false
	## Nome do alvo logo abaixo da mira "+", centrado como o aviso.
	_label_alvo = _criar_label(16)
	_label_alvo.set_anchors_preset(Control.PRESET_CENTER)
	_label_alvo.offset_left = 0
	_label_alvo.offset_right = 0
	_label_alvo.offset_top = 28
	_label_alvo.offset_bottom = 28
	_label_alvo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label_alvo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_alvo.visible = false
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
	## A mira só faz sentido jogando; pausado ela ficava por cima dos menus.
	_mira.visible = GameState.current_state == GameState.State.PLAYING
	_atualizar_label_alvo()
	_label_objetivo.text = texto_objetivo()
	## O aviso só conta tempo jogando: concluído dentro da batalha ou do
	## inventário, ele espera a tela fechar pra ser lido (senão expirava coberto).
	if _tempo_aviso > 0.0 and GameState.current_state == GameState.State.PLAYING:
		_tempo_aviso -= delta
		_label_aviso.visible = _tempo_aviso > 0.0
	for i in range(8):
		_atualizar_slot(i)
	_barra_vida.max_value = GameState.vida_maxima
	_barra_vida.value = GameState.vida_atual


func _atualizar_label_alvo() -> void:
	## Nome do que está sob a mira com a dica de tecla (Ciclo 5, 5E), lido do
	## jogador (grupo "player"), que o atualiza junto com o raio da mira. Só
	## aparece com a mira: fora de PLAYING ficaria por cima dos menus.
	if not is_instance_valid(_jogador):
		_jogador = get_tree().get_first_node_in_group("player") as Player
	var texto := ""
	if _mira.visible and _jogador != null and _jogador.alvo_mirado != "":
		var dica: String = DICA_POR_TIPO.get(_jogador.alvo_tipo, "")
		texto = _jogador.alvo_mirado if dica == "" else "%s  %s" % [_jogador.alvo_mirado, dica]
	_label_alvo.text = texto
	_label_alvo.visible = texto != ""


func _atualizar_label_carregando() -> void:
	## Aviso só enquanto a área em volta do jogador carrega (o personagem fica
	## parado até area_inicial_pronta); o resto do mundo carrega em segundo
	## plano sem aviso (ADR-026).
	if _chunk_manager == null:
		_chunk_manager = get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	_label_carregando.visible = _chunk_manager != null and not _chunk_manager.area_pronta


func _atualizar_slot(indice: int) -> void:
	var botao: Button = _botoes[indice]
	var selecionado: bool = indice == GameState.hotbar_selecionado

	_slots[indice].mostrar(
		GameState.inventario_hotbar.get_item_id(indice),
		GameState.inventario_hotbar.get_quantidade(indice)
	)

	if selecionado != _ultimo_selecionado[indice]:
		var estilo: StyleBoxFlat = (
			_estilos_selecionado[indice] if selecionado else _estilos_normal[indice]
		)
		botao.add_theme_stylebox_override("normal", estilo)
		_ultimo_selecionado[indice] = selecionado
