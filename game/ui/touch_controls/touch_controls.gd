class_name TouchControls
extends CanvasLayer
## Controles touch (F12, ADR-025): joystick flutuante (esquerda) pra
## movimento + arrasto (direita) pra olhar + botões de ação.
## Joystick/arrasto só respondem a toque de verdade (tela sensível ao
## toque) — suportam os dois dedos ao mesmo tempo (mover E olhar juntos),
## por isso usam InputEventScreenTouch/Drag direto (mouse emulado só dá 1
## ponteiro). Os botões de ação (pular/quebrar/colocar/interagir/inventário)
## são Button comuns e ficam visíveis em qualquer plataforma — mouse/trackpad
## clicam neles igual — porque clicar-e-segurar pelo teclado/mouse pode falhar
## em navegador dependendo do hardware (achado real: "quebrar" não respondia
## no Chrome/Mac com trackpad mesmo com o mapa de input correto, ADR-026).

const RAIO_JOYSTICK: float = 60.0
const SENSIBILIDADE_ARRASTO: float = 0.006

var _indice_toque_joystick: int = -1
var _centro_joystick: Vector2 = Vector2.ZERO
var _indice_toque_olhar: int = -1
var _jogador: Node3D

@onready var _joystick_fundo: Control = $Joystick/Fundo
@onready var _joystick_alca: Control = $Joystick/Alca
@onready var _botao_pular: Button = $Acoes/BotaoPular
@onready var _botao_quebrar: Button = $Acoes/BotaoQuebrar
@onready var _botao_colocar: Button = $Acoes/BotaoColocar
@onready var _botao_interagir: Button = $Acoes/BotaoInteragir
@onready var _botao_inventario: Button = $Acoes/BotaoInventario


func _ready() -> void:
	$Joystick.visible = false
	_conectar_botao(_botao_pular, "pular")
	_conectar_botao(_botao_quebrar, "quebrar")
	_conectar_botao(_botao_colocar, "colocar")
	_conectar_botao(_botao_interagir, "interagir")
	_conectar_botao(_botao_inventario, "inventario")


func _conectar_botao(botao: Button, acao: String) -> void:
	botao.button_down.connect(Input.action_press.bind(acao, 1.0))
	botao.button_up.connect(Input.action_release.bind(acao))


func _garantir_jogador() -> void:
	if _jogador == null:
		_jogador = get_tree().get_first_node_in_group("player")


func _input(event: InputEvent) -> void:
	if not DisplayServer.is_touchscreen_available():
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
