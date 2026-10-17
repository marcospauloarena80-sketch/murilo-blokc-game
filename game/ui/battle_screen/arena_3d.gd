class_name Arena3D
extends Node3D
## Cena 3D do terço superior da tela de batalha (Ciclo 9, Frente 9B): chão
## circular, céu, duas criaturas frente a frente montadas por código a partir
## de CreatureDef e câmera lateral. As animações usam Tween sem await; sem
## renderização (headless/testes) os efeitos finais são aplicados na hora.

enum Lado { JOGADOR, OPONENTE }

const POS_JOGADOR: Vector3 = Vector3(-1.4, 0.0, 0.0)
const POS_OPONENTE: Vector3 = Vector3(1.4, 0.0, 0.0)
const DISTANCIA_INVESTIDA: float = 0.6
const DURACAO_IDA_S: float = 0.15
const DURACAO_VOLTA_S: float = 0.3
const COR_DANO: Color = Color(1.0, 0.15, 0.15)

## Falso em headless; testes podem ligar para exercitar os Tweens.
var animacoes_ligadas: bool = DisplayServer.get_name() != "headless"

var _corpos: Array[Node3D] = [null, null]
var _tweens: Array[Tween] = []
var _bola: MeshInstance3D
var _livre_em_s: float = 0.0


func _ready() -> void:
	_montar_cenario()


func _montar_cenario() -> void:
	var chao := MeshInstance3D.new()
	chao.name = "Chao"
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 3.2
	cilindro.bottom_radius = 3.2
	cilindro.height = 0.2
	chao.mesh = cilindro
	chao.material_override = CorpoCubelin.criar_material(Color(0.36, 0.6, 0.3), false)
	chao.position = Vector3(0.0, -0.1, 0.0)
	add_child(chao)

	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.53, 0.78, 0.95)  ## mesmo azul do céu do jogo
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.8, 0.85, 0.9)
	var mundo_amb := WorldEnvironment.new()
	mundo_amb.name = "Ceu"
	mundo_amb.environment = ambiente
	add_child(mundo_amb)

	var sol := DirectionalLight3D.new()
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	add_child(sol)

	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0.0, 1.1, 4.6)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.5, 0.0))


func montar(def_jogador: CreatureDef, def_oponente: CreatureDef) -> void:
	trocar_corpo(Lado.JOGADOR, def_jogador)
	trocar_corpo(Lado.OPONENTE, def_oponente)


func trocar_corpo(lado: int, def: CreatureDef) -> void:
	_cancelar_animacoes()
	if _corpos[lado] != null:
		_corpos[lado].queue_free()
	var corpo := CorpoCubelin.montar(def)
	corpo.position = _posicao_base(lado)
	## A frente do corpo é -Z: jogador olha para +X, oponente para -X.
	corpo.rotation.y = -PI / 2.0 if lado == Lado.JOGADOR else PI / 2.0
	add_child(corpo)
	_corpos[lado] = corpo


func corpo_do_lado(lado: int) -> Node3D:
	return _corpos[lado]


## Avanço de 0,6 e volta em 0,3 s.
func investida(lado: int) -> void:
	var corpo := _corpos[lado]
	if corpo == null or not animacoes_ligadas:
		return
	var base := _posicao_base(lado)
	var sentido: float = 1.0 if lado == Lado.JOGADOR else -1.0
	var tween := _novo_tween(DURACAO_IDA_S + DURACAO_VOLTA_S)
	tween.tween_property(corpo, "position:x", base.x + sentido * DISTANCIA_INVESTIDA, DURACAO_IDA_S)
	tween.tween_property(corpo, "position:x", base.x, DURACAO_VOLTA_S)


## Pisca vermelho ao levar dano.
func piscar_dano(lado: int) -> void:
	var corpo := _corpos[lado]
	if corpo == null or not animacoes_ligadas:
		return
	var caixa := corpo.get_node_or_null("Caixa") as MeshInstance3D
	if caixa == null:
		return
	var material := caixa.material_override as StandardMaterial3D
	var cor_original: Color = material.albedo_color
	var tween := _novo_tween(0.3)
	tween.tween_property(material, "albedo_color", COR_DANO, 0.1)
	tween.tween_property(material, "albedo_color", cor_original, 0.1)
	tween.tween_property(material, "albedo_color", COR_DANO, 0.05)
	tween.tween_property(material, "albedo_color", cor_original, 0.05)


## Cubo de captura: a esfera encolhe o alvo, balança 2 vezes e só então mostra
## o resultado (escapou = o alvo volta ao tamanho normal).
func animar_captura(sucesso: bool) -> void:
	var alvo := _corpos[Lado.OPONENTE]
	if alvo == null:
		return
	if not animacoes_ligadas:
		alvo.visible = not sucesso
		return
	_remover_bola()
	_bola = MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.25
	esfera.height = 0.5
	_bola.mesh = esfera
	_bola.material_override = CorpoCubelin.criar_material(Color(0.9, 0.2, 0.2), false)
	_bola.position = POS_OPONENTE + Vector3(0.0, 1.8, 0.0)
	add_child(_bola)
	var bola := _bola
	var tween := _novo_tween(0.35 + 2 * 0.4)
	tween.set_parallel(true)
	tween.tween_property(bola, "position:y", 0.25, 0.35)
	tween.tween_property(alvo, "scale", Vector3.ONE * 0.05, 0.35)
	tween.set_parallel(false)
	for i in range(2):
		tween.tween_property(bola, "rotation:z", 0.45, 0.1)
		tween.tween_property(bola, "rotation:z", -0.45, 0.2)
		tween.tween_property(bola, "rotation:z", 0.0, 0.1)
	tween.tween_callback(_resolver_captura.bind(sucesso))


## Evolução: flash branco e troca de forma no meio dele.
func evoluir_jogador(def: CreatureDef) -> void:
	if not animacoes_ligadas:
		trocar_corpo(Lado.JOGADOR, def)
		return
	var flash := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.9
	esfera.height = 1.8
	flash.mesh = esfera
	var material := CorpoCubelin.criar_material(Color(1, 1, 1, 0), true)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = material
	flash.position = POS_JOGADOR + Vector3(0.0, 0.5, 0.0)
	add_child(flash)
	## trocar_corpo cancela os Tweens da fila, então o flash usa um próprio.
	var tween := create_tween()
	tween.tween_property(material, "albedo_color:a", 1.0, 0.25)
	tween.tween_callback(trocar_corpo.bind(Lado.JOGADOR, def))
	tween.tween_property(material, "albedo_color:a", 0.0, 0.35)
	tween.tween_callback(flash.queue_free)


func _resolver_captura(sucesso: bool) -> void:
	var alvo := _corpos[Lado.OPONENTE]
	if sucesso:
		if alvo != null:
			alvo.visible = false
	else:
		if alvo != null:
			alvo.scale = Vector3.ONE
		_remover_bola()


func _posicao_base(lado: int) -> Vector3:
	return POS_JOGADOR if lado == Lado.JOGADOR else POS_OPONENTE


## Enfileira: uma animação nova só começa depois que a anterior terminou
## (o golpe do jogador e a resposta do selvagem saem no mesmo quadro).
func _novo_tween(duracao_s: float) -> Tween:
	var agora: float = Time.get_ticks_msec() / 1000.0
	var atraso: float = maxf(0.0, _livre_em_s - agora)
	_livre_em_s = agora + atraso + duracao_s
	var tween := create_tween()
	if atraso > 0.0:
		tween.tween_interval(atraso)
	_tweens.append(tween)
	return tween


func _cancelar_animacoes() -> void:
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_livre_em_s = 0.0
	_remover_bola()
	for lado: int in [Lado.JOGADOR, Lado.OPONENTE]:
		var corpo := _corpos[lado]
		if corpo != null and is_instance_valid(corpo):
			corpo.position = _posicao_base(lado)
			corpo.scale = Vector3.ONE
			corpo.visible = true


func _remover_bola() -> void:
	if _bola != null and is_instance_valid(_bola):
		_bola.queue_free()
	_bola = null
