class_name LaboratorioScreen
extends CanvasLayer
## Laboratório da Professora Lina (F9): gerencia GameState.deposito_cubelins
## e GameState.equipe_cubelins. Abre via EventBus.laboratorio_requested.
## Ver docs/01-GDD.md §12 e docs/07-DECISOES.md ADR-022.

var _aberto: bool = false

@onready var _grid_equipe: VBoxContainer = $Control/Painel/Margem/VBox/GridEquipe
@onready var _grid_deposito: VBoxContainer = $Control/Painel/Margem/VBox/GridDeposito
@onready var _botao_fechar: Button = $Control/Painel/Margem/VBox/BotaoFechar


func _ready() -> void:
	visible = false
	_botao_fechar.pressed.connect(_fechar)
	EventBus.laboratorio_requested.connect(_abrir)


func _abrir() -> void:
	_aberto = true
	visible = true
	GameState.mudar_estado(GameState.State.PAUSED)
	_atualizar()


func _fechar() -> void:
	_aberto = false
	visible = false
	GameState.mudar_estado(GameState.State.PLAYING)


func _ao_clicar_equipe(indice: int) -> void:
	if indice < 0 or indice >= GameState.equipe_cubelins.size():
		return
	var instancia: CreatureInstance = GameState.equipe_cubelins[indice]
	GameState.equipe_cubelins.remove_at(indice)
	GameState.deposito_cubelins.append(instancia)
	_atualizar()


func _ao_clicar_deposito(indice: int) -> void:
	if indice < 0 or indice >= GameState.deposito_cubelins.size():
		return
	if GameState.equipe_cubelins.size() >= GameState.MAX_EQUIPE:
		return
	var instancia: CreatureInstance = GameState.deposito_cubelins[indice]
	GameState.deposito_cubelins.remove_at(indice)
	GameState.equipe_cubelins.append(instancia)
	_atualizar()


func _atualizar() -> void:
	for filho in _grid_equipe.get_children():
		filho.queue_free()
	for i in range(GameState.equipe_cubelins.size()):
		var instancia: CreatureInstance = GameState.equipe_cubelins[i]
		var botao := Button.new()
		botao.text = "%s Nv.%d (equipe)" % [instancia.especie_def().nome, instancia.nivel]
		botao.pressed.connect(_ao_clicar_equipe.bind(i))
		_grid_equipe.add_child(botao)

	for i in range(GameState.deposito_cubelins.size()):
		var instancia: CreatureInstance = GameState.deposito_cubelins[i]
		var botao := Button.new()
		botao.text = "%s Nv.%d (depósito)" % [instancia.especie_def().nome, instancia.nivel]
		botao.disabled = GameState.equipe_cubelins.size() >= GameState.MAX_EQUIPE
		botao.pressed.connect(_ao_clicar_deposito.bind(i))
		_grid_deposito.add_child(botao)
