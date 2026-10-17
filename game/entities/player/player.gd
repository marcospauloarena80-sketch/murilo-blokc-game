class_name Player
extends CharacterBody3D
## Movimento e interação com o mundo do Murilo.
## Ver docs/02-ARQUITETURA.md §4.1/§4.2 e docs/07-DECISOES.md ADR-014/ADR-015.
##
## Física começa pausada e só liga quando a área em volta do jogador termina de
## gerar (sinal area_inicial_pronta do ChunkManager, ADR-026); depois disso o
## jogador fica parado se pisar num chunk que ainda não tem colisão, em vez de
## cair pelo mundo. Movimento/quebrar/colocar só respondem no
## estado GameState.PLAYING — durante CHARACTER_CREATION a gravidade continua
## (o personagem se assenta no chão pro preview), mas os controles ficam mudos.

const VELOCIDADE: float = 5.0
const VELOCIDADE_CORRIDA: float = 8.0
## ~1,3 bloco de altura. Com 4.5 (1,03 bloco) subir um degrau de 1 bloco ficava
## no limite e quem caía num buraco raso não saía (achado jogando, ADR-027).
const FORCA_PULO: float = 5.0
const GRAVIDADE: float = 9.8
## Nadar (Ciclo 4, lagos): afunda devagar, Espaço sobe, anda mais lento e
## cair na água não machuca.
const FATOR_GRAVIDADE_AGUA: float = 0.25
const VELOCIDADE_SUBIDA_AGUA: float = 2.6
const FATOR_VELOCIDADE_AGUA: float = 0.55
## Sonda dos pés um pouco acima da base da cápsula (0,95): em pé na margem
## ela lê o bloco onde os pés estão, não o chão.
const DESLOCAMENTO_SONDA_PES: float = 0.9
const ALCANCE: float = 5.5
const AMPLITUDE_MAX_BALANCO: float = 0.6
const SEGUNDOS_POR_PONTO_ENERGIA: float = 2.0
const ALTURA_QUEDA_SEGURA: float = 3.0
const INTERVALO_ATAQUE_SEG: float = 0.5
const DANO_MAO_NUA: int = 1
const SENSIBILIDADE_MOUSE: float = 0.003
const ALTURA_LIMITE_QUEDA: float = -20.0
## Centro da cápsula (altura 1.9) fica 0.95 acima dos pés; o topo do bloco de
## superfície está em y+1. Margem pequena pra não nascer dentro do chão.
const ALTURA_ACIMA_DO_BLOCO: float = 2.0
const PITCH_INICIAL_CAMERA: float = -0.35
## Câmera abre um pouco ao correr (Ciclo 5): sensação de velocidade sem enjoar.
const FOV_PARADO: float = 72.0
const FOV_CORRIDA: float = 80.0
const VELOCIDADE_FOV: float = 6.0  ## fração por segundo do lerp
const ALTURA_QUEDA_POEIRA: float = 1.5  ## acima disso, aterrissar levanta poeira

## O que está sob a mira neste quadro, pro HUD e pra sonda (Ciclo 5, 5E): nome
## do NPC, da criatura ou do bloco e o tipo ("npc" | "criatura" | "bloco");
## vazios quando a mira não acerta nada.
var alvo_mirado: String = ""
var alvo_tipo: String = ""

var _chunk_manager: ChunkManager
var _outline: MeshInstance3D
var _progresso_quebra: float = 0.0
var _bloco_em_quebra: Vector3i = Vector3i(0, -999, 0)
var _fase_balanco: float = 0.0
var _tempo_energia: float = 0.0
var _estava_no_ar: bool = false
var _y_inicio_queda: float = 0.0
var _tempo_desde_ataque: float = INTERVALO_ATAQUE_SEG

## Atalhos pros materiais do CorpoBlocos (o criador de personagem lê a camisa).
var _mat_pele: StandardMaterial3D
var _mat_cabelo: StandardMaterial3D
var _mat_camisa: StandardMaterial3D
var _mat_calca: StandardMaterial3D

@onready var camera_pivot: Node3D = $CameraPivot
@onready var _corpo: CorpoBlocos = $Corpo
@onready var _braco_camera: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var _ombro_esquerdo: Node3D = $Corpo/OmbroEsquerdo
@onready var _ombro_direito: Node3D = $Corpo/OmbroDireito
@onready var _quadril_esquerdo: Node3D = $Corpo/QuadrilEsquerdo
@onready var _quadril_direito: Node3D = $Corpo/QuadrilDireito


func _ready() -> void:
	add_to_group("player")
	_configurar_materiais()
	aplicar_aparencia(GameState.aparencia_atual)

	_outline = _criar_outline()
	add_child(_outline)
	_outline.visible = false

	## Sem isso, ao olhar pra cima o braço da câmera colide com a própria
	## cápsula e a câmera entra na cabeça do personagem.
	_braco_camera.add_excluded_object(get_rid())
	## Começa olhando um pouco pra baixo: o chão à frente fica ao alcance da mira.
	camera_pivot.rotation.x = PITCH_INICIAL_CAMERA

	## No Continuar, a posição salva vale desde já: o mundo carrega a partir
	## dela e um save feito durante o carregamento não volta pro spawn padrão.
	if GameState.veio_de_continuar:
		global_position = GameState.posicao_salva

	set_physics_process(false)
	_chunk_manager = get_tree().get_first_node_in_group("chunk_manager") as ChunkManager
	if _chunk_manager == null:
		return
	if _chunk_manager.area_pronta:
		_ao_area_pronta()
	else:
		_chunk_manager.area_inicial_pronta.connect(_ao_area_pronta)


func _configurar_materiais() -> void:
	## O corpo (malhas, materiais e rosto) é o CorpoBlocos compartilhado com os
	## NPCs (Frente 5A); aqui ficam só os atalhos.
	_mat_pele = _corpo.mat_pele
	_mat_cabelo = _corpo.mat_cabelo
	_mat_camisa = _corpo.mat_camisa
	_mat_calca = _corpo.mat_calca


func aplicar_aparencia(aparencia: CharacterAppearance) -> void:
	_corpo.aplicar_aparencia(aparencia)


func _ao_area_pronta() -> void:
	## Novo jogo: nasce em pé na superfície, em vez de cair de y=45 (1 a 2 s
	## de queda olhando pro céu no primeiro contato com o jogo).
	if not GameState.veio_de_continuar and _chunk_manager != null:
		var y := _chunk_manager.altura_da_superficie(
			floori(global_position.x), floori(global_position.z)
		)
		if y >= 0:
			global_position.y = float(y) + ALTURA_ACIMA_DO_BLOCO
	velocity = Vector3.ZERO
	set_physics_process(true)


func _criar_outline() -> MeshInstance3D:
	var no := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(1.02, 1.02, 1.02)
	no.mesh = caixa
	no.top_level = true
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.25)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	no.material_override = material
	return no


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		girar_camera(event.relative.x, event.relative.y, SENSIBILIDADE_MOUSE)
	elif event is InputEventMouseButton and event.pressed:
		_talvez_capturar_mouse()


func girar_camera(delta_x: float, delta_y: float, sensibilidade: float) -> void:
	rotate_y(CameraLookMath.delta_yaw(delta_x, sensibilidade))
	camera_pivot.rotation.x = CameraLookMath.novo_pitch(
		camera_pivot.rotation.x, delta_y, sensibilidade
	)


func _talvez_capturar_mouse() -> void:
	## Só pede captura em resposta a um clique de verdade — pedir toda hora
	## (ex.: a cada frame) trava a exportação web, porque a API de Pointer
	## Lock do navegador exige um gesto real do usuário e rejeita chamadas
	## fora disso (achado real reportado pelo usuário na F12, ADR-025).
	## Só pede se AINDA não está capturado — repetir o pedido em todo clique
	## (inclusive os cliques de segurar pra quebrar bloco) faz o navegador
	## reconfirmar o Pointer Lock à toa, o que pode soltar/reiniciar o estado
	## do botão do mouse no meio da ação (achado real: "quebrar" não
	## funcionava no Chrome/Mac mesmo com o mapa de input correto, ADR-026).
	if DisplayServer.is_touchscreen_available():
		return  # toque olha por arrasto de tela, não por captura de mouse
	if (
		GameState.current_state == GameState.State.PLAYING
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _liberar_mouse_se_necessario(jogando: bool) -> void:
	if DisplayServer.is_touchscreen_available():
		return
	if not jogando and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _esta_na_agua(abaixo_do_centro: float = 0.0) -> bool:
	if _chunk_manager == null:
		return false
	var ponto := global_position - Vector3(0.0, abaixo_do_centro, 0.0)
	return _chunk_manager.get_block(Vector3i(ponto.floor())) == BlockRegistry.AGUA_ID


func _physics_process(delta: float) -> void:
	if _chunk_manager != null and not _chunk_manager.chunk_pronto_em(global_position):
		## Chunk sem colisão ainda (mundo carregando em segundo plano): espera
		## parado em vez de atravessar o chão (ADR-026).
		velocity = Vector3.ZERO
		return
	if global_position.y < ALTURA_LIMITE_QUEDA:
		## Caiu pela borda do mundo finito: volta pro ponto de respawn.
		global_position = GameState.ponto_respawn
		velocity = Vector3.ZERO
		return
	## Centro OU pés na água: só o centro deixava o jogador sair do modo nado
	## na superfície com os pés 0,6 abaixo do topo, sem alcançar a margem.
	var centro_na_agua := _esta_na_agua()
	var na_agua := centro_na_agua or _esta_na_agua(DESLOCAMENTO_SONDA_PES)
	if na_agua:
		velocity.y = maxf(velocity.y - GRAVIDADE * FATOR_GRAVIDADE_AGUA * delta, -2.5)
		_y_inicio_queda = global_position.y
		if GameState.current_state == GameState.State.PLAYING and Input.is_action_pressed("pular"):
			if centro_na_agua:
				velocity.y = move_toward(velocity.y, VELOCIDADE_SUBIDA_AGUA, 12.0 * delta)
			else:
				velocity.y = FORCA_PULO  # só os pés na água: na superfície, pula pra fora
	elif not is_on_floor():
		velocity.y -= GRAVIDADE * delta
		if not _estava_no_ar:
			_estava_no_ar = true
			_y_inicio_queda = global_position.y
	elif _estava_no_ar:
		_estava_no_ar = false
		var altura_queda := _y_inicio_queda - global_position.y
		if altura_queda > ALTURA_QUEDA_POEIRA:
			EventBus.player_landed.emit(
				global_position - Vector3(0.0, DESLOCAMENTO_SONDA_PES, 0.0), altura_queda
			)
		if GameState.current_state == GameState.State.PLAYING:
			_aplicar_dano_de_queda(altura_queda)

	var jogando := GameState.current_state == GameState.State.PLAYING
	_liberar_mouse_se_necessario(jogando)
	var esta_correndo := false

	if jogando:
		if Input.is_action_just_pressed("pular") and is_on_floor():
			velocity.y = FORCA_PULO

		var input_dir := Input.get_vector(
			"mover_esquerda", "mover_direita", "mover_frente", "mover_tras"
		)
		var direcao := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		esta_correndo = (
			Input.is_action_pressed("correr")
			and direcao != Vector3.ZERO
			and GameState.energia_atual > 0
		)
		var velocidade_atual := VELOCIDADE_CORRIDA if esta_correndo else VELOCIDADE
		if na_agua:
			velocidade_atual *= FATOR_VELOCIDADE_AGUA
		_atualizar_energia(delta, esta_correndo)

		if direcao:
			velocity.x = direcao.x * velocidade_atual
			velocity.z = direcao.z * velocidade_atual
		else:
			velocity.x = move_toward(velocity.x, 0, velocidade_atual)
			velocity.z = move_toward(velocity.z, 0, velocidade_atual)
	else:
		velocity.x = move_toward(velocity.x, 0, VELOCIDADE)
		velocity.z = move_toward(velocity.z, 0, VELOCIDADE)

	move_and_slide()
	_animar_membros(delta)
	_atualizar_fov(delta, esta_correndo)

	if jogando:
		_processar_selecao_de_bloco()
		_processar_mira_e_interacao(delta)
		if Input.is_action_just_pressed("comer"):
			_tentar_comer()
	elif _outline:
		_outline.visible = false


func _animar_membros(delta: float) -> void:
	var velocidade_horizontal := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and velocidade_horizontal > 0.1:
		_fase_balanco += delta * velocidade_horizontal * 3.0
	var fator: float = clamp(velocidade_horizontal / VELOCIDADE_CORRIDA, 0.0, 1.0)
	var amplitude: float = fator * AMPLITUDE_MAX_BALANCO
	var angulo: float = sin(_fase_balanco) * amplitude
	_ombro_esquerdo.rotation.x = angulo
	_ombro_direito.rotation.x = -angulo
	_quadril_esquerdo.rotation.x = -angulo
	_quadril_direito.rotation.x = angulo


func _atualizar_fov(delta: float, esta_correndo: bool) -> void:
	var alvo := FOV_CORRIDA if esta_correndo else FOV_PARADO
	_camera.fov = lerpf(_camera.fov, alvo, minf(1.0, VELOCIDADE_FOV * delta))


func _processar_selecao_de_bloco() -> void:
	for i in range(1, 9):
		if Input.is_action_just_pressed("hotbar_%d" % i):
			GameState.hotbar_selecionado = i - 1


func _aplicar_dano_de_queda(altura_queda: float) -> void:
	var excesso: float = altura_queda - ALTURA_QUEDA_SEGURA
	if excesso <= 0.0:
		return
	GameState.vida_atual = max(0, GameState.vida_atual - int(floor(excesso)))


func _atualizar_energia(delta: float, esta_correndo: bool) -> void:
	_tempo_energia += delta
	if _tempo_energia < SEGUNDOS_POR_PONTO_ENERGIA:
		return
	_tempo_energia = 0.0
	if esta_correndo:
		GameState.energia_atual = max(0, GameState.energia_atual - 1)
	else:
		GameState.energia_atual = min(GameState.energia_maxima, GameState.energia_atual + 1)


func _tentar_comer() -> void:
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	if item_id == "":
		return
	var def := ItemRegistry.get_item(item_id)
	if def == null or not def.eh_comida:
		return
	if GameState.fome_atual >= GameState.fome_maxima:
		return
	if not GameState.inventario_hotbar.remover(item_id, 1):
		return
	GameState.fome_atual = min(GameState.fome_maxima, GameState.fome_atual + def.restaura_fome)


func _multiplicador_ferramenta_atual() -> float:
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	if item_id == "":
		return 1.0
	var def := ItemRegistry.get_item(item_id)
	if def == null or not def.eh_ferramenta:
		return 1.0
	return def.multiplicador_velocidade


func _raycast_mira() -> Dictionary:
	if _chunk_manager == null:
		return {}
	## O raio sai da câmera, passa pelo centro da tela (a mira "+") e pela base
	## do braço no ombro, e segue ALCANCE além dela. Antes ele parava 5 unidades
	## depois da câmera, que fica atrás do jogador: terminava antes do
	## personagem e nunca acertava nada (bug desde a F2, achado jogando o build
	## real, ADR-027). O braço de mola garante que entre a câmera e o ombro não
	## há bloco; o único obstáculo possível é o próprio jogador, excluído.
	var origem := _camera.global_position
	var direcao := -_camera.global_transform.basis.z
	var comprimento := _braco_camera.get_hit_length() + ALCANCE
	var query := PhysicsRayQueryParameters3D.create(origem, origem + direcao * comprimento)
	query.exclude = [get_rid()]
	var resultado := get_world_3d().direct_space_state.intersect_ray(query)
	## Garantia: o resto do código (bloco mirado, onde colocar) depende da
	## normal virada pro jogador. Com a malha do avesso (bug corrigido no
	## ChunkMesher, ADR-027) ela vinha invertida e trocava os dois blocos.
	if not resultado.is_empty() and (resultado["normal"] as Vector3).dot(direcao) > 0.0:
		resultado["normal"] = -(resultado["normal"] as Vector3)
	return resultado


func _dano_de_ataque_atual() -> int:
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	if item_id == "":
		return DANO_MAO_NUA
	var def := ItemRegistry.get_item(item_id)
	if def == null or not def.eh_arma:
		return DANO_MAO_NUA
	return def.dano_ataque


func _processar_mira_e_interacao(delta: float) -> void:
	_tempo_desde_ataque += delta

	var resultado := _raycast_mira()
	if resultado.is_empty():
		_outline.visible = false
		_progresso_quebra = 0.0
		alvo_mirado = ""
		alvo_tipo = ""
		return

	var colisor: Node = resultado.get("collider")
	if colisor != null and colisor.is_in_group("creature"):
		_outline.visible = false
		_progresso_quebra = 0.0
		var especie := (colisor as Creature).especie
		alvo_tipo = "criatura"
		alvo_mirado = especie.nome if especie != null else ""
		if Input.is_action_just_pressed("quebrar") and _tempo_desde_ataque >= INTERVALO_ATAQUE_SEG:
			_tempo_desde_ataque = 0.0
			(colisor as Creature).receber_dano(_dano_de_ataque_atual())
		elif Input.is_action_just_pressed("interagir") and GameState.tem_cubelin_disponivel():
			EventBus.battle_started.emit(colisor)
		return

	if colisor != null and colisor.is_in_group("npc"):
		_outline.visible = false
		_progresso_quebra = 0.0
		var def_npc := (colisor as Npc).def
		alvo_tipo = "npc"
		alvo_mirado = def_npc.nome if def_npc != null else ""
		if Input.is_action_just_pressed("interagir"):
			EventBus.dialogue_started.emit(colisor)
		return

	var normal: Vector3 = resultado["normal"]
	var ponto_dentro: Vector3 = resultado["position"] - normal * 0.5
	var bloco_mirado := Vector3i(
		floori(ponto_dentro.x), floori(ponto_dentro.y), floori(ponto_dentro.z)
	)
	var def_bloco := BlockRegistry.get_block(_chunk_manager.get_block(bloco_mirado))
	alvo_tipo = "bloco"
	alvo_mirado = def_bloco.nome if def_bloco != null else ""

	_outline.visible = true
	_outline.global_position = Vector3(bloco_mirado) + Vector3(0.5, 0.5, 0.5)

	if bloco_mirado != _bloco_em_quebra:
		_bloco_em_quebra = bloco_mirado
		_progresso_quebra = 0.0

	if Input.is_action_pressed("quebrar"):
		var id_alvo := _chunk_manager.get_block(bloco_mirado)
		var def := BlockRegistry.get_block(id_alvo)
		if def != null:
			_progresso_quebra += delta * _multiplicador_ferramenta_atual()
			if _progresso_quebra >= def.dureza:
				_chunk_manager.set_block(bloco_mirado, BlockRegistry.AR_ID)
				_progresso_quebra = 0.0
	else:
		_progresso_quebra = 0.0

	if Input.is_action_just_pressed("colocar"):
		_tentar_colocar_bloco(bloco_mirado + Vector3i(normal.round()))

	if Input.is_action_just_pressed("interagir"):
		_processar_interacao(bloco_mirado)


func _processar_interacao(bloco_mirado: Vector3i) -> void:
	var id_alvo := _chunk_manager.get_block(bloco_mirado)
	var def := BlockRegistry.get_block(id_alvo)
	if def == null:
		return
	if def.tipo_especial == "cama":
		GameState.ponto_respawn = Vector3(bloco_mirado) + Vector3(0.5, 1.0, 0.5)
	elif def.tipo_especial == "bau":
		EventBus.chest_requested.emit(GameState.chave_posicao(bloco_mirado))


func _tentar_colocar_bloco(adjacente: Vector3i) -> void:
	## Só ar e água aceitam bloco. A água é substituída (lago raso, mirando o
	## fundo) e não entra no save, então Continuar fica consistente.
	var id_destino := _chunk_manager.get_block(adjacente)
	if id_destino != BlockRegistry.AR_ID and id_destino != BlockRegistry.AGUA_ID:
		return
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	if item_id == "":
		return
	var def := ItemRegistry.get_item(item_id)
	if def == null or def.bloco_id == BlockRegistry.AR_ID:
		return
	## Fora do mundo, acima do topo ou em chunk ainda não gerado o set_block
	## não faz nada: confere antes de gastar o item.
	_chunk_manager.set_block(adjacente, def.bloco_id)
	if _chunk_manager.get_block(adjacente) != def.bloco_id:
		return
	GameState.inventario_hotbar.remover(item_id, 1)
