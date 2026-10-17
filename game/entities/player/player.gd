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
## Passo do raio auxiliar que acha blocos em cruz (sem colisão), em blocos.
const PASSO_RAIO_CRUZ: float = 0.1
const GRAMA_ID: int = 1
const TERRA_ID: int = 2
const TERRA_ARADA_ID: int = 22
const AMPLITUDE_MAX_BALANCO: float = 0.6
const SEGUNDOS_POR_PONTO_ENERGIA: float = 2.0
const ALTURA_QUEDA_SEGURA: float = 3.0
const INTERVALO_ATAQUE_SEG: float = 0.5
const DANO_MAO_NUA: int = 1
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
## Agachar (Ciclo 8, 8E): anda devagar, câmera mais baixa e não cai de bordas.
const FATOR_VELOCIDADE_AGACHADO: float = 0.4
const DESCIDA_CAMERA_AGACHADO: float = 0.3
const VELOCIDADE_CAMERA_AGACHAR: float = 12.0  ## fração por segundo do lerp
const ALCANCE_CHAO_AGACHADO: float = 0.6  ## sem chão até aqui abaixo = borda

## O que está sob a mira neste quadro, pro HUD e pra sonda (Ciclo 5, 5E): nome
## do NPC, da criatura ou do bloco e o tipo ("npc" | "criatura" | "bloco");
## vazios quando a mira não acerta nada.
var alvo_mirado: String = ""
var alvo_tipo: String = ""
## Agachado neste quadro (Shift): atualizado no _physics_process.
var agachado: bool = false

var _chunk_manager: ChunkManager
var _outline: MeshInstance3D
var _progresso_quebra: float = 0.0
var _bloco_em_quebra: Vector3i = Vector3i(0, -999, 0)
var _fase_balanco: float = 0.0
var _tempo_energia: float = 0.0
var _estava_no_ar: bool = false
var _y_inicio_queda: float = 0.0
var _tempo_desde_ataque: float = INTERVALO_ATAQUE_SEG
var _altura_base_camera: float = 0.0
var _avisou_tier: bool = false  ## evita repetir o aviso de tier a cada quadro

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

	_altura_base_camera = camera_pivot.position.y
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
		## Sensibilidade vem das opções do jogador (Frente 6D), não de uma constante.
		girar_camera(event.relative.x, event.relative.y, Opcoes.sensibilidade)
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
		agachado = Input.is_action_pressed("agachar") and not na_agua
		if agachado:
			esta_correndo = false
		var velocidade_atual := VELOCIDADE_CORRIDA if esta_correndo else VELOCIDADE
		if agachado:
			velocidade_atual *= FATOR_VELOCIDADE_AGACHADO
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
		agachado = false
		velocity.x = move_toward(velocity.x, 0, VELOCIDADE)
		velocity.z = move_toward(velocity.z, 0, VELOCIDADE)

	if agachado and is_on_floor():
		_travar_bordas(delta)
	_atualizar_camera_agachada(delta)
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


func _tem_chao_em(deslocamento: Vector3) -> bool:
	## Com o corpo deslocado na horizontal, há chão sob o CENTRO da cápsula até
	## ALCANCE_CHAO_AGACHADO abaixo dos pés? Raio no centro (não test_move da
	## cápsula): a cápsula apoiada na quina já escorrega pra fora antes de
	## perder o contato, e o jogador caía mesmo agachado.
	var origem := global_position + deslocamento
	var fim := origem - Vector3(0.0, DESLOCAMENTO_SONDA_PES + ALCANCE_CHAO_AGACHADO, 0.0)
	var consulta := PhysicsRayQueryParameters3D.create(origem, fim)
	consulta.exclude = [get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(consulta).is_empty()


func _travar_bordas(delta: float) -> void:
	## Agachado no chão: zera o componente horizontal que levaria a uma borda
	## (sem chão logo abaixo da posição do próximo quadro).
	var dx := velocity.x * delta
	var dz := velocity.z * delta
	if dx != 0.0 and not _tem_chao_em(Vector3(dx, 0.0, 0.0)):
		velocity.x = 0.0
	if dz != 0.0 and not _tem_chao_em(Vector3(0.0, 0.0, dz)):
		velocity.z = 0.0
	## Quina: cada eixo sozinho tem chão, mas o passo diagonal não.
	if velocity.x != 0.0 and velocity.z != 0.0:
		if not _tem_chao_em(Vector3(velocity.x * delta, 0.0, velocity.z * delta)):
			velocity.z = 0.0


func _atualizar_camera_agachada(delta: float) -> void:
	var alvo := _altura_base_camera - (DESCIDA_CAMERA_AGACHADO if agachado else 0.0)
	camera_pivot.position.y = lerpf(
		camera_pivot.position.y, alvo, minf(1.0, VELOCIDADE_CAMERA_AGACHAR * delta)
	)


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


func _multiplicador_para(def_bloco: BlockDef) -> float:
	return Ferramentas.multiplicador(def_bloco, _ferramenta_atual())


func _ferramenta_atual() -> ItemDef:
	return ItemRegistry.get_item(
		GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	)


func _gastar_ferramenta() -> void:
	## Cada bloco quebrado (ou golpe de arma) gasta 1 de durabilidade da pilha
	## selecionada; ao zerar, o item some com som.
	var def := _ferramenta_atual()
	if def == null or def.durabilidade <= 0:
		return
	if GameState.inventario_hotbar.gastar_durabilidade(GameState.hotbar_selecionado):
		AudioManager.tocar_sfx("ui_clique")
		EventBus.aviso.emit("%s quebrou" % def.nome)


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


func _resultado_com_cruz(resultado: Dictionary) -> Dictionary:
	## Blocos em cruz (muda, cogumelo, trigo) não têm colisão, então o raio
	## principal os atravessa. Este raio auxiliar anda pelo mesmo caminho em
	## passos curtos e, se passar por uma célula em cruz antes de onde o raio
	## principal acertou (ou ao alcance, se não acertou nada), mira nela: devolve
	## um resultado sintético com a face de cima da célula como superfície.
	if _chunk_manager == null:
		return resultado
	var origem := _camera.global_position
	var direcao := -_camera.global_transform.basis.z
	var comeco: float = _braco_camera.get_hit_length()
	var fim: float = comeco + ALCANCE
	if not resultado.is_empty():
		fim = minf(fim, origem.distance_to(resultado["position"]))
	var t: float = comeco
	var ultima := Vector3i(0, -999, 0)
	while t <= fim:
		var celula := Vector3i((origem + direcao * t).floor())
		if celula != ultima:
			ultima = celula
			if BlockRegistry.e_cruz(_chunk_manager.get_block(celula)):
				return {
					"collider": null,
					"position": Vector3(celula) + Vector3(0.5, 1.0, 0.5),
					"normal": Vector3.UP,
				}
		t += PASSO_RAIO_CRUZ
	return resultado


func _dano_de_ataque_atual() -> int:
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	if item_id == "":
		return DANO_MAO_NUA
	var def := ItemRegistry.get_item(item_id)
	if def == null or not def.eh_arma:
		return DANO_MAO_NUA
	return def.dano_ataque


## E numa criatura: animal só mostra o nome (Ciclo 8, 8B); Cubelin abre batalha.
func interagir_com_criatura(criatura: Creature) -> void:
	if criatura.especie != null and criatura.especie.eh_animal:
		EventBus.aviso.emit(criatura.especie.nome)
	elif GameState.tem_cubelin_disponivel():
		EventBus.battle_started.emit(criatura)


func _processar_mira_e_interacao(delta: float) -> void:
	_tempo_desde_ataque += delta

	var resultado := _resultado_com_cruz(_raycast_mira())
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
		elif Input.is_action_just_pressed("interagir"):
			interagir_com_criatura(colisor as Creature)
			_gastar_ferramenta()
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
	## Um fio para dentro da face acertada (não meio bloco): as formas finas de
	## construção (porta, cerca, laje) têm faces no meio da célula.
	var ponto_dentro: Vector3 = resultado["position"] - normal * 0.01
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
		_avisou_tier = false

	if Input.is_action_pressed("quebrar"):
		_quebrar_bloco(bloco_mirado, delta)
	else:
		_progresso_quebra = 0.0
		_avisou_tier = false

	if Input.is_action_just_pressed("colocar"):
		_tentar_colocar_bloco(bloco_mirado + Vector3i(normal.round()))

	if Input.is_action_just_pressed("interagir"):
		_processar_interacao(bloco_mirado)


func _quebrar_bloco(bloco_mirado: Vector3i, delta: float) -> void:
	## Avança a quebra do bloco; tier insuficiente não avança e avisa uma vez.
	var def := BlockRegistry.get_block(_chunk_manager.get_block(bloco_mirado))
	if def == null:
		return
	if not Ferramentas.pode_quebrar(def, _ferramenta_atual()):
		if not _avisou_tier:
			EventBus.aviso.emit(Ferramentas.aviso_tier(def))
			_avisou_tier = true
		return
	_progresso_quebra += delta * _multiplicador_para(def)
	if _progresso_quebra >= def.dureza:
		_remover_bloco(bloco_mirado)
		_progresso_quebra = 0.0
		_gastar_ferramenta()


func _processar_interacao(bloco_mirado: Vector3i) -> void:
	var id_alvo := _chunk_manager.get_block(bloco_mirado)
	var def := BlockRegistry.get_block(id_alvo)
	if def == null:
		return
	if _tentar_arar(bloco_mirado, id_alvo):
		return
	if def.tipo_especial == "cama":
		GameState.ponto_respawn = Vector3(bloco_mirado) + Vector3(0.5, 1.0, 0.5)
		## Dormir (Ciclo 6): à noite o main.gd amanhece, cura e faz o fade;
		## de dia a cama só marca o respawn.
		if GameState.eh_noite():
			EventBus.player_slept.emit()
		else:
			EventBus.aviso.emit("Você só consegue dormir à noite")
	elif def.tipo_especial == "bau":
		EventBus.chest_requested.emit(GameState.chave_posicao(bloco_mirado))
	elif def.tipo_especial == "porta":
		_alternar_porta(bloco_mirado, id_alvo)


func _base_da_porta(pos: Vector3i, id: int) -> Vector3i:
	## O topo da porta (29) olha o bloco de baixo; as outras partes são a base.
	return pos + Vector3i.DOWN if id == BlockRegistry.PORTA_TOPO_ID else pos


func _alternar_porta(pos: Vector3i, id: int) -> void:
	## Abre ou fecha a porta (8C). O topo lê o estado da base no mesher, então
	## só a base muda de id. Troca de estado não é construir nem quebrar.
	var base := _base_da_porta(pos, id)
	var id_base := _chunk_manager.get_block(base)
	if id_base == BlockRegistry.PORTA_FECHADA_ID:
		_chunk_manager.trocar_estado_do_bloco(base, BlockRegistry.PORTA_ABERTA_ID)
	elif id_base == BlockRegistry.PORTA_ABERTA_ID:
		_chunk_manager.trocar_estado_do_bloco(base, BlockRegistry.PORTA_FECHADA_ID)


func _remover_bloco(pos: Vector3i) -> void:
	## Remove o bloco; porta sai inteira (base e topo), dropando uma vez só.
	var id := _chunk_manager.get_block(pos)
	var def := BlockRegistry.get_block(id)
	_chunk_manager.set_block(pos, BlockRegistry.AR_ID)
	if def == null or def.tipo_especial != "porta":
		return
	var era_topo: bool = id == BlockRegistry.PORTA_TOPO_ID
	var parceiro := pos + (Vector3i.DOWN if era_topo else Vector3i.UP)
	var id_parceiro := _chunk_manager.get_block(parceiro)
	var parceiro_e_da_porta: bool = id_parceiro == BlockRegistry.PORTA_TOPO_ID
	if era_topo:
		parceiro_e_da_porta = (
			id_parceiro == BlockRegistry.PORTA_FECHADA_ID
			or id_parceiro == BlockRegistry.PORTA_ABERTA_ID
		)
	if parceiro_e_da_porta:
		_chunk_manager.set_block(parceiro, BlockRegistry.AR_ID)


func _tentar_arar(celula: Vector3i, id_alvo: int) -> bool:
	## Enxada na mão (ItemDef.pode_arar): grama ou terra vira terra arada, desde
	## que nada sólido esteja em cima. É obra do jogador mas não "bloco colocado":
	## usa a troca sem evento, então não conta pra missão de construir.
	if id_alvo != GRAMA_ID and id_alvo != TERRA_ID:
		return false
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	var def_item := ItemRegistry.get_item(item_id) if item_id != "" else null
	if def_item == null or not def_item.pode_arar:
		return false
	var acima := _chunk_manager.get_block(celula + Vector3i.UP)
	if acima != BlockRegistry.AR_ID and not BlockRegistry.e_cruz(acima):
		return false
	_chunk_manager.trocar_bloco_sem_evento(celula, TERRA_ARADA_ID)
	return true


func _celula_invade_o_corpo(celula: Vector3i) -> bool:
	## Cápsula do jogador (raio ~0,3, altura 1,9, pés em global_position.y - 0,95)
	## contra o cubo da célula.
	var pes := global_position.y - 0.95
	var minimo := Vector3(celula)
	var maximo := minimo + Vector3.ONE
	return (
		global_position.x + 0.3 > minimo.x
		and global_position.x - 0.3 < maximo.x
		and global_position.z + 0.3 > minimo.z
		and global_position.z - 0.3 < maximo.z
		and pes + 1.9 > minimo.y
		and pes < maximo.y
	)


func _destino_aceita_bloco(adjacente: Vector3i, def: ItemDef) -> bool:
	## Só ar e água aceitam bloco (a água é substituída e não entra no save),
	## nunca dentro do corpo do jogador (prendia num poço, replay do Ciclo 7),
	## respeitando o chão exigido (semente) e o espaço da porta.
	var id_destino := _chunk_manager.get_block(adjacente)
	if id_destino != BlockRegistry.AR_ID and id_destino != BlockRegistry.AGUA_ID:
		return false
	if _celula_invade_o_corpo(adjacente):
		return false
	var def_bloco := BlockRegistry.get_block(def.bloco_id)
	if def_bloco != null and not def_bloco.chao_exigido.is_empty():
		var chao := _chunk_manager.get_block(adjacente + Vector3i.DOWN)
		if not def_bloco.chao_exigido.has(chao):
			EventBus.aviso.emit("Não dá pra plantar aqui")
			return false
	return def.bloco_id != BlockRegistry.PORTA_FECHADA_ID or _cabe_porta_em_cima(adjacente)


func _tentar_colocar_bloco(adjacente: Vector3i) -> void:
	var item_id: String = GameState.inventario_hotbar.get_item_id(GameState.hotbar_selecionado)
	var def := ItemRegistry.get_item(item_id) if item_id != "" else null
	if def == null or def.bloco_id == BlockRegistry.AR_ID:
		return
	if not _destino_aceita_bloco(adjacente, def):
		return
	## Fora do mundo, acima do topo ou em chunk ainda não gerado o set_block
	## não faz nada: confere antes de gastar o item.
	_chunk_manager.set_block(adjacente, def.bloco_id)
	if _chunk_manager.get_block(adjacente) != def.bloco_id:
		return
	if def.bloco_id == BlockRegistry.PORTA_FECHADA_ID and not _completar_porta(adjacente):
		return
	GameState.inventario_hotbar.remover(item_id, 1)


func _cabe_porta_em_cima(base: Vector3i) -> bool:
	## Porta tem 2 blocos de altura: precisa de ar em cima e fora do corpo.
	var acima := base + Vector3i.UP
	return (
		_chunk_manager.get_block(acima) == BlockRegistry.AR_ID and not _celula_invade_o_corpo(acima)
	)


func _completar_porta(base: Vector3i) -> bool:
	## Põe o topo da porta; se o mundo não deixar (acima do limite), desfaz a base.
	var acima := base + Vector3i.UP
	_chunk_manager.set_block(acima, BlockRegistry.PORTA_TOPO_ID)
	if _chunk_manager.get_block(acima) == BlockRegistry.PORTA_TOPO_ID:
		return true
	_chunk_manager.set_block(base, BlockRegistry.AR_ID)
	return false
