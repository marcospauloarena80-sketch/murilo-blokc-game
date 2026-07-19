class_name DialogueScreen
extends CanvasLayer
## Tela de diálogo (F9): linhas sequenciais + escolha ocasional de aceitar/
## recusar missão. Abre via EventBus.dialogue_started. Ver docs/01-GDD.md §12
## e docs/07-DECISOES.md ADR-022.

var _npc_def: NpcDef
var _indice_linha: int = 0
var _aberto: bool = false

@onready var _label_nome: Label = $Control/Painel/Margem/VBox/LabelNome
@onready var _label_texto: Label = $Control/Painel/Margem/VBox/LabelTexto
@onready var _botao_avancar: Button = $Control/Painel/Margem/VBox/Acoes/BotaoAvancar
@onready var _botao_aceitar: Button = $Control/Painel/Margem/VBox/Acoes/BotaoAceitar
@onready var _botao_recusar: Button = $Control/Painel/Margem/VBox/Acoes/BotaoRecusar
@onready var _botao_laboratorio: Button = $Control/Painel/Margem/VBox/Acoes/BotaoLaboratorio
@onready var _botao_trocar: Button = $Control/Painel/Margem/VBox/Acoes/BotaoTrocar
@onready var _botao_desafiar: Button = $Control/Painel/Margem/VBox/Acoes/BotaoDesafiar
@onready var _botao_fechar: Button = $Control/Painel/Margem/VBox/Acoes/BotaoFechar


func _ready() -> void:
	visible = false
	_botao_avancar.pressed.connect(_ao_avancar)
	_botao_aceitar.pressed.connect(_ao_aceitar_quest)
	_botao_recusar.pressed.connect(_ao_recusar_quest)
	_botao_laboratorio.pressed.connect(_ao_abrir_laboratorio)
	_botao_trocar.pressed.connect(_ao_trocar)
	_botao_desafiar.pressed.connect(_ao_desafiar)
	_botao_fechar.pressed.connect(_fechar)
	EventBus.dialogue_started.connect(_abrir)


func _abrir(npc: Npc) -> void:
	_npc_def = npc.def
	_indice_linha = 0
	_aberto = true
	visible = true
	GameState.mudar_estado(GameState.State.PAUSED)
	if _npc_def.cura_ao_interagir:
		GameState.curar_no_refugio()
	_atualizar()


func _fechar() -> void:
	_aberto = false
	visible = false
	_npc_def = null
	GameState.mudar_estado(GameState.State.PLAYING)


func _ao_avancar() -> void:
	_indice_linha += 1
	_atualizar()


func _oferece_quest_pendente() -> bool:
	if _npc_def == null or _npc_def.oferece_quest_id == "":
		return false
	if GameState.quests_concluidas.has(_npc_def.oferece_quest_id):
		return false
	if GameState.quest_atual_id == _npc_def.oferece_quest_id:
		return false
	return true


func _ao_aceitar_quest() -> void:
	GameState.iniciar_quest(_npc_def.oferece_quest_id)
	_fechar()


func _ao_recusar_quest() -> void:
	_fechar()


func _ao_abrir_laboratorio() -> void:
	EventBus.laboratorio_requested.emit()
	_fechar()


func _arena_disponivel() -> bool:
	if _npc_def == null or _npc_def.abre_arena == "":
		return false
	var arena := ArenaRegistry.get_arena(_npc_def.abre_arena)
	if arena.requer_todas_insignias:
		return GameState.insignias_conquistadas.size() >= ArenaRegistry.todos_os_ids().size() - 1
	return true


func _ao_desafiar() -> void:
	EventBus.arena_challenge_started.emit(_npc_def.abre_arena)
	_fechar()


func _pode_trocar() -> bool:
	if _npc_def == null or _npc_def.troca_pede_item == "":
		return false
	var quantidade := (
		GameState.inventario_hotbar.contar(_npc_def.troca_pede_item)
		+ GameState.inventario_mochila.contar(_npc_def.troca_pede_item)
	)
	return quantidade >= _npc_def.troca_pede_quantidade


func _ao_trocar() -> void:
	if not _pode_trocar():
		return
	var restante := _npc_def.troca_pede_quantidade
	restante -= _consumir_ate(_npc_def.troca_pede_item, restante)
	if restante > 0:
		return
	GameState.adicionar_item(_npc_def.troca_oferece_item, _npc_def.troca_oferece_quantidade)
	_atualizar()


func _consumir_ate(item_id: String, quantidade: int) -> int:
	var disponivel_hotbar: int = min(quantidade, GameState.inventario_hotbar.contar(item_id))
	if disponivel_hotbar > 0:
		GameState.inventario_hotbar.remover(item_id, disponivel_hotbar)
	var restante := quantidade - disponivel_hotbar
	var disponivel_mochila: int = min(restante, GameState.inventario_mochila.contar(item_id))
	if disponivel_mochila > 0:
		GameState.inventario_mochila.remover(item_id, disponivel_mochila)
	return disponivel_hotbar + disponivel_mochila


func _atualizar() -> void:
	if _npc_def == null:
		return

	_label_nome.text = _npc_def.nome
	var fim_das_linhas := _indice_linha >= _npc_def.linhas_dialogo.size()
	var mostra_oferta := fim_das_linhas and _oferece_quest_pendente()
	var mostra_laboratorio := fim_das_linhas and not mostra_oferta and _npc_def.abre_laboratorio
	var mostra_troca := fim_das_linhas and not mostra_oferta and _npc_def.troca_pede_item != ""
	var eh_guardiao := _npc_def.abre_arena != ""
	var mostra_desafio := (
		fim_das_linhas and not mostra_oferta and eh_guardiao and _arena_disponivel()
	)
	var mostra_bloqueado := (
		fim_das_linhas and not mostra_oferta and eh_guardiao and not _arena_disponivel()
	)

	if not fim_das_linhas:
		_label_texto.text = _npc_def.linhas_dialogo[_indice_linha]
	elif mostra_oferta:
		_label_texto.text = "Aceita esta missão?"
	elif mostra_troca:
		_label_texto.text = (
			"Troco %d %s por %d %s."
			% [
				_npc_def.troca_pede_quantidade,
				_npc_def.troca_pede_item,
				_npc_def.troca_oferece_quantidade,
				_npc_def.troca_oferece_item
			]
		)
	elif mostra_bloqueado:
		_label_texto.text = "Volte quando tiver conquistado todas as insígnias."
	else:
		_label_texto.text = ""

	_botao_avancar.visible = not fim_das_linhas
	_botao_aceitar.visible = mostra_oferta
	_botao_recusar.visible = mostra_oferta
	_botao_laboratorio.visible = mostra_laboratorio
	_botao_trocar.visible = mostra_troca
	_botao_trocar.disabled = not _pode_trocar()
	_botao_desafiar.visible = mostra_desafio
	_botao_fechar.visible = fim_das_linhas and not mostra_oferta
