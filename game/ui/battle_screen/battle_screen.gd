class_name BattleScreen
extends CanvasLayer
## Tela de batalha por turnos 1x1 (F8). Abre via EventBus.battle_started.
## Ver docs/01-GDD.md §11 e docs/07-DECISOES.md ADR-021.
##
## Ordem de turno (quem_age_primeiro) só se aplica ao Atacar — trocar/item/
## fugir são resolvidos antes do contra-ataque selvagem, exceto quando bem
## sucedidos (troca sempre gasta o turno; captura/fuga bem sucedidas encerram
## a batalha antes do selvagem agir).

const VARIACAO_MIN: float = 0.9
const VARIACAO_MAX: float = 1.1
const NIVEL_SELVAGEM_PADRAO: int = 5

var _batalha: BattleService
var _criatura_mundo: Creature
var _aberto: bool = false
var _botoes_ataque: Array[Button] = []

@onready var _label_jogador: Label = $Control/Painel/Margem/VBox/LabelJogador
@onready var _label_selvagem: Label = $Control/Painel/Margem/VBox/LabelSelvagem
@onready var _label_status: Label = $Control/Painel/Margem/VBox/LabelStatus
@onready var _grid_ataques: VBoxContainer = $Control/Painel/Margem/VBox/GridAtaques
@onready var _botao_trocar: Button = $Control/Painel/Margem/VBox/Acoes/BotaoTrocar
@onready var _botao_pocao: Button = $Control/Painel/Margem/VBox/Acoes/BotaoPocao
@onready var _botao_cubo: Button = $Control/Painel/Margem/VBox/Acoes/BotaoCubo
@onready var _botao_fugir: Button = $Control/Painel/Margem/VBox/Acoes/BotaoFugir
@onready var _botao_fechar: Button = $Control/Painel/Margem/VBox/BotaoFechar


func _ready() -> void:
	visible = false
	for i in range(4):
		var botao := Button.new()
		botao.pressed.connect(_ao_atacar.bind(i))
		_grid_ataques.add_child(botao)
		_botoes_ataque.append(botao)

	_botao_trocar.pressed.connect(_ao_trocar)
	_botao_pocao.pressed.connect(_ao_usar_pocao)
	_botao_cubo.pressed.connect(_ao_usar_cubo)
	_botao_fugir.pressed.connect(_ao_fugir)
	_botao_fechar.pressed.connect(_fechar)

	EventBus.battle_started.connect(_abrir)


func _abrir(criatura: Creature) -> void:
	_criatura_mundo = criatura
	var selvagem := CreatureInstance.new(criatura.especie.especie_id, NIVEL_SELVAGEM_PADRAO)
	_batalha = BattleService.new(GameState.equipe_cubelins, selvagem)
	_aberto = true
	visible = true
	GameState.mudar_estado(GameState.State.PAUSED)
	_atualizar()


func _fechar() -> void:
	_aberto = false
	visible = false
	_batalha = null
	_criatura_mundo = null
	GameState.mudar_estado(GameState.State.PLAYING)
	EventBus.battle_ended.emit()


func _pode_agir() -> bool:
	if _batalha == null or _batalha.resultado != BattleService.Resultado.EM_ANDAMENTO:
		return false
	var jogador := _batalha.jogador_ativo()
	return jogador != null and not jogador.esta_desmaiado()


func _ao_atacar(indice_ataque: int) -> void:
	if not _pode_agir():
		return
	var conhecidos := _batalha.jogador_ativo().ataques_conhecidos
	if indice_ataque >= conhecidos.size():
		return
	var ataque_id: String = conhecidos[indice_ataque]
	_resolver_turno_com_ataque(ataque_id)
	_atualizar()


func _resolver_turno_com_ataque(ataque_id: String) -> void:
	if _batalha.quem_age_primeiro() == "jogador":
		_batalha.jogador_ataca(ataque_id, randf_range(VARIACAO_MIN, VARIACAO_MAX))
		if _batalha.resultado == BattleService.Resultado.EM_ANDAMENTO:
			_ataque_selvagem_aleatorio()
	else:
		_ataque_selvagem_aleatorio()
		if _batalha.resultado == BattleService.Resultado.EM_ANDAMENTO:
			_batalha.jogador_ataca(ataque_id, randf_range(VARIACAO_MIN, VARIACAO_MAX))


func _ataque_selvagem_aleatorio() -> void:
	var conhecidos := _batalha.selvagem.ataques_conhecidos
	if conhecidos.is_empty():
		return
	var ataque_id: String = conhecidos[randi() % conhecidos.size()]
	_batalha.selvagem_ataca(ataque_id, randf_range(VARIACAO_MIN, VARIACAO_MAX))


func _proximo_indice_disponivel() -> int:
	for i in range(_batalha.equipe.size()):
		if i != _batalha.indice_ativo and not _batalha.equipe[i].esta_desmaiado():
			return i
	return -1


func _ao_trocar() -> void:
	if _batalha == null or _batalha.resultado != BattleService.Resultado.EM_ANDAMENTO:
		return
	var proximo := _proximo_indice_disponivel()
	if proximo == -1:
		return
	_batalha.trocar_ativo(proximo)
	if _batalha.resultado == BattleService.Resultado.EM_ANDAMENTO:
		_ataque_selvagem_aleatorio()
	_atualizar()


func _contar_item(item_id: String) -> int:
	return (
		GameState.inventario_hotbar.contar(item_id) + GameState.inventario_mochila.contar(item_id)
	)


func _consumir_item(item_id: String) -> bool:
	if GameState.inventario_hotbar.remover(item_id, 1):
		return true
	return GameState.inventario_mochila.remover(item_id, 1)


func _ao_usar_pocao() -> void:
	if not _pode_agir():
		return
	if not _consumir_item("pocao_cura"):
		return
	var def := ItemRegistry.get_item("pocao_cura")
	_batalha.usar_pocao(_batalha.jogador_ativo(), def.cura_pontos)
	if _batalha.resultado == BattleService.Resultado.EM_ANDAMENTO:
		_ataque_selvagem_aleatorio()
	_atualizar()


func _ao_usar_cubo() -> void:
	_usar_cubo_com_sorteio(randf())


func _usar_cubo_com_sorteio(sorteio: float) -> void:
	if not _pode_agir():
		return
	if not _consumir_item("cubo_captura"):
		return
	var sucesso := CaptureService.tentar_capturar(_batalha.selvagem, 1, sorteio)
	if sucesso:
		_batalha.capturar()
		GameState.adicionar_cubelin(_batalha.selvagem)
		EventBus.creature_captured.emit(_batalha.selvagem.especie_id)
		if _criatura_mundo != null:
			_criatura_mundo.queue_free()
	elif _batalha.resultado == BattleService.Resultado.EM_ANDAMENTO:
		_ataque_selvagem_aleatorio()
	_atualizar()


func _ao_fugir() -> void:
	_fugir_com_sorteio(randf())


func _fugir_com_sorteio(sorteio: float) -> void:
	if not _pode_agir():
		return
	var sucesso := _batalha.tentar_fugir(sorteio)
	if not sucesso:
		_ataque_selvagem_aleatorio()
	_atualizar()


func _process(_delta: float) -> void:
	if visible:
		_atualizar()


func _atualizar() -> void:
	if _batalha == null:
		return

	var jogador := _batalha.jogador_ativo()
	var pode_agir := _pode_agir()

	if jogador != null:
		_label_jogador.text = (
			"%s Nv.%d — HP %d/%d"
			% [
				jogador.especie_def().nome,
				jogador.nivel,
				jogador.vida_atual,
				jogador.vida_maxima_efetiva()
			]
		)
	var selvagem := _batalha.selvagem
	_label_selvagem.text = (
		"%s selvagem — HP %d/%d"
		% [selvagem.especie_def().nome, selvagem.vida_atual, selvagem.vida_maxima_efetiva()]
	)

	for i in range(4):
		var botao: Button = _botoes_ataque[i]
		if jogador != null and i < jogador.ataques_conhecidos.size():
			var ataque := AttackRegistry.get_ataque(jogador.ataques_conhecidos[i])
			botao.text = ataque.nome
			botao.visible = true
			botao.disabled = not pode_agir
		else:
			botao.visible = false

	var em_andamento := _batalha.resultado == BattleService.Resultado.EM_ANDAMENTO
	_botao_trocar.disabled = not em_andamento or _proximo_indice_disponivel() == -1
	_botao_pocao.disabled = not pode_agir or _contar_item("pocao_cura") <= 0
	_botao_cubo.disabled = not pode_agir or _contar_item("cubo_captura") <= 0
	_botao_fugir.disabled = not pode_agir

	_botao_fechar.visible = not em_andamento
	_label_status.text = _texto_resultado()

	if _batalha.resultado == BattleService.Resultado.VITORIA and _criatura_mundo != null:
		if is_instance_valid(_criatura_mundo):
			_criatura_mundo.queue_free()
		_criatura_mundo = null


func _texto_resultado() -> String:
	match _batalha.resultado:
		BattleService.Resultado.VITORIA:
			return "Vitória!"
		BattleService.Resultado.DERROTA:
			return "Seus Cubelins desmaiaram..."
		BattleService.Resultado.FUGIU:
			return "Fugiu da batalha."
		BattleService.Resultado.CAPTUROU:
			return "Cubelin capturado!"
		_:
			return ""
