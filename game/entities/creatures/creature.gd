class_name Creature
extends CharacterBody3D
## Cubelin vivo no mundo (F7): corpo único (caixa colorida pelo elemento),
## física simples com colisão real no terreno voxel, sem pathfinding —
## direção crua + move_and_slide (ADR-020). Batalha/captura/XP ficam pra F8.
## Ciclo 5 (Frente 5B): olhos na frente, faixa do elemento na base, pulinho
## visual, corpo virado pro movimento e placa com o nome da espécie.

const GRAVIDADE: float = 9.8
const INTERVALO_DANO_CONTATO_SEG: float = 1.0
const VELOCIDADE_GIRO_RAD_S: float = 6.0
const COR_PUPILA: Color = Color(0.1, 0.1, 0.12)
const COR_PUPILA_AGRESSIVA: Color = Color(0.9, 0.1, 0.1)

var especie: CreatureDef
var vida_atual: int = 0
## Nível do selvagem, definido pelo spawner (Ciclo 9, 9A). 0 = sem nível
## (animais e criaturas de teste): a batalha usa o padrão.
var nivel: int = 0

var _comportamento: CreatureBehavior
var _jogador: Node3D
var _tempo_desde_dano_contato: float = INTERVALO_DANO_CONTATO_SEG
var _tempo_anim: float = 0.0
var _pupilas: Array[MeshInstance3D] = []

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _hurtbox: Area3D = $Hurtbox


func configurar(def: CreatureDef) -> void:
	especie = def
	vida_atual = def.vida_maxima
	_comportamento = CreatureBehavior.new(def)
	## O spawner chama configurar() antes do add_child, quando os @onready
	## ainda são null: por isso o visual usa $MeshInstance3D direto (ADR-027).
	_montar_visual(def)


## Define o nível e escala a vida do mundo como CreatureInstance (9A).
func definir_nivel(novo_nivel: int) -> void:
	nivel = novo_nivel
	if especie == null or novo_nivel <= 0:
		return
	var base: int = especie.vida_maxima
	vida_atual = base + int(floor(base * CreatureInstance.FATOR_CRESCIMENTO * (novo_nivel - 1)))
	var placa := get_node_or_null("Placa") as Label3D
	if placa != null:
		placa.text = "%s Nv.%d" % [especie.nome, novo_nivel]


func _ready() -> void:
	add_to_group("creature")
	if especie != null and especie.eh_animal:
		add_to_group("animal")
	_jogador = get_tree().get_first_node_in_group("player")
	_hurtbox.body_entered.connect(_ao_tocar_jogador)
	EventBus.day_started.connect(_atualizar_pupilas)
	EventBus.night_started.connect(_atualizar_pupilas)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta
	else:
		velocity.y = 0.0

	if _jogador != null and _comportamento != null:
		var direcao: Vector3 = _comportamento.atualizar(
			delta, global_position, _jogador.global_position
		)
		velocity.x = direcao.x * especie.velocidade
		velocity.z = direcao.z * especie.velocidade
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	_virar_para_o_movimento(delta)
	_animar_pulinho(delta)
	move_and_slide()
	_tempo_desde_dano_contato += delta


func receber_dano(quantidade: int) -> void:
	vida_atual = max(0, vida_atual - quantidade)
	if vida_atual <= 0:
		if especie.eh_animal:
			_dropar_comida()
		else:
			EventBus.creature_defeated.emit(especie.especie_id)
		queue_free()


## Animal morto solta os itens de especie.drops pelo LootSpawner (Ciclo 8, 8B).
func _dropar_comida() -> void:
	var itens: Dictionary = {}
	for item_id: String in especie.drops:
		itens[item_id] = randi_range(1, maxi(1, int(especie.drops[item_id])))
	var spawner := get_tree().get_first_node_in_group("loot_spawner") as LootSpawner
	if spawner != null:
		spawner.dropar_itens(global_position, itens)


func _ao_tocar_jogador(corpo: Node3D) -> void:
	if not corpo.is_in_group("player"):
		return
	if especie == null or not especie.eh_agressivo:
		return
	if _tempo_desde_dano_contato < INTERVALO_DANO_CONTATO_SEG:
		return
	_tempo_desde_dano_contato = 0.0
	GameState.vida_atual = max(0, GameState.vida_atual - especie.dano_contato)


## --- Visual (Frente 5B) ---


func _montar_visual(def: CreatureDef) -> void:
	var corpo := $MeshInstance3D as MeshInstance3D
	var tamanho: Vector3 = _tamanho_do_formato(def.formato)
	## BoxMesh novo por instância: o da cena é compartilhado por todas as
	## criaturas, e mudar o size dele achataria o mundo inteiro.
	var caixa := BoxMesh.new()
	caixa.size = tamanho
	corpo.mesh = caixa
	corpo.material_override = _criar_material(def.cor, false)

	var frente_z: float = -tamanho.z / 2.0 - 0.005
	var altura_olhos: float = tamanho.y * 0.15
	var afastamento_olhos: float = tamanho.x * 0.25
	_criar_olho(
		corpo, "OlhoEsquerdo", "PupilaEsquerda", Vector3(-afastamento_olhos, altura_olhos, frente_z)
	)
	_criar_olho(
		corpo, "OlhoDireito", "PupilaDireita", Vector3(afastamento_olhos, altura_olhos, frente_z)
	)
	_atualizar_pupilas()

	## Faixa do elemento: anel fino em volta da base, na cor secundária.
	## Animal não tem elemento, então fica sem faixa.
	if not def.eh_animal:
		var faixa := MeshInstance3D.new()
		faixa.name = "Faixa"
		var anel := BoxMesh.new()
		anel.size = Vector3(tamanho.x + 0.02, 0.06, tamanho.z + 0.02)
		faixa.mesh = anel
		faixa.material_override = _criar_material(def.cor_secundaria, true)
		faixa.position = Vector3(0.0, -tamanho.y / 2.0 + 0.06, 0.0)
		corpo.add_child(faixa)

	## Placa com o nome: é o que diferencia Pedrolim de Rochedo de longe. A
	## sonda e o HUD do Ciclo 6 usam especie.nome pro nome sob a mira.
	var placa := Label3D.new()
	placa.name = "Placa"
	placa.text = def.nome
	placa.font_size = 26
	placa.outline_size = 10
	placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	placa.visibility_range_end = 16.0
	placa.position = Vector3(0.0, tamanho.y / 2.0 + 0.35, 0.0)
	add_child(placa)


func _tamanho_do_formato(formato: String) -> Vector3:
	match formato:
		"achatado":
			return Vector3(0.9, 0.45, 0.9)
		"alto":
			return Vector3(0.5, 0.9, 0.5)
		_:
			return Vector3(0.7, 0.7, 0.7)


func _criar_olho(pai: Node3D, nome: String, nome_pupila: String, pos: Vector3) -> void:
	var olho := MeshInstance3D.new()
	olho.name = nome
	var branco := QuadMesh.new()
	branco.size = Vector2(0.14, 0.14)
	olho.mesh = branco
	olho.material_override = _criar_material(Color.WHITE, true)
	olho.position = pos
	olho.rotation.y = PI  ## QuadMesh olha pra +Z; a frente do Cubelin é -Z.
	pai.add_child(olho)

	var pupila := MeshInstance3D.new()
	pupila.name = nome_pupila
	var escura := QuadMesh.new()
	escura.size = Vector2(0.07, 0.07)
	pupila.mesh = escura
	pupila.material_override = _criar_material(COR_PUPILA, true)
	pupila.position = Vector3(0.0, 0.0, 0.005)  ## um fio à frente do branco
	olho.add_child(pupila)
	_pupilas.append(pupila)


func _criar_material(cor: Color, sem_sombra: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = cor
	if sem_sombra:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _atualizar_pupilas() -> void:
	## Agressivo à noite olha com pupila vermelha; de dia (ou passivo) escura.
	var vermelha: bool = especie != null and especie.eh_agressivo and GameState.eh_noite()
	var cor: Color = COR_PUPILA_AGRESSIVA if vermelha else COR_PUPILA
	for pupila in _pupilas:
		(pupila.material_override as StandardMaterial3D).albedo_color = cor


func _virar_para_o_movimento(delta: float) -> void:
	var horizontal := Vector2(velocity.x, velocity.z)
	if horizontal.length_squared() < 0.0001:
		return  ## parado mantém a última direção
	var alvo: float = atan2(-velocity.x, -velocity.z)  ## frente é -Z
	rotation.y = lerp_angle(rotation.y, alvo, minf(1.0, VELOCIDADE_GIRO_RAD_S * delta))


func _animar_pulinho(delta: float) -> void:
	## Só o MeshInstance3D sobe e desce; a colisão fica parada.
	_tempo_anim += delta
	var andando: bool = Vector2(velocity.x, velocity.z).length_squared() >= 0.0001
	if andando:
		_mesh.position.y = sin(_tempo_anim * 6.0) * 0.06
	else:
		_mesh.position.y = sin(_tempo_anim * 2.0) * 0.02
