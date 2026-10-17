class_name TouchControls
extends CanvasLayer
## Controles touch (F12, ADR-025): joystick flutuante (esquerda) pra
## movimento + arrasto (direita) pra olhar + botões de ação + botão de pausa.
## Joystick/arrasto só respondem a toque de verdade (tela sensível ao
## toque) — suportam os dois dedos ao mesmo tempo (mover E olhar juntos),
## por isso usam InputEventScreenTouch/Drag direto (mouse emulado só dá 1
## ponteiro). Os botões (pular/quebrar/colocar/interagir/inventário/pausa)
## são Button comuns e só ficam visíveis quando há tela de toque: no desktop
## eles cobriam o "Jogar" do criador de personagem e poluíam a tela. A ADR-026
## os deixava visíveis em qualquer plataforma porque clicar-e-segurar falhava
## no trackpad (Chrome/Mac); desde então o mapa de input ganhou as teclas Q
## (quebrar) e C (colocar), validadas jogando, que cobrem esse caso.
## Ações lidas por polling pelo Player (pular/quebrar/colocar/interagir) usam
## Input.action_press/release; as lidas por evento em _unhandled_input
## (inventario/pausar) precisam de um InputEventAction via parse_input_event,
## porque action_press não gera InputEvent.

const RAIO_JOYSTICK: float = 60.0
const SENSIBILIDADE_ARRASTO: float = 0.006

## Só pra teste: força o caminho "com tela de toque" sem depender do hardware.
var forcar_toque: bool = false

var _tem_toque: bool = false
var _indice_toque_joystick: int = -1
var _centro_joystick: Vector2 = Vector2.ZERO
var _indice_toque_olhar: int = -1
var _jogador: Node3D
var _poderes_ui: HBoxContainer  ## setas e turbo (poderes temporários)

@onready var _joystick_fundo: Control = $Joystick/Fundo
@onready var _joystick_alca: Control = $Joystick/Alca
@onready var _botao_pular: Button = $Acoes/BotaoPular
@onready var _botao_quebrar: Button = $Acoes/BotaoQuebrar
@onready var _botao_colocar: Button = $Acoes/BotaoColocar
@onready var _botao_interagir: Button = $Acoes/BotaoInteragir
@onready var _botao_inventario: Button = $Acoes/BotaoInventario
@onready var _botao_pausa: Button = $Pausa/BotaoPausa


func _ready() -> void:
	$Joystick.visible = false
	_tem_toque = _tem_tela_de_toque()
	$Acoes.visible = _tem_toque
	$Pausa.visible = _tem_toque
	## Sem foco de teclado: senão, num aparelho com toque e teclado, Espaço ou
	## Enter reativavam o último botão tocado (Bolsa/Pausa reabrindo a tela).
	for botao: Button in [
		_botao_pular,
		_botao_quebrar,
		_botao_colocar,
		_botao_interagir,
		_botao_inventario,
		_botao_pausa
	]:
		botao.focus_mode = Control.FOCUS_NONE
	_conectar_botao(_botao_pular, "pular")
	_conectar_botao(_botao_quebrar, "quebrar")
	_conectar_botao(_botao_colocar, "colocar")
	_conectar_botao(_botao_interagir, "interagir")
	_conectar_botao_por_evento(_botao_inventario, "inventario")
	_conectar_botao_por_evento(_botao_pausa, "pausar")
	_criar_botoes_de_poder()


func _tem_tela_de_toque() -> bool:
	return forcar_toque or DisplayServer.is_touchscreen_available()


func _process(_delta: float) -> void:
	## Na criação de personagem os botões cobririam o "Jogar" (eles ficam
	## acima do painel na árvore); o HUD se esconde do mesmo jeito.
	var criando := GameState.current_state == GameState.State.CHARACTER_CREATION
	$Acoes.visible = _tem_toque and not criando
	$Pausa.visible = _tem_toque and not criando
	_poderes_ui.visible = _tem_toque and not criando


func _conectar_botao(botao: Button, acao: String) -> void:
	botao.button_down.connect(Input.action_press.bind(acao, 1.0))
	botao.button_up.connect(Input.action_release.bind(acao))


func _conectar_botao_por_evento(botao: Button, acao: String) -> void:
	botao.button_down.connect(_despachar_acao.bind(acao, true))
	botao.button_up.connect(_despachar_acao.bind(acao, false))


func _despachar_acao(acao: String, pressionado: bool) -> void:
	var evento := InputEventAction.new()
	evento.action = acao
	evento.pressed = pressionado
	evento.strength = 1.0
	Input.parse_input_event(evento)


func _garantir_jogador() -> void:
	if _jogador == null:
		_jogador = get_tree().get_first_node_in_group("player")


func _input(event: InputEvent) -> void:
	if not _tem_tela_de_toque():
		return
	if event is InputEventScreenTouch:
		_ao_tocar(event)
	elif event is InputEventScreenDrag:
		_ao_arrastar(event)


func _ao_tocar(event: InputEventScreenTouch) -> void:
	var metade_da_tela: float = get_viewport().get_visible_rect().size.x / 2.0
	if event.pressed:
		if event.position.x < metade_da_tela and _indice_toque_joystick == -1:
			_indice_toque_joystick = event.index
			_centro_joystick = event.position
			$Joystick.visible = true
			$Joystick.position = _centro_joystick
			_joystick_alca.position = -_joystick_alca.size / 2.0
		elif event.position.x >= metade_da_tela and _indice_toque_olhar == -1:
			_indice_toque_olhar = event.index
	else:
		if event.index == _indice_toque_joystick:
			_indice_toque_joystick = -1
			_soltar_joystick()
		elif event.index == _indice_toque_olhar:
			_indice_toque_olhar = -1


func _ao_arrastar(event: InputEventScreenDrag) -> void:
	if event.index == _indice_toque_joystick:
		_atualizar_joystick(event.position)
	elif event.index == _indice_toque_olhar:
		_garantir_jogador()
		if _jogador != null:
			_jogador.girar_camera(event.relative.x, event.relative.y, SENSIBILIDADE_ARRASTO)


func _atualizar_joystick(posicao_toque: Vector2) -> void:
	var offset := posicao_toque - _centro_joystick
	var direcao := VirtualJoystickMath.direcao_normalizada(offset, RAIO_JOYSTICK)
	var limitado := direcao * RAIO_JOYSTICK
	_joystick_alca.position = limitado - _joystick_alca.size / 2.0
	_aplicar_forcas(direcao)


func _soltar_joystick() -> void:
	$Joystick.visible = false
	_aplicar_forcas(Vector2.ZERO)


func _aplicar_forcas(direcao: Vector2) -> void:
	var forcas := VirtualJoystickMath.forcas_dos_eixos(direcao)
	for acao: String in forcas:
		var forca: float = forcas[acao]
		if forca > 0.05:
			Input.action_press(acao, forca)
		else:
			Input.action_release(acao)


func _criar_botoes_de_poder() -> void:
	## Lado direito, no meio: seta pra cima (1 toque pula, 2 toques voa), seta pra
	## baixo (agacha; voando, pousa) e, ao lado, o turbo (acelera e volta ao normal).
	## Os poderes são temporários e gastam uma barra de carga (ver Poderes).
	_poderes_ui = HBoxContainer.new()
	_poderes_ui.name = "Poderes"
	_poderes_ui.add_theme_constant_override("separation", 10)
	_poderes_ui.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_poderes_ui.offset_left = -170.0
	_poderes_ui.offset_right = -16.0
	_poderes_ui.offset_top = -80.0
	_poderes_ui.offset_bottom = 80.0
	_poderes_ui.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_poderes_ui.visible = _tem_toque
	add_child(_poderes_ui)
	var setas := VBoxContainer.new()
	setas.add_theme_constant_override("separation", 10)
	_poderes_ui.add_child(setas)
	var cima := _novo_botao_de_poder("▲", "BotaoCima")
	var baixo := _novo_botao_de_poder("▼", "BotaoBaixo")
	var turbo := _novo_botao_de_poder("»", "BotaoTurbo")
	setas.add_child(cima)
	setas.add_child(baixo)
	_poderes_ui.add_child(turbo)
	cima.button_down.connect(_ao_apertar_cima)
	cima.button_up.connect(_ao_soltar_cima)
	baixo.button_down.connect(_ao_apertar_baixo)
	baixo.button_up.connect(Input.action_release.bind("agachar"))
	turbo.button_down.connect(_ao_apertar_turbo)


func _novo_botao_de_poder(texto: String, nome: String) -> Button:
	var botao := Button.new()
	botao.name = nome
	botao.text = texto
	botao.custom_minimum_size = Vector2(70, 70)
	botao.focus_mode = Control.FOCUS_NONE
	botao.modulate = Color(1, 1, 1, 0.85)
	return botao


func _ao_apertar_cima() -> void:
	_garantir_jogador()
	var jogador := _jogador as Player
	if jogador == null:
		return
	var agora: float = Time.get_ticks_msec() / 1000.0
	if jogador.poderes.tocar_cima(agora) == "pulo":
		Input.action_press("pular", 1.0)


func _ao_soltar_cima() -> void:
	Input.action_release("pular")
	_garantir_jogador()
	var jogador := _jogador as Player
	if jogador != null:
		jogador.poderes.soltar_cima()


func _ao_apertar_baixo() -> void:
	_garantir_jogador()
	var jogador := _jogador as Player
	if jogador != null and jogador.poderes.tocar_baixo() == "agachar":
		Input.action_press("agachar", 1.0)


func _ao_apertar_turbo() -> void:
	_garantir_jogador()
	var jogador := _jogador as Player
	if jogador != null:
		jogador.poderes.alternar_turbo()
