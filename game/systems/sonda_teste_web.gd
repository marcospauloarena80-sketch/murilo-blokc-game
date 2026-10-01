extends Node
## Sonda de teste: só existe em build de DEPURAÇÃO rodando na Web. Expõe pro
## navegador automatizado o estado do jogo (chamar window.muriloEstado() e ler
## window.muriloUltimoEstado, porque callback do JavaScriptBridge não devolve
## valor pro JS), girar/apontar a câmera (muriloGirar, muriloMirar), porque o
## navegador automatizado não recebe Pointer Lock, e achar blocos por tipo
## (muriloProcurar). Serve pra validar o Golden Path jogando de verdade
## (ADR-027). Em build de release (o publicado) ela se remove no _ready.

const INCLINACAO_BRACO: float = 0.0872665  ## 5° fixos do SpringArm3D em player.tscn

var _cb_estado: JavaScriptObject
var _cb_girar: JavaScriptObject
var _cb_mirar: JavaScriptObject
var _cb_procurar: JavaScriptObject
var _cb_bloco: JavaScriptObject
var _cb_hora: JavaScriptObject
var _cb_spawnar: JavaScriptObject
var _cb_especies: JavaScriptObject
var _janela: JavaScriptObject


func _ready() -> void:
	if not (OS.is_debug_build() and OS.has_feature("web")):
		queue_free()
		return
	_cb_estado = JavaScriptBridge.create_callback(_estado)
	_cb_girar = JavaScriptBridge.create_callback(_girar)
	_janela = JavaScriptBridge.get_interface("window")
	_janela.muriloEstado = _cb_estado
	_janela.muriloGirar = _cb_girar
	_cb_mirar = JavaScriptBridge.create_callback(_mirar)
	_cb_procurar = JavaScriptBridge.create_callback(_procurar)
	_janela.muriloMirar = _cb_mirar
	_janela.muriloProcurar = _cb_procurar
	_cb_bloco = JavaScriptBridge.create_callback(_bloco)
	_janela.muriloBloco = _cb_bloco
	_cb_hora = JavaScriptBridge.create_callback(_hora)
	_janela.muriloHora = _cb_hora
	_cb_spawnar = JavaScriptBridge.create_callback(_spawnar)
	_janela.muriloSpawnar = _cb_spawnar
	_cb_especies = JavaScriptBridge.create_callback(_especies)
	_janela.muriloEspecies = _cb_especies


func _jogador() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _estado(_args: Array) -> void:
	var dados: Dictionary = {
		"estado": GameState.State.keys()[GameState.current_state],
		"hotbar": GameState.inventario_hotbar.serializar(),
		"mochila": GameState.inventario_mochila.serializar(),
		"quest": GameState.quest_atual_id,
		"progresso": GameState.progresso_quest_atual,
		"concluidas": GameState.quests_concluidas,
		"equipe": GameState.equipe_cubelins.size(),
		"vida": GameState.vida_atual,
	}
	var sob_mouse := get_viewport().gui_get_hovered_control()
	dados["sob_mouse"] = str(sob_mouse.get_path()) if sob_mouse != null else "nada"
	dados["modo_mouse"] = Input.mouse_mode
	var jogador := _jogador()
	if jogador != null:
		var p := jogador.global_position
		dados["pos"] = [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)]
		dados["fisica"] = jogador.is_physics_processing()
		dados["no_chao"] = jogador.is_on_floor()
		dados["velocidade"] = [
			snappedf(jogador.velocity.x, 0.01), snappedf(jogador.velocity.z, 0.01)
		]
		dados["progresso_quebra"] = snappedf(jogador._progresso_quebra, 0.01)
		dados["acoes"] = {
			"quebrar": Input.is_action_pressed("quebrar"),
			"frente": Input.is_action_pressed("mover_frente"),
			"pular": Input.is_action_pressed("pular"),
		}
		var mira := jogador._raycast_mira()
		if mira.is_empty():
			dados["mira"] = "nada"
		else:
			var alvo: Node = mira["collider"]
			var ponto: Vector3 = mira["position"]
			dados["mira"] = {
				"grupo":
				(
					"npc"
					if alvo.is_in_group("npc")
					else ("criatura" if alvo.is_in_group("creature") else "bloco")
				),
				"ponto":
				[snappedf(ponto.x, 0.01), snappedf(ponto.y, 0.01), snappedf(ponto.z, 0.01)],
				"distancia": snappedf(ponto.distance_to(jogador.global_position), 0.01),
			}
	var criaturas: Array = []
	for no: Node in get_tree().get_nodes_in_group("creature"):
		var criatura := no as Creature
		if criatura == null or criatura.especie == null:
			continue
		var c := criatura.global_position
		(
			criaturas
			. append(
				{
					"especie": criatura.especie.especie_id,
					"pos": [snappedf(c.x, 0.1), snappedf(c.y, 0.1), snappedf(c.z, 0.1)],
				}
			)
		)
	dados["criaturas"] = criaturas
	var npcs: Array = []
	for no: Node in get_tree().get_nodes_in_group("npc"):
		var npc := no as Npc
		if npc == null or npc.def == null:
			continue
		var n := npc.global_position
		npcs.append(
			{
				"id": npc.def.npc_id,
				"pos": [snappedf(n.x, 0.1), snappedf(n.y, 0.1), snappedf(n.z, 0.1)]
			}
		)
	dados["npcs"] = npcs
	dados["nos_no_grupo_creature"] = get_tree().get_nodes_in_group("creature").size()
	dados["tempo_jogo"] = snappedf(GameState.tempo_de_jogo_seg, 0.1)
	var spawner := get_tree().current_scene.get_node_or_null("CreatureSpawner")
	if spawner != null:
		dados["spawner_timer"] = snappedf(float(spawner.get("_tempo_desde_spawn")), 0.1)
	dados["eh_noite"] = GameState.eh_noite()
	var cm := get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	if cm != null:
		dados["area_pronta"] = cm.area_pronta
		dados["chunks_com_malha"] = cm._chunks_com_malha.size()
		dados["filas"] = [cm._fila_geracao.size(), cm._fila_malha.size(), cm._fila_sujos.size()]
	_janela.muriloUltimoEstado = JSON.stringify(dados)


func _girar(args: Array) -> void:
	var jogador := _jogador()
	if jogador != null and args.size() >= 2:
		jogador.girar_camera(float(args[0]), float(args[1]), 0.01)


func _mirar(args: Array) -> void:
	## Aponta a câmera pro centro do bloco (x, y, z): gira o corpo (yaw) e o
	## pivô (pitch), descontando a inclinação fixa de ~5° do braço da câmera.
	var jogador := _jogador()
	if jogador == null or args.size() < 3:
		return
	var alvo := Vector3(float(args[0]) + 0.5, float(args[1]) + 0.5, float(args[2]) + 0.5)
	var braco: Node3D = jogador.get_node("CameraPivot/SpringArm3D")
	var d := alvo - braco.global_position
	jogador.rotation.y = atan2(-d.x, -d.z)
	var pitch := atan2(d.y, Vector2(d.x, d.z).length()) + INCLINACAO_BRACO
	jogador.camera_pivot.rotation.x = clampf(
		pitch, CameraLookMath.PITCH_MIN, CameraLookMath.PITCH_MAX
	)


func _procurar(args: Array) -> void:
	## Bloco mais próximo do jogador com o id pedido, num raio; resultado em
	## window.muriloUltimaBusca ([x, y, z] ou vazio).
	var jogador := _jogador()
	var cm := get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	var achado: Array = []
	if jogador != null and cm != null and args.size() >= 2:
		var id := int(args[0])
		var raio := int(args[1])
		var dy_min := int(args[2]) if args.size() >= 3 else -4
		var dy_max := int(args[3]) if args.size() >= 4 else 7
		## dy é relativo aos pés do jogador (centro da cápsula fica 0,95 acima).
		var centro := Vector3i((jogador.global_position - Vector3(0, 0.95, 0)).floor())
		var melhor := INF
		for dx in range(-raio, raio + 1):
			for dz in range(-raio, raio + 1):
				for dy in range(dy_min, dy_max + 1):
					var pos := centro + Vector3i(dx, dy, dz)
					if cm.get_block(pos) != id:
						continue
					var dist := Vector3(pos).distance_to(jogador.global_position)
					if dist < melhor:
						melhor = dist
						achado = [pos.x, pos.y, pos.z]
	_janela.muriloUltimaBusca = JSON.stringify(achado)


func _bloco(args: Array) -> void:
	## id do bloco em (x, y, z), em window.muriloUltimoBloco.
	var cm := get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	var id := -1
	if cm != null and args.size() >= 3:
		id = cm.get_block(Vector3i(int(args[0]), int(args[1]), int(args[2])))
	_janela.muriloUltimoBloco = id


func _hora(args: Array) -> void:
	## Pula o relógio pra fase pedida do ciclo (0 = início do dia, 0,7 = noite).
	## Só pra testar conteúdo de dia/noite sem esperar o ciclo real.
	if args.size() >= 1:
		GameState.ciclo_dia_noite_seg = float(args[0]) * GameState.DURACAO_CICLO_SEG


func _spawnar(args: Array) -> void:
	## Força N tentativas do spawner real e conta quantas criaturas existem
	## depois (window.muriloUltimoSpawn).
	var spawner := get_tree().current_scene.get_node_or_null("CreatureSpawner")
	var n := int(args[0]) if args.size() >= 1 else 1
	if spawner != null:
		for i: int in range(n):
			spawner.call("_tentar_spawnar")
	_janela.muriloUltimoSpawn = get_tree().get_nodes_in_group("creature").size()
	if spawner != null:
		_janela.muriloMotivoSpawn = str(spawner.get("ultimo_motivo_sem_spawn"))


func _especies(args: Array) -> void:
	## Diagnóstico do spawn: elementos do bioma e espécies candidatas pro período
	## (window.muriloUltimasEspecies).
	var periodo := str(args[0]) if args.size() >= 1 else "dia"
	var bioma_id := str(args[1]) if args.size() >= 2 else "floresta_cubica"
	var bioma := BiomeRegistry.get_bioma(bioma_id)
	var dados: Dictionary = {
		"bioma_nulo": bioma == null,
		"elementos": Array(bioma.elementos_cubelin) if bioma != null else [],
		"ids": CreatureRegistry.todos_os_ids(),
	}
	var spawner := get_tree().current_scene.get_node_or_null("CreatureSpawner")
	if spawner != null:
		var nomes: Array = []
		for def: CreatureDef in spawner.call("_especies_do_periodo_e_bioma", periodo, bioma_id):
			nomes.append(def.especie_id)
		dados["candidatas"] = nomes
	var brotinho := CreatureRegistry.get_creature("brotinho")
	if brotinho != null:
		dados["brotinho"] = [brotinho.elemento, brotinho.periodo_spawn, brotinho.pode_ser_selvagem]
	_janela.muriloUltimasEspecies = JSON.stringify(dados)
