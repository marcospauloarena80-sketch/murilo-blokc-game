extends GutTest
## Cubelin companheiro no mundo (Ciclo 9, 9C): main.tscn de verdade, mundo
## gerado e física real (mesmo padrão de test_creature_world_physics.gd).

const MainScene := preload("res://scenes/main.tscn")
const QUADRO: float = 1.0 / 60.0

var _main: Node3D
var _jogador: Player


func before_each() -> void:
	GameState.reiniciar_para_novo_jogo()
	GameState.mudar_estado(GameState.State.PLAYING)


func after_each() -> void:
	GameState.reiniciar_para_novo_jogo()
	GameState.mudar_estado(GameState.State.BOOT)


func _montar(com_brasita: bool) -> Companheiro:
	if com_brasita:
		GameState.equipe_cubelins = [CreatureInstance.new("brasita", 4)]
	_main = MainScene.instantiate()
	add_child_autofree(_main)
	var cm: ChunkManager = _main.get_node("ChunkManager")
	while cm.tem_chunks_pendentes():
		cm._process(0.0)
	_jogador = _main.get_node("Player")
	return _main.get_node("Companheiro") as Companheiro


func _rodar(quadros: int, companheiro: Companheiro) -> void:
	for i in range(quadros):
		if is_instance_valid(companheiro.criatura):
			companheiro.criatura._physics_process(QUADRO)
		await wait_physics_frames(1)


## Faixa plana de pedra e ar em -Z do jogador (nos eixos X ficam NPCs do Vilarejo),
## pra o teste não depender do relevo.
func _aplanar_corredor() -> void:
	var cm: ChunkManager = _main.get_node("ChunkManager")
	var base := Vector3i(_jogador.global_position.floor())
	for dx in range(-2, 3):
		for dz in range(-14, 3):
			cm.set_block(base + Vector3i(dx, -1, dz), 3)
			for dy in range(0, 4):
				cm.set_block(base + Vector3i(dx, dy, dz), BlockRegistry.AR_ID)
	while cm.tem_chunks_pendentes():
		cm._process(0.0)


func test_equipe_vazia_nao_tem_companheiro() -> void:
	var companheiro := _montar(false)
	assert_null(companheiro.criatura)
	assert_eq(get_tree().get_nodes_in_group("companheiro").size(), 0)


func test_com_brasita_cria_criatura_no_grupo_companheiro() -> void:
	var companheiro := _montar(true)
	assert_not_null(companheiro.criatura)
	assert_true(companheiro.criatura.is_in_group("companheiro"))
	assert_false(companheiro.criatura.is_in_group("creature"), "spawner e batalha não enxergam")
	assert_eq(companheiro.criatura.especie.especie_id, "brasita")


func test_team_changed_refaz_o_companheiro() -> void:
	var companheiro := _montar(false)
	GameState.adicionar_cubelin(CreatureInstance.new("ventim", 2))
	assert_not_null(companheiro.criatura)
	assert_eq(companheiro.criatura.especie.especie_id, "ventim")
	GameState.equipe_cubelins.clear()
	EventBus.team_changed.emit()
	await wait_frames(2)  # queue_free do anterior
	assert_null(companheiro.criatura)
	assert_eq(get_tree().get_nodes_in_group("companheiro").size(), 0)


func test_companheiro_sem_dano_de_contato_nem_dano_do_jogador() -> void:
	var companheiro := _montar(true)
	var amigo: Creature = companheiro.criatura
	var vida_jogador: int = GameState.vida_atual
	amigo._ao_tocar_jogador(_jogador)
	assert_eq(GameState.vida_atual, vida_jogador)
	var vida: int = amigo.vida_atual
	amigo.receber_dano(99)
	assert_true(is_instance_valid(amigo))
	assert_eq(amigo.vida_atual, vida)


func test_aviso_mostra_nome_nivel_e_vida() -> void:
	var companheiro := _montar(true)
	var cubelin: CreatureInstance = GameState.equipe_cubelins[0]
	var texto: String = companheiro.criatura.texto_aviso()
	assert_eq(
		texto, "%s Nv.4  %d/%d" % ["Brasita", cubelin.vida_atual, cubelin.vida_maxima_efetiva()]
	)


func test_a_30_blocos_teleporta_para_perto() -> void:
	var companheiro := _montar(true)
	await wait_physics_frames(5)
	var amigo: Creature = companheiro.criatura
	amigo.global_position = _jogador.global_position + Vector3(30, 0, 0)
	await _rodar(3, companheiro)
	var distancia: float = amigo.global_position.distance_to(_jogador.global_position)
	assert_lt(distancia, 8.0, "deveria ter teleportado, distância %.1f" % distancia)


func test_segue_o_jogador_de_longe_ate_a_faixa() -> void:
	var companheiro := _montar(true)
	for i in range(600):  # o jogador nasce no ar e cai até o chão
		if _jogador.is_on_floor():
			break
		await wait_physics_frames(1)
	assert_true(_jogador.is_on_floor(), "jogador deveria ter pousado")
	var amigo: Creature = companheiro.criatura
	_aplanar_corredor()
	amigo.global_position = _jogador.global_position + Vector3(0, 0.5, -10)
	var antes: float = amigo.global_position.distance_to(_jogador.global_position)
	await _rodar(240, companheiro)
	var depois: float = amigo.global_position.distance_to(_jogador.global_position)
	assert_lt(
		depois,
		CreatureBehavior.DIST_SEGUIR_MAX + 0.5,
		"deveria ter se aproximado (%.1f -> %.1f)" % [antes, depois]
	)
	assert_gt(amigo.global_position.y, 0.0)
