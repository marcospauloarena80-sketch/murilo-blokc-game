extends Node
## Sonda de teste: só existe em build de DEPURAÇÃO rodando na Web. Expõe pro
## navegador automatizado o estado do jogo (chamar window.muriloEstado() e ler
## window.muriloUltimoEstado, porque callback do JavaScriptBridge não devolve
## valor pro JS) e um jeito de
## girar a câmera (window.muriloGirar(dx, dy)), porque o navegador automatizado
## não recebe Pointer Lock. Serve pra validar o Golden Path jogando de verdade
## (ADR-027). Em build de release (o publicado) ela se remove no _ready.

var _cb_estado: JavaScriptObject
var _cb_girar: JavaScriptObject
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
	var cm := get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	if cm != null:
		dados["area_pronta"] = cm.area_pronta
	_janela.muriloUltimoEstado = JSON.stringify(dados)


func _girar(args: Array) -> void:
	var jogador := _jogador()
	if jogador != null and args.size() >= 2:
		jogador.girar_camera(float(args[0]), float(args[1]), 0.01)
