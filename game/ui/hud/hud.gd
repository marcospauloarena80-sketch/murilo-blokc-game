class_name Hud
extends CanvasLayer
## HUD sempre visível: hotbar refletindo GameState.inventario_hotbar, objetivo
## atual e avisos curtos (item coletado, missão concluída). Ver
## docs/02-ARQUITETURA.md §4.13. Objetivo e avisos entraram no ADR-027: jogando
## o build real, o jogador não tinha como saber o que fazer nem o que aconteceu.
## Ciclo 6 (6C): vida em corações, fome em maçãs, energia numa barra fina,
## cartão de objetivo que pulsa ao progredir e dicas de controle nos primeiros
## segundos; tudo criado em código, sem assets de terceiros.

const TAMANHO_SLOT := Vector2(44, 44)
const COR_SLOT_VAZIO := Color(0.15, 0.15, 0.15, 0.6)
const DURACAO_AVISO_SEG: float = 3.0
const DURACAO_AVISO_IMPORTANTE_SEG: float = 5.0
## O aviso esmaece (modulate) nesse tempo final em vez de sumir de uma vez.
const FADE_AVISO_SEG: float = 0.3
## Dica de tecla mostrada ao lado do nome do alvo sob a mira (Ciclo 5, 5E).
const DICA_POR_TIPO: Dictionary = {"npc": "E falar", "criatura": "E desafiar", "bloco": "Q quebrar"}
## Corações e maçãs: 16 x 16 desenhados por código e mostrados em 24 x 24.
const LADO_ICONE: int = 16
const TAMANHO_ICONE := Vector2(24, 24)
const QUANTIDADE_ICONES: int = 10  ## 20 de vida/fome = 10 ícones (2 pontos cada)
## Máscaras pixel art: '#' contorno, 'o' preenchimento, 'b' brilho,
## 'c' cabinho, 'f' folha, '.' transparente. Coluna >= 8 é a metade direita.
const MASCARA_CORACAO: PackedStringArray = [
	"................",
	"..####....####..",
	".#oooo#..#oooo#.",
	"#bboooo##oooooo#",
	"#booooooooooooo#",
	"#oooooooooooooo#",
	"#oooooooooooooo#",
	".#oooooooooooo#.",
	".#oooooooooooo#.",
	"..#oooooooooo#..",
	"...#oooooooo#...",
	"....#oooooo#....",
	".....#oooo#.....",
	"......#oo#......",
	".......##.......",
	"................",
]
const MASCARA_MACA: PackedStringArray = [
	".......cc.......",
	".......ccff.....",
	"...####..####...",
	"..#bboo##oooo#..",
	".#bboooooooooo#.",
	".#booooooooooo#.",
	".#oooooooooooo#.",
	".#oooooooooooo#.",
	".#oooooooooooo#.",
	".#oooooooooooo#.",
	".#oooooooooooo#.",
	"..#oooooooooo#..",
	"..#oooooooooo#..",
	"...#ooo##ooo#...",
	"....###..###....",
	"................",
]
const COR_CORACAO := Color("e03a3a")
const COR_CORACAO_CONTORNO := Color("5a1010")
const COR_MACA := Color("f2871e")
const COR_MACA_CONTORNO := Color("7a3f10")
const COR_ICONE_VAZIO := Color("6a6a6a")
const COR_ICONE_VAZIO_CONTORNO := Color("2e2e2e")
## Paleta dos painéis (fundo escuro e borda dourada do Vale Dourado).
const COR_PAINEL := Color(0.08, 0.1, 0.16, 0.86)
const COR_BORDA_PAINEL := Color(0.95, 0.78, 0.35)
## Dicas de controle de um jogo novo: cada linha some ao usar uma das ações.
const DURACAO_DICAS_SEG: float = 25.0
const DICAS_CONTROLES: Dictionary = {
	"WASD anda": ["mover_frente", "mover_tras", "mover_esquerda", "mover_direita"],
	"Espaço pula": ["pular"],
	"E conversa/usa": ["interagir"],
	"Q quebra": ["quebrar"],
	"C coloca": ["colocar"],
	"I mochila": ["inventario"],
	"Esc pausa": ["pausar"],
}

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
var _label_aviso: Label
var _painel_aviso: PanelContainer
var _label_alvo: Label
var _jogador: Player
var _tempo_aviso: float = 0.0
var _aviso_importante: bool = false
## Vida, fome e energia (6C). As texturas ficam guardadas para comparar por
## identidade: o teste confere o coração pela textura atribuída.
var _tex_cheio: ImageTexture
var _tex_meio: ImageTexture
var _tex_vazio: ImageTexture
var _tex_maca_cheia: ImageTexture
var _tex_maca_vazia: ImageTexture
var _coracoes: Array[TextureRect] = []
var _macas: Array[TextureRect] = []
var _barra_energia: ProgressBar
var _barra_poder: ProgressBar  ## carga dos poderes de voar e acelerar (toque)
## Cartão de objetivo (6C): substitui o label solto do ADR-027.
var _cartao_objetivo: PanelContainer
var _label_titulo_cartao: Label
var _label_descricao_cartao: Label
var _barra_cartao: ProgressBar
var _ultimo_progresso_cartao: int = -1  ## -1 = sem missão mostrada
var _tween_cartao: Tween
## Dicas de controle (6C): textos ainda não dispensados, na ordem de DICAS_CONTROLES.
var _label_dicas: Label
var _dicas_pendentes: Array[String] = []

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

	## A barra antiga fica na cena (6B e 6C não editam hud.tscn), só escondida.
	_barra_vida.visible = false
	_criar_vida_fome_energia()
	_criar_cartao_objetivo()
	_criar_toast()
	_criar_dicas()
	_criar_minimapa()
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
	EventBus.aviso.connect(_mostrar_aviso.bind(false))


func _criar_label(tamanho: int, pai: Node = null) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var destino: Node = pai if pai != null else $Control
	destino.add_child(label)
	return label


func _estilo_painel() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_PAINEL
	estilo.set_corner_radius_all(12)
	estilo.set_border_width_all(2)
	estilo.border_color = COR_BORDA_PAINEL
	estilo.content_margin_left = 14
	estilo.content_margin_right = 14
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	return estilo


func _criar_painel(estilo_pai: Control.LayoutPreset) -> PanelContainer:
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", _estilo_painel())
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(painel)
	painel.set_anchors_preset(estilo_pai)
	return painel


## --- Vida, fome e energia (6C) -------------------------------------------


static func _textura_pixel_art(
	mascara: PackedStringArray, cor_esquerda: Color, cor_direita: Color, cor_contorno: Color
) -> ImageTexture:
	## Pinta a máscara 16 x 16: metade esquerda e direita podem ter cores
	## diferentes (meio coração). Cabinho e folha da maçã têm cores fixas.
	var img := Image.create(LADO_ICONE, LADO_ICONE, false, Image.FORMAT_RGBA8)
	for y: int in range(LADO_ICONE):
		for x: int in range(LADO_ICONE):
			var preenchimento: Color = cor_esquerda if x < LADO_ICONE / 2 else cor_direita
			var cor := Color.TRANSPARENT
			match mascara[y][x]:
				"#":
					cor = cor_contorno
				"o":
					cor = preenchimento
				"b":
					cor = preenchimento.lightened(0.35)
				"c":
					cor = Color("5a3a20")
				"f":
					cor = Color("4caf50")
			img.set_pixel(x, y, cor)
	return ImageTexture.create_from_image(img)


func _criar_fileira_de_icones(nome: String, esquerda: float, direita: float) -> Array[TextureRect]:
	## 10 ícones 24 x 24 numa HBoxContainer ancorada embaixo no centro, logo
	## acima da hotbar (que vai de -60 a -10). Filtro nearest mantém o pixel art.
	var caixa := HBoxContainer.new()
	caixa.name = nome
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_theme_constant_override("separation", 2)
	$Control.add_child(caixa)
	caixa.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caixa.offset_left = esquerda
	caixa.offset_right = direita
	caixa.offset_top = -92
	caixa.offset_bottom = -68
	caixa.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caixa.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var icones: Array[TextureRect] = []
	for i in range(QUANTIDADE_ICONES):
		var icone := TextureRect.new()
		icone.custom_minimum_size = TAMANHO_ICONE
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caixa.add_child(icone)
		icones.append(icone)
	return icones


func _criar_vida_fome_energia() -> void:
	_tex_cheio = _textura_pixel_art(MASCARA_CORACAO, COR_CORACAO, COR_CORACAO, COR_CORACAO_CONTORNO)
	_tex_meio = _textura_pixel_art(
		MASCARA_CORACAO, COR_CORACAO, COR_ICONE_VAZIO, COR_CORACAO_CONTORNO
	)
	_tex_vazio = _textura_pixel_art(
		MASCARA_CORACAO, COR_ICONE_VAZIO, COR_ICONE_VAZIO, COR_ICONE_VAZIO_CONTORNO
	)
	_tex_maca_cheia = _textura_pixel_art(MASCARA_MACA, COR_MACA, COR_MACA, COR_MACA_CONTORNO)
	_tex_maca_vazia = _textura_pixel_art(
		MASCARA_MACA, COR_ICONE_VAZIO, COR_ICONE_VAZIO, COR_ICONE_VAZIO_CONTORNO
	)
	## 10 x 24 + 9 x 2 = 258 px por fileira; corações à esquerda, fome à direita.
	_coracoes = _criar_fileira_de_icones("Coracoes", -266, -8)
	_macas = _criar_fileira_de_icones("Fome", 8, 266)

	## Barra fina de energia acima das fileiras; só aparece ao gastar energia.
	_barra_energia = ProgressBar.new()
	_barra_energia.name = "Energia"
	_barra_energia.show_percentage = false
	_barra_energia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0, 0, 0, 0.5)
	fundo.set_corner_radius_all(3)
	var preenchimento := StyleBoxFlat.new()
	preenchimento.bg_color = COR_BORDA_PAINEL
	preenchimento.set_corner_radius_all(3)
	_barra_energia.add_theme_stylebox_override("background", fundo)
	_barra_energia.add_theme_stylebox_override("fill", preenchimento)
	$Control.add_child(_barra_energia)
	_criar_barra_de_poder()
	_barra_energia.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_barra_energia.offset_left = -100
	_barra_energia.offset_right = 100
	_barra_energia.offset_top = -102
	_barra_energia.offset_bottom = -96
	_barra_energia.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_barra_energia.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_barra_energia.visible = false


func _atualizar_vida_fome_energia() -> void:
	## Cada ícone vale 2 pontos: vida 13 = 6 cheios, 1 meio e 3 vazios.
	var cheios: int = GameState.vida_atual / 2
	var tem_meio: bool = GameState.vida_atual % 2 == 1
	for i in range(QUANTIDADE_ICONES):
		var textura: ImageTexture = _tex_vazio
		if i < cheios:
			textura = _tex_cheio
		elif i == cheios and tem_meio:
			textura = _tex_meio
		_coracoes[i].texture = textura
	var macas_cheias: int = GameState.fome_atual / 2
	for i in range(QUANTIDADE_ICONES):
		_macas[i].texture = _tex_maca_cheia if i < macas_cheias else _tex_maca_vazia
	_barra_energia.visible = GameState.energia_atual < GameState.energia_maxima
	_barra_energia.max_value = GameState.energia_maxima
	_barra_energia.value = GameState.energia_atual


## --- Cartão de objetivo (6C) ----------------------------------------------


func _criar_cartao_objetivo() -> void:
	_cartao_objetivo = _criar_painel(Control.PRESET_TOP_LEFT)
	_cartao_objetivo.name = "CartaoObjetivo"
	_cartao_objetivo.position = Vector2(16, 14)
	var coluna := VBoxContainer.new()
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_theme_constant_override("separation", 4)
	_cartao_objetivo.add_child(coluna)
	_label_titulo_cartao = _criar_label(18, coluna)
	_label_titulo_cartao.add_theme_color_override("font_color", COR_BORDA_PAINEL)
	_label_descricao_cartao = _criar_label(14, coluna)
	_barra_cartao = ProgressBar.new()
	_barra_cartao.custom_minimum_size = Vector2(220, 10)
	_barra_cartao.show_percentage = false
	_barra_cartao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_barra_cartao)


func _atualizar_cartao_objetivo() -> void:
	## Reaproveita texto_objetivo(): "Objetivo: descrição (n/m)" ou a dica da
	## Lina sem missão; vazio quando não há nada a mostrar.
	var quest := GameState.quest_atual()
	var texto := texto_objetivo().trim_prefix("Objetivo: ")
	_cartao_objetivo.visible = texto != ""
	_label_titulo_cartao.text = quest.nome if quest != null else "Objetivo"
	_label_descricao_cartao.text = texto
	_barra_cartao.visible = quest != null
	var feito := -1
	if quest != null:
		feito = mini(GameState.progresso_quest_atual, quest.quantidade_alvo)
		_barra_cartao.max_value = quest.quantidade_alvo
		_barra_cartao.value = feito
	if feito >= 0 and _ultimo_progresso_cartao >= 0 and feito != _ultimo_progresso_cartao:
		_pulsar_cartao()
	_ultimo_progresso_cartao = feito


func _pulsar_cartao() -> void:
	## Escala 1,0 -> 1,06 -> 1,0 em 0,4 s a partir do centro do cartão.
	if _tween_cartao != null and _tween_cartao.is_valid():
		_tween_cartao.kill()
	_cartao_objetivo.pivot_offset = _cartao_objetivo.size / 2.0
	_tween_cartao = create_tween()
	_tween_cartao.tween_property(_cartao_objetivo, "scale", Vector2(1.06, 1.06), 0.2)
	_tween_cartao.tween_property(_cartao_objetivo, "scale", Vector2.ONE, 0.2)


## --- Toast e dicas (6C) ----------------------------------------------------


func _criar_toast() -> void:
	## Painel centrado no topo que cresce para os dois lados a partir do meio
	## da tela (offsets zerados; antes metade do texto saía pela borda esquerda).
	_painel_aviso = _criar_painel(Control.PRESET_CENTER_TOP)
	_painel_aviso.name = "Aviso"
	_painel_aviso.offset_left = 0
	_painel_aviso.offset_right = 0
	_painel_aviso.offset_top = 110
	_painel_aviso.offset_bottom = 110
	_painel_aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_painel_aviso.visible = false
	_label_aviso = _criar_label(24, _painel_aviso)
	_label_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_aviso.visible = false


func _criar_minimapa() -> void:
	$Control.add_child(Minimapa.new())


func _criar_dicas() -> void:
	_dicas_pendentes.assign(DICAS_CONTROLES.keys())
	_label_dicas = _criar_label(16)
	_label_dicas.name = "Dicas"
	_label_dicas.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_label_dicas.offset_left = 16
	_label_dicas.offset_top = -16
	_label_dicas.offset_bottom = -16
	_label_dicas.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label_dicas.visible = false


func _atualizar_dicas() -> void:
	for texto: String in _dicas_pendentes.duplicate():
		for acao: String in DICAS_CONTROLES[texto]:
			if Input.is_action_just_pressed(acao):
				_dicas_pendentes.erase(texto)
				break
	var mostrar: bool = (
		GameState.current_state == GameState.State.PLAYING
		and GameState.tempo_de_jogo_seg < DURACAO_DICAS_SEG
		and not _dicas_pendentes.is_empty()
	)
	_label_dicas.visible = mostrar
	if mostrar:
		_label_dicas.text = "\n".join(PackedStringArray(_dicas_pendentes))


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
	_painel_aviso.visible = true
	_painel_aviso.modulate.a = 1.0
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
	_atualizar_barra_de_poder()
	_atualizar_cartao_objetivo()
	_atualizar_dicas()
	## O aviso só conta tempo jogando: concluído dentro da batalha ou do
	## inventário, ele espera a tela fechar pra ser lido (senão expirava coberto).
	if _tempo_aviso > 0.0 and GameState.current_state == GameState.State.PLAYING:
		_tempo_aviso -= delta
		_label_aviso.visible = _tempo_aviso > 0.0
		_painel_aviso.visible = _label_aviso.visible
		_painel_aviso.modulate.a = clampf(_tempo_aviso / FADE_AVISO_SEG, 0.0, 1.0)
	for i in range(8):
		_atualizar_slot(i)
	_atualizar_vida_fome_energia()


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
		GameState.inventario_hotbar.get_quantidade(indice),
		GameState.inventario_hotbar.fracao_durabilidade(indice)
	)

	if selecionado != _ultimo_selecionado[indice]:
		var estilo: StyleBoxFlat = (
			_estilos_selecionado[indice] if selecionado else _estilos_normal[indice]
		)
		botao.add_theme_stylebox_override("normal", estilo)
		_ultimo_selecionado[indice] = selecionado


func _criar_barra_de_poder() -> void:
	## Barra discreta acima da energia: só aparece quando os poderes gastaram ou
	## gastam carga (vazia, o poder desliga e só volta depois de recarregar).
	_barra_poder = ProgressBar.new()
	_barra_poder.name = "Poder"
	_barra_poder.show_percentage = false
	_barra_poder.min_value = 0.0
	_barra_poder.max_value = 1.0
	_barra_poder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0, 0, 0, 0.35)
	var preenchimento := StyleBoxFlat.new()
	preenchimento.bg_color = Color(0.45, 0.85, 1.0, 0.9)
	_barra_poder.add_theme_stylebox_override("background", fundo)
	_barra_poder.add_theme_stylebox_override("fill", preenchimento)
	$Control.add_child(_barra_poder)
	_barra_poder.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_barra_poder.offset_left = -60
	_barra_poder.offset_right = 60
	_barra_poder.offset_top = -111
	_barra_poder.offset_bottom = -107
	_barra_poder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_barra_poder.visible = false


func _atualizar_barra_de_poder() -> void:
	if not is_instance_valid(_jogador):
		_jogador = get_tree().get_first_node_in_group("player") as Player
	if _jogador == null:
		_barra_poder.visible = false
		return
	var poderes: Poderes = _jogador.poderes
	_barra_poder.value = poderes.carga
	_barra_poder.visible = poderes.ativo() or poderes.carga < Poderes.CARGA_MAXIMA
