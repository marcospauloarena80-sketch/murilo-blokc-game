class_name CadernoScreen
extends CanvasLayer
## Caderno de Cubelins (Ciclo 9, 9D): grade das 18 formas. Não vista = silhueta
## cinza; vista = cor e nome; capturada ganha o selo "Capturado". Tecla J
## (ação "caderno") ou botão no diálogo da Lina. Entra na pilha como "caderno".

const COR_SILHUETA: Color = Color(0.35, 0.35, 0.38)
const COLUNAS: int = 6

var _aberto: bool = false
var _botoes: Dictionary = {}  ## especie_id -> Button

@onready var _grade: GridContainer = $Control/Painel/Margem/VBox/Grade
@onready var _detalhe: Label = $Control/Painel/Margem/VBox/Detalhe
@onready var _botao_fechar: Button = $Control/Painel/Margem/VBox/BotaoFechar


func _ready() -> void:
	visible = false
	_grade.columns = COLUNAS
	_botao_fechar.pressed.connect(_fechar)
	EventBus.caderno_requested.connect(_abrir)
	for especie_id: String in CreatureRegistry.todos_os_ids():
		var botao := Button.new()
		botao.name = especie_id
		botao.custom_minimum_size = Vector2(76, 64)
		botao.pressed.connect(selecionar.bind(especie_id))
		_grade.add_child(botao)
		_botoes[especie_id] = botao


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("caderno"):
		if _aberto:
			_fechar()
		elif GameState.current_state == GameState.State.PLAYING:
			_abrir()


func _abrir() -> void:
	_aberto = true
	visible = true
	GameState.abrir_tela("caderno")
	_atualizar()
	_detalhe.text = "Escolha um Cubelin para ver os detalhes."


func _fechar() -> void:
	_aberto = false
	visible = false
	GameState.fechar_tela("caderno")


func _atualizar() -> void:
	for especie_id: String in _botoes:
		var botao: Button = _botoes[especie_id]
		var def := CreatureRegistry.get_creature(especie_id)
		if GameState.especies_vistas.has(especie_id):
			botao.text = def.nome
			if GameState.especies_capturadas.has(especie_id):
				botao.text += "\nCapturado"
			botao.modulate = def.cor.lerp(Color.WHITE, 0.35)
		else:
			botao.text = "???"
			botao.modulate = COR_SILHUETA


func selecionar(especie_id: String) -> void:
	_detalhe.text = texto_detalhe(especie_id)


static func texto_detalhe(especie_id: String) -> String:
	var def := CreatureRegistry.get_creature(especie_id)
	if def == null or not GameState.especies_vistas.has(especie_id):
		return "Ainda não visto."
	var linhas: Array[String] = [def.nome, "Elemento: %s" % def.elemento, def.descricao]
	if def.especie_evolucao != "":
		var proxima := CreatureRegistry.get_creature(def.especie_evolucao)
		var nome_proxima: String = proxima.nome if proxima != null else def.especie_evolucao
		linhas.append("Evolui para %s no nível %d." % [nome_proxima, def.nivel_evolucao])
	else:
		linhas.append("Não evolui mais.")
	if GameState.especies_capturadas.has(especie_id):
		linhas.append("Capturado")
	return "\n".join(PackedStringArray(linhas))
