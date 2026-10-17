extends GutTest
## Frente 5B (docs/superpowers/plans/2026-10-17-ciclos-5-a-9.md): Cubelins com
## olhos, faixa na cor do elemento, pulinho e placa com o nome da espécie. A
## placa é o que diferencia um Pedrolim de um Rochedo de longe.

const CreatureScene := preload("res://entities/creatures/creature.tscn")

var _ciclo_original: float = 0.0


func before_each() -> void:
	_ciclo_original = GameState.ciclo_dia_noite_seg


func after_each() -> void:
	GameState.ciclo_dia_noite_seg = _ciclo_original


func _def(formato: String = "cubo", agressivo: bool = false) -> CreatureDef:
	var def := CreatureDef.new()
	def.nome = "Brotinho"
	def.cor = Color(0.3, 0.7, 0.25)
	def.cor_secundaria = Color(0.31, 0.698, 0.247)
	def.formato = formato
	def.eh_agressivo = agressivo
	def.raio_deteccao = 50.0
	def.velocidade = 3.0
	return def


func _criar(def: CreatureDef) -> Creature:
	var criatura := CreatureScene.instantiate() as Creature
	## Mesma ordem do CreatureSpawner: configurar() antes do add_child.
	criatura.configurar(def)
	add_child_autofree(criatura)
	return criatura


func _tornar_noite() -> void:
	GameState.ciclo_dia_noite_seg = GameState.DURACAO_CICLO_SEG * 0.9


func _cor_da_pupila(criatura: Creature) -> Color:
	var pupila := criatura.find_child("PupilaEsquerda", true, false) as MeshInstance3D
	assert_not_null(pupila, "a pupila esquerda deveria existir")
	if pupila == null:
		return Color.TRANSPARENT
	return (pupila.material_override as StandardMaterial3D).albedo_color


func test_configurar_cria_olhos_faixa_e_placa_com_o_nome() -> void:
	var criatura := _criar(_def())

	assert_not_null(criatura.find_child("OlhoEsquerdo", true, false))
	assert_not_null(criatura.find_child("OlhoDireito", true, false))
	assert_not_null(criatura.find_child("Faixa", true, false))
	var placa := criatura.find_child("Placa", true, false) as Label3D
	assert_not_null(placa, "a placa deveria existir")
	if placa != null:
		assert_eq(placa.text, "Brotinho")
		assert_eq(placa.billboard, BaseMaterial3D.BILLBOARD_ENABLED)


func test_faixa_usa_a_cor_secundaria_do_elemento() -> void:
	var criatura := _criar(_def())

	var faixa := criatura.find_child("Faixa", true, false) as MeshInstance3D
	var material := faixa.material_override as StandardMaterial3D
	assert_eq(material.albedo_color, Color(0.31, 0.698, 0.247))


func test_formato_achatado_gera_caixa_baixa_sem_mudar_a_colisao() -> void:
	var criatura := _criar(_def("achatado"))

	var caixa := (criatura.get_node("MeshInstance3D") as MeshInstance3D).mesh as BoxMesh
	assert_lt(caixa.size.y, 0.5)
	var forma := (criatura.get_node("CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	assert_eq(forma.size, Vector3(0.7, 0.7, 0.7), "colisão continua 0,7³ (ADR-020)")


func test_formato_de_uma_criatura_nao_vaza_para_outra() -> void:
	_criar(_def("achatado"))
	var cubo := _criar(_def("cubo"))

	var caixa := (cubo.get_node("MeshInstance3D") as MeshInstance3D).mesh as BoxMesh
	assert_eq(caixa.size, Vector3(0.7, 0.7, 0.7), "o BoxMesh da cena é compartilhado")


func test_corpo_vira_para_a_direcao_do_movimento() -> void:
	var jogador_falso := Node3D.new()
	jogador_falso.add_to_group("player")
	add_child_autofree(jogador_falso)
	jogador_falso.global_position = Vector3(20.0, 0.0, 0.0)
	## Agressiva com o jogador dentro do raio: anda rumo a ele, em +X.
	var criatura := _criar(_def("cubo", true))
	criatura.global_position = Vector3.ZERO

	for i in range(10):
		criatura._physics_process(0.1)

	assert_gt(criatura.velocity.x, 0.0, "deveria estar andando em +X")
	assert_almost_eq(criatura.rotation.y, -PI / 2.0, 0.05, "olhando pra +X (frente é -Z)")


func test_parado_mantem_a_ultima_direcao() -> void:
	var criatura := _criar(_def())
	criatura.rotation.y = 1.0

	for i in range(10):
		criatura._physics_process(0.1)

	assert_almost_eq(criatura.rotation.y, 1.0, 0.001)


func test_pulinho_mexe_so_o_visual() -> void:
	var jogador_falso := Node3D.new()
	jogador_falso.add_to_group("player")
	add_child_autofree(jogador_falso)
	jogador_falso.global_position = Vector3(20.0, 0.0, 0.0)
	var criatura := _criar(_def("cubo", true))
	var corpo := criatura.get_node("MeshInstance3D") as MeshInstance3D

	for i in range(5):
		criatura._physics_process(1.0 / 60.0)

	assert_ne(corpo.position.y, 0.0, "o visual deveria subir e descer andando")
	assert_lt(absf(corpo.position.y), 0.07)
	var colisao := criatura.get_node("CollisionShape3D") as CollisionShape3D
	assert_eq(colisao.position, Vector3.ZERO, "a colisão não pula")


func test_agressivo_a_noite_tem_pupila_vermelha() -> void:
	_tornar_noite()

	var cor := _cor_da_pupila(_criar(_def("cubo", true)))

	assert_gt(cor.r, 0.7)
	assert_lt(cor.g, 0.3)


func test_passivo_a_noite_tem_pupila_escura() -> void:
	_tornar_noite()

	var cor := _cor_da_pupila(_criar(_def("cubo", false)))

	assert_lt(cor.r, 0.3)


func test_agressivo_de_dia_tem_pupila_escura() -> void:
	GameState.ciclo_dia_noite_seg = GameState.DURACAO_CICLO_SEG * 0.25

	var cor := _cor_da_pupila(_criar(_def("cubo", true)))

	assert_lt(cor.r, 0.3)


func test_pupila_fica_vermelha_quando_a_noite_chega() -> void:
	GameState.ciclo_dia_noite_seg = GameState.DURACAO_CICLO_SEG * 0.25
	var criatura := _criar(_def("cubo", true))
	assert_lt(_cor_da_pupila(criatura).r, 0.3)

	_tornar_noite()
	EventBus.night_started.emit()

	assert_gt(_cor_da_pupila(criatura).r, 0.7)
