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
var _guardiao: GuardianBattle
var _arena: ArenaDef
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
	EventBus.arena_challenge_started.connect(_abrir_arena)


func _abrir(criatura: Creature) -> void:
	_criatura_mundo = criatura
	_guardiao = null
	_arena = null
	var selvagem := CreatureInstance.new(criatura.especie.especie_id, NIVEL_SELVAGEM_PADRAO)
	_batalha = BattleService.new(GameState.equipe_cubelins, selvagem)
	_aberto = true
	visible = true
	GameState.mudar_estado(GameState.State.PAUSED)
	_atualizar()


func _abrir_arena(arena_id: String) -> void:
	_criatura_mundo = null
	_arena = ArenaRegistry.get_arena(arena_id)
	_guardiao = GuardianBattle.new(GameState.equipe_cubelins, _arena.construir_equipe())
	_batalha = _guardiao.batalha_atual
	_aberto = true
	visible = true
	GameState.mudar_estado(GameState.State.PAUSED)
	_atualizar()


func _fechar() -> void:
	if _batalha != null and _batalha.resultado == BattleService.Resultado.DERROTA:
		_enviar_pro_refugio()
	if (
		_arena != null
		and _arena.arena_id == "coracao_dourado"
		and _batalha.resultado == BattleService.Resultado.VITORIA
	):
		EventBus.game_completed.emit()
	_aberto = false
	visible = false
	_batalha = null
	_criatura_mundo = null
	_guardiao = null
	_arena = null
	GameState.mudar_estado(GameState.State.PLAYING)
	EventBus.battle_ended.emit()


func _enviar_pro_refugio() -> void:
	## Derrota manda o jogador pro Refúgio, que já cura tudo (F9, ADR-022) —
	## sem perda de itens, só o trajeto de volta (docs/01-GDD.md §11).
	GameState.curar_no_refugio()
	var jogador := get_tree().get_first_node_in_group("player") as Player
	if jogador != null:
		jogador.global_position = GameState.PONTO_REFUGIO
		jogador.velocity = Vector3.ZERO


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
	_avancar_guardiao_se_necessario()
	_atualizar()


func _avancar_guardiao_se_necessario() -> void:
	## Vitória contra 1 membro do Guardião não encerra a luta se houver mais
	## (F10, ADR-023) — encadeia pro próximo mantendo a equipe do jogador.
	if _guardiao == null or _batalha.resultado != BattleService.Resultado.VITORIA:
		return
	if _guardiao.tem_proximo_adversario():
		_guardiao.avancar_para_proximo()
		_batalha = _guardiao.batalha_atual
	elif not GameState.tem_insignia(_arena.arena_id):
		GameState.conquistar_insignia(_arena.arena_id)


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
	if not _pode_agir() or _guardiao != null:
		return
	var tier := 2
	if not _consumir_item("cubo_captura_avancado"):
		tier = 1
		if not _consumir_item("cubo_captura"):
			return
	var sucesso := CaptureService.tentar_capturar(_batalha.selvagem, tier, sorteio)
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
	if not _pode_agir() or _guardiao != null:
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
	if _guardiao != null:
		_label_selvagem.text = (
			"%s (%d/%d): %s — HP %d/%d"
			% [
				_arena.guardiao_nome,
				_guardiao.indice_guardiao + 1,
				_guardiao.equipe_guardiao.size(),
				selvagem.especie_def().nome,
				selvagem.vida_atual,
				selvagem.vida_maxima_efetiva()
			]
		)
	else:
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
	var eh_guardiao := _guardiao != null
	_botao_trocar.disabled = not em_andamento or _proximo_indice_disponivel() == -1
	_botao_pocao.disabled = not pode_agir or _contar_item("pocao_cura") <= 0
	_botao_cubo.visible = not eh_guardiao
	_botao_cubo.disabled = (
		not pode_agir
		or (_contar_item("cubo_captura") <= 0 and _contar_item("cubo_captura_avancado") <= 0)
	)
	_botao_fugir.visible = not eh_guardiao
	_botao_fugir.disabled = not pode_agir

	_botao_fechar.visible = not em_andamento
	_label_status.text = _texto_resultado()

	if _batalha.resultado == BattleService.Resultado.VITORIA and _criatura_mundo != null:
		EventBus.creature_defeated.emit(_batalha.selvagem.especie_id)
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
