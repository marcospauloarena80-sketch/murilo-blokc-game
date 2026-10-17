extends Node3D
## Orquestra save/load/autosave da sessão (F5) + ciclo dia/noite (F6). Cada
## sistema fornece seu próprio snapshot; este script só monta o Dictionary
## final e delega ao SaveManager. Ver docs/02-ARQUITETURA.md §4.6/§4.1.

const ItemDropScene := preload("res://entities/props/item_drop.tscn")

const INTERVALO_AUTOSAVE: float = 60.0
const INTERVALO_FOME_SEG: float = 60.0
const INTERVALO_DANO_FOME_SEG: float = 10.0
## Regeneração (Ciclo 6): com a fome quase cheia, +1 de vida a cada 4 s e
## -1 de fome a cada 2 regenerações. Só roda em PLAYING (ver _process).
const INTERVALO_REGENERACAO_SEG: float = 4.0
const FOME_MINIMA_REGENERACAO: int = 18
const REGENERACOES_POR_PONTO_DE_FOME: int = 2
## Dormir (Ciclo 6): fade preto 0 -> 1 -> 0 e cura ao acordar.
const DURACAO_FADE_DORMIR_SEG: float = 1.2
const CURA_AO_DORMIR: int = 4

var _tempo_desde_autosave: float = 0.0
var _tempo_desde_fome: float = 0.0
var _tempo_desde_dano_fome: float = 0.0
var _tempo_desde_regeneracao: float = 0.0
var _regeneracoes_sem_custo: int = 0
var _era_noite: bool = false
var _fade_dormir: ColorRect

@onready var _chunk_manager: ChunkManager = $ChunkManager
@onready var _player: Player = $Player
@onready var _luz_sol: DirectionalLight3D = $DirectionalLight3D
@onready var _ambiente: WorldEnvironment = $WorldEnvironment
@onready var _loot_spawner: Node3D = $LootSpawner


func _ready() -> void:
	_era_noite = GameState.eh_noite()
	_atualizar_iluminacao()
	## Mundo carrega em fluxo (ADR-026): o delta salvo é entregue já, e o
	## ChunkManager aplica cada edição direto nos dados quando o chunk dela
	## for gerado. Cada NPC é aterrado quando o chunk dele fica pronto.
	if GameState.veio_de_continuar:
		_chunk_manager.aplicar_delta(GameState.delta_blocos_carregado)
	_chunk_manager.chunk_pronto.connect(_posicionar_npcs_no_chunk)
	EventBus.player_slept.connect(_ao_dormir)


func _posicionar_npcs_no_chunk(coord: Vector2i) -> void:
	## NPCs (F9) ficam no .tscn com Y aproximado; aqui são reajustados pelo plano do
	## Vilarejo (Ciclo 8, 8D): dentro da casa, sobre o piso, ou no centro da arena.
	for no: Node in get_tree().get_nodes_in_group("npc"):
		var npc := no as Node3D
		var npc_id: String = str(npc.get("npc_id_inicial"))
		var x: int = floori(npc.global_position.x)
		var z: int = floori(npc.global_position.z)
		if Vilarejo.POSICOES_NPCS.has(npc_id):
			var base: Vector2i = Vilarejo.POSICOES_NPCS[npc_id]
			if Vilarejo.tem_casa(npc_id):
				base = Vilarejo.centro_da_casa(npc_id)
			x = base.x
			z = base.y
		elif Vilarejo.POSICOES_TREINADORES.has(npc_id):
			var ponto: Vector2i = Vilarejo.POSICOES_TREINADORES[npc_id]
			x = ponto.x
			z = ponto.y
		var coord_npc := Vector2i(
			floori(x / float(ChunkData.SIZE_H)), floori(z / float(ChunkData.SIZE_H))
		)
		if coord_npc != coord:
			continue
		var y := _nivel_do_piso(npc_id, x, z)
		if y < 0:
			continue
		if Vilarejo.POSICOES_NPCS.has(npc_id):
			npc.global_position = Vilarejo.posicao_do_npc(npc_id, y)
		else:
			npc.global_position.y = float(y) + 1.0


func _nivel_do_piso(npc_id: String, x: int, z: int) -> int:
	## y do bloco onde o NPC pisa. Numa casa a coluna tem o telhado por cima: o piso é o
	## primeiro sólido abaixo do vão de ar sob o telhado.
	if not Vilarejo.tem_casa(npc_id):
		return _chunk_manager.altura_da_superficie(x, z)
	var telhado: int = _chunk_manager.altura_da_superficie(x, z)
	for y in range(telhado - 1, -1, -1):
		if BlockRegistry.e_solido(_chunk_manager.get_block(Vector3i(x, y, z))):
			return y
	return -1


func _process(delta: float) -> void:
	if GameState.current_state != GameState.State.PLAYING:
		return
	GameState.tempo_de_jogo_seg += delta
	GameState.ciclo_dia_noite_seg += delta
	_atualizar_iluminacao()
	_verificar_transicao_dia_noite()

	_atualizar_fome(delta)
	_regenerar_vida(delta)
	_verificar_morte()

	_tempo_desde_autosave += delta
	if _tempo_desde_autosave >= INTERVALO_AUTOSAVE:
		_tempo_desde_autosave = 0.0
		salvar_jogo()


func _atualizar_fome(delta: float) -> void:
	_tempo_desde_fome += delta
	if _tempo_desde_fome >= INTERVALO_FOME_SEG:
		_tempo_desde_fome = 0.0
		GameState.fome_atual = max(0, GameState.fome_atual - 1)

	if GameState.fome_atual <= 0:
		_tempo_desde_dano_fome += delta
		if _tempo_desde_dano_fome >= INTERVALO_DANO_FOME_SEG and GameState.vida_atual > 1:
			_tempo_desde_dano_fome = 0.0
			GameState.vida_atual -= 1
	else:
		_tempo_desde_dano_fome = 0.0


func _regenerar_vida(delta: float) -> void:
	## Chamada só pelo _process, que já exige PLAYING: pausado ou em batalha
	## o relógio nem anda.
	if (
		GameState.fome_atual < FOME_MINIMA_REGENERACAO
		or GameState.vida_atual >= GameState.vida_maxima
	):
		_tempo_desde_regeneracao = 0.0
		return
	_tempo_desde_regeneracao += delta
	if _tempo_desde_regeneracao < INTERVALO_REGENERACAO_SEG:
		return
	_tempo_desde_regeneracao = 0.0
	GameState.vida_atual += 1
	_regeneracoes_sem_custo += 1
	if _regeneracoes_sem_custo >= REGENERACOES_POR_PONTO_DE_FOME:
		_regeneracoes_sem_custo = 0
		GameState.fome_atual = max(0, GameState.fome_atual - 1)


func _verificar_morte() -> void:
	if GameState.vida_atual > 0:
		return
	_processar_morte()


func _ao_dormir() -> void:
	## Amanhece na hora (o fade é só cosmético): o teste e a sonda leem o
	## ciclo logo depois de interagir com a cama.
	GameState.ciclo_dia_noite_seg = 0.0
	GameState.vida_atual = mini(GameState.vida_atual + CURA_AO_DORMIR, GameState.vida_maxima)
	EventBus.aviso.emit("Bom dia!")
	_animar_fade_dormir()


func _animar_fade_dormir() -> void:
	if _fade_dormir == null:
		## Camada própria acima do HUD e das telas, criada só no primeiro sono.
		var camada := CanvasLayer.new()
		camada.layer = 100
		add_child(camada)
		_fade_dormir = ColorRect.new()
		_fade_dormir.color = Color.BLACK
		_fade_dormir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade_dormir.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade_dormir.modulate.a = 0.0
		camada.add_child(_fade_dormir)
	var tween := create_tween()
	tween.tween_property(_fade_dormir, "modulate:a", 1.0, DURACAO_FADE_DORMIR_SEG * 0.5)
	tween.tween_property(_fade_dormir, "modulate:a", 0.0, DURACAO_FADE_DORMIR_SEG * 0.5)


func _processar_morte() -> void:
	var pos: Vector3 = _player.global_position
	for i in range(GameState.inventario_mochila.tamanho):
		var item_id := GameState.inventario_mochila.get_item_id(i)
		if item_id == "":
			continue
		var drop: ItemDrop = ItemDropScene.instantiate()
		drop.item_id = item_id
		drop.quantidade = GameState.inventario_mochila.get_quantidade(i)
		drop.position = pos + Vector3(randf_range(-0.5, 0.5), 0.2, randf_range(-0.5, 0.5))
		_loot_spawner.add_child(drop)

	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.vida_atual = GameState.vida_maxima
	_player.global_position = GameState.ponto_respawn
	_player.velocity = Vector3.ZERO
	EventBus.player_died.emit()


func _atualizar_iluminacao() -> void:
	var fase: float = GameState.ciclo_dia_noite_seg / GameState.DURACAO_CICLO_SEG
	var r: Dictionary = DayNightCalculator.calcular(fase, GameState.FRACAO_DIA)
	_luz_sol.rotation_degrees = Vector3(r["angulo_x_graus"], r["angulo_y_graus"], 0.0)
	_luz_sol.light_energy = maxf(float(r["energia_sol"]) * 0.9, 0.1 + 0.15 * float(r["noite"]))
	_luz_sol.light_color = r["cor_luz"]
	var ambiente := _ambiente.environment
	ambiente.ambient_light_energy = r["energia_ambiente"]
	## Céu, neblina e luz ambiente com a mesma paleta (Ciclo 4, ADR-027): a
	## neblina na cor do horizonte esconde a borda do mundo.
	var topo: Color = r["cor_ceu_topo"]
	var horizonte: Color = r["cor_ceu_horizonte"]
	var ceu := ambiente.sky.sky_material as ShaderMaterial
	ceu.set_shader_parameter("cor_topo", topo)
	ceu.set_shader_parameter("cor_horizonte", horizonte)
	ceu.set_shader_parameter("cor_luz", r["cor_luz"])
	ceu.set_shader_parameter("noite", r["noite"])
	ambiente.fog_light_color = horizonte
	_chunk_manager.definir_cor_do_ceu(horizonte.lerp(topo, 0.3))
	_atualizar_cor_ambiente(horizonte.lerp(topo, 0.35).lerp(Color.WHITE, 0.35))


func _atualizar_cor_ambiente(cor_do_ceu: Color = Color.WHITE) -> void:
	## Cada bioma tinge a luz ambiente (BiomeDef.cor_ambiente); clima escurece
	## um pouco por cima disso — polimento visual da F11 (ADR-024).
	var bioma_id := WorldGenerator.bioma_em(
		int(_player.global_position.x), int(_player.global_position.z)
	)
	var bioma := BiomeRegistry.get_bioma(bioma_id)
	var cor: Color = bioma.cor_ambiente if bioma != null else Color.WHITE
	var clima := get_tree().get_first_node_in_group("weather_system") as WeatherSystem
	if clima != null and clima.estado_atual != WeatherService.Estado.NENHUM:
		cor = cor.darkened(0.25 if clima.eh_tempestade() else 0.12)
	_ambiente.environment.ambient_light_color = cor * cor_do_ceu


func _verificar_transicao_dia_noite() -> void:
	var agora_noite: bool = GameState.eh_noite()
	if agora_noite == _era_noite:
		return
	_era_noite = agora_noite
	if agora_noite:
		EventBus.night_started.emit()
	else:
		EventBus.day_started.emit()


func salvar_jogo() -> void:
	var dados: Dictionary = {
		"seed": GameState.seed_atual,
		"tempo_de_jogo_seg": GameState.tempo_de_jogo_seg,
		"ciclo_dia_noite_seg": GameState.ciclo_dia_noite_seg,
		"vida_atual": GameState.vida_atual,
		"fome_atual": GameState.fome_atual,
		"energia_atual": GameState.energia_atual,
		"hotbar_selecionado": GameState.hotbar_selecionado,
		"aparencia": GameState.aparencia_atual.serializar(),
		"hotbar": GameState.inventario_hotbar.serializar(),
		"mochila": GameState.inventario_mochila.serializar(),
		"delta_blocos": _chunk_manager.exportar_delta(),
		"jogador_posicao": _vector3_para_array(_player.global_position),
		"ponto_respawn": _vector3_para_array(GameState.ponto_respawn),
		"baus": _serializar_baus(),
		"equipe_cubelins": _serializar_cubelins(GameState.equipe_cubelins),
		"deposito_cubelins": _serializar_cubelins(GameState.deposito_cubelins),
		"quest_atual_id": GameState.quest_atual_id,
		"progresso_quest_atual": GameState.progresso_quest_atual,
		"quests_concluidas": GameState.quests_concluidas,
		"insignias_conquistadas": GameState.insignias_conquistadas,
		"especies_vistas": GameState.especies_vistas,
		"especies_capturadas": GameState.especies_capturadas,
		"treinadores_vencidos": GameState.treinadores_vencidos,
	}
	SaveManager.salvar(dados)
	EventBus.game_saved.emit()


func _serializar_baus() -> Dictionary:
	var resultado: Dictionary = {}
	for chave: String in GameState.baus:
		resultado[chave] = GameState.baus[chave].serializar()
	return resultado


func _serializar_cubelins(lista: Array[CreatureInstance]) -> Array:
	var resultado: Array = []
	for instancia: CreatureInstance in lista:
		resultado.append(instancia.serializar())
	return resultado


static func _vector3_para_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]
