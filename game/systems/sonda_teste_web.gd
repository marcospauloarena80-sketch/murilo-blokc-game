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
	dados["eh_noite"] = GameState.eh_noite()
	var cm := get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	if cm != null:
		dados["area_pronta"] = cm.area_pronta
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
		var centro := Vector3i(jogador.global_position.floor())
		var melhor := INF
		for dx in range(-raio, raio + 1):
			for dz in range(-raio, raio + 1):
				for dy in range(-4, 8):
					var pos := centro + Vector3i(dx, dy, dz)
					if cm.get_block(pos) != id:
						continue
					var dist := Vector3(pos).distance_to(jogador.global_position)
					if dist < melhor:
						melhor = dist
						achado = [pos.x, pos.y, pos.z]
	_janela.muriloUltimaBusca = JSON.stringify(achado)
