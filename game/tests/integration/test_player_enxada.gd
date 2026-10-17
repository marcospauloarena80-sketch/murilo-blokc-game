extends GutTest
## Horta e blocos em cruz no Player (Ciclo 8, frente 8A): a mira acerta bloco em
## cruz (sem colisão) com física de verdade, a enxada ara grama e terra, e a
## semente só planta em terra arada. Mesmo cenário de test_player_alvo_mirado.gd.

const PlayerScene := preload("res://entities/player/player.tscn")
## O braço da câmera sobe 5° fixos e a câmera olha 5° pra baixo (player.tscn);
## com o pivô girado em +5° o raio sai horizontal, 1,2 acima do centro do
## jogador e 0,55 à direita (ombro).
const INCLINACAO_BRACO: float = 0.0872665
const POSICAO_JOGADOR := Vector3(20.5, 58.0, 20.5)
const MUDA: int = 17
const TRIGO_1: int = 19
const TERRA_ARADA: int = 22

var _cm: ChunkManager
var _player: Player


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.hotbar_selecionado = 0
	_cm = ChunkManager.new()
	_cm.world_seed = 1
	add_child_autofree(_cm)
	_drenar()
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_player.set_physics_process(false)
	_player.global_position = POSICAO_JOGADOR
	_player.camera_pivot.rotation.x = INCLINACAO_BRACO


func after_each() -> void:
	Input.action_release("quebrar")
	Input.action_release("interagir")
	Input.action_release("colocar")


func _drenar() -> void:
	while _cm.tem_chunks_pendentes():
		_cm._process(0.0)


func _ceu_limpo(centro: Vector3i, raio: int, de_y: int, ate_y: int) -> void:
	## Ar nos andares de_y..ate_y em volta de centro (o terreno pode subir até aí).
	for dx in range(-raio, raio + 1):
		for dz in range(-raio, raio + 1):
			for y in range(de_y, ate_y + 1):
				_cm.trocar_bloco_sem_evento(Vector3i(centro.x + dx, y, centro.z + dz), 0)


func test_mira_acerta_bloco_em_cruz_sem_colisao() -> void:
	_ceu_limpo(Vector3i(20, 0, 18), 3, 55, 62)
	## Uma muda onde o raio horizontal passa, 3 blocos à frente (jogador olha -Z).
	var alvo := Vector3i(21, 59, 17)
	_cm.trocar_bloco_sem_evento(alvo, MUDA)
	_drenar()
	await wait_physics_frames(3)

	_player._processar_mira_e_interacao(0.0)

	assert_eq(_player.alvo_tipo, "bloco")
	assert_eq(_player.alvo_mirado, "Muda")


func test_quebrar_muda_mirada_remove_o_bloco() -> void:
	_ceu_limpo(Vector3i(20, 0, 18), 3, 55, 62)
	var alvo := Vector3i(21, 59, 17)
	_cm.trocar_bloco_sem_evento(alvo, MUDA)
	_drenar()
	await wait_physics_frames(3)
	_player.set_physics_process(false)
	## Dureza 0,05: um quadro segurando "quebrar" basta.
	Input.action_press("quebrar")
	_player._processar_mira_e_interacao(0.2)
	Input.action_release("quebrar")

	assert_eq(_cm.get_block(alvo), 0, "muda quebrada")


func test_cruz_atras_de_parede_nao_e_mirada() -> void:
	_ceu_limpo(Vector3i(20, 0, 17), 4, 55, 62)
	## Parede de pedra em z=17 e muda atrás dela em z=15: mira fica na pedra.
	for dx in range(-2, 4):
		for dy in range(-3, 4):
			_cm.trocar_bloco_sem_evento(Vector3i(20 + dx, 59 + dy, 17), 3)
	_cm.trocar_bloco_sem_evento(Vector3i(21, 59, 15), MUDA)
	_drenar()
	await wait_physics_frames(3)

	_player._processar_mira_e_interacao(0.0)

	assert_eq(_player.alvo_mirado, "Pedra")


func test_mira_no_cubo_continua_igual_sem_cruz_no_caminho() -> void:
	_ceu_limpo(Vector3i(20, 0, 18), 3, 55, 62)
	for dx in range(-2, 3):
		for dy in range(-5, 3):
			_cm.trocar_bloco_sem_evento(Vector3i(20 + dx, 58 + dy, 17), 3)
	_drenar()
	await wait_physics_frames(3)

	_player._processar_mira_e_interacao(0.0)

	assert_eq(_player.alvo_mirado, "Pedra")


func test_enxada_ara_grama_e_terra() -> void:
	GameState.inventario_hotbar.adicionar("enxada_madeira", 1)
	var celula := Vector3i(20, 50, 20)
	_ceu_limpo(celula, 1, 51, 53)
	for id: int in [1, 2]:
		_cm.trocar_bloco_sem_evento(celula, id)
		assert_true(_player._tentar_arar(celula, id), "ara bloco %d" % id)
		assert_eq(_cm.get_block(celula), TERRA_ARADA)


func test_enxada_nao_ara_pedra_nem_com_bloco_em_cima() -> void:
	GameState.inventario_hotbar.adicionar("enxada_madeira", 1)
	var celula := Vector3i(20, 50, 20)
	_ceu_limpo(celula, 1, 51, 53)
	_cm.trocar_bloco_sem_evento(celula, 3)
	assert_false(_player._tentar_arar(celula, 3))
	_cm.trocar_bloco_sem_evento(celula, 1)
	_cm.trocar_bloco_sem_evento(celula + Vector3i.UP, 3)
	assert_false(_player._tentar_arar(celula, 1), "bloco em cima impede")
	assert_eq(_cm.get_block(celula), 1)


func test_sem_enxada_nao_ara() -> void:
	GameState.inventario_hotbar.adicionar("tabua", 3)
	var celula := Vector3i(20, 50, 20)
	_ceu_limpo(celula, 1, 51, 53)
	_cm.trocar_bloco_sem_evento(celula, 1)
	assert_false(_player._tentar_arar(celula, 1))
	assert_eq(_cm.get_block(celula), 1)


func test_ararar_nao_conta_como_bloco_colocado() -> void:
	GameState.inventario_hotbar.adicionar("enxada_madeira", 1)
	var colocados: Array = []
	var ao_colocar := func(pos: Vector3i, _id: int) -> void: colocados.append(pos)
	EventBus.block_placed.connect(ao_colocar)
	var celula := Vector3i(20, 50, 20)
	_ceu_limpo(celula, 1, 51, 53)
	_cm.trocar_bloco_sem_evento(celula, 1)
	_player._tentar_arar(celula, 1)
	EventBus.block_placed.disconnect(ao_colocar)
	assert_eq(colocados.size(), 0)


func test_semente_so_planta_em_terra_arada() -> void:
	GameState.inventario_hotbar.adicionar("semente", 2)
	var chao := Vector3i(20, 50, 20)
	_ceu_limpo(chao, 1, 51, 53)
	_cm.trocar_bloco_sem_evento(chao, 1)  # grama
	_player._tentar_colocar_bloco(chao + Vector3i.UP)
	assert_eq(_cm.get_block(chao + Vector3i.UP), 0, "grama não serve")
	assert_eq(GameState.inventario_hotbar.contar("semente"), 2, "semente não foi gasta")
	_cm.trocar_bloco_sem_evento(chao, TERRA_ARADA)
	_player._tentar_colocar_bloco(chao + Vector3i.UP)
	assert_eq(_cm.get_block(chao + Vector3i.UP), TRIGO_1)
	assert_eq(GameState.inventario_hotbar.contar("semente"), 1)


func test_muda_planta_em_grama() -> void:
	GameState.inventario_hotbar.adicionar("muda", 1)
	var chao := Vector3i(20, 50, 20)
	_ceu_limpo(chao, 1, 51, 53)
	_cm.trocar_bloco_sem_evento(chao, 1)
	_player._tentar_colocar_bloco(chao + Vector3i.UP)
	assert_eq(_cm.get_block(chao + Vector3i.UP), MUDA)
