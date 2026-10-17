extends GutTest
## Crescimento das plantas (Ciclo 8, frente 8A) com tempo injetado: muda vira
## árvore, trigo passa pelos 3 estágios, planta longe do jogador não cresce,
## drops extras do LootSpawner. ChunkManager real, filas drenadas.

const MUDA: int = 17
const TRIGO_1: int = 19
const TRIGO_2: int = 20
const TRIGO_3: int = 21
const TERRA_ARADA: int = 22
const TRONCO: int = 4
const FOLHAS: int = 5
const BASE := Vector3i(20, 40, 20)

var _cm: ChunkManager
var _crescimento: Crescimento
var _jogador: Node3D


func before_each() -> void:
	_cm = ChunkManager.new()
	_cm.world_seed = 1
	add_child_autofree(_cm)
	while _cm.tem_chunks_pendentes():
		_cm._process(0.0)
	## Limpa o ar em volta (o terreno pode passar de y=40) e põe um piso de teste.
	for dx in range(-3, 4):
		for dz in range(-3, 4):
			for y in range(BASE.y - 1, BASE.y + 12):
				_cm.trocar_bloco_sem_evento(BASE + Vector3i(dx, y - BASE.y, dz), 0)
			_cm.trocar_bloco_sem_evento(BASE + Vector3i(dx, -1, dz), TERRA_ARADA)
	_jogador = Node3D.new()
	_jogador.add_to_group("player")
	add_child_autofree(_jogador)
	_jogador.global_position = Vector3(BASE)
	_crescimento = Crescimento.new()
	_crescimento.chunk_manager = _cm
	add_child_autofree(_crescimento)


func test_muda_vira_arvore_com_tempo_acelerado() -> void:
	_cm.trocar_bloco_sem_evento(BASE, MUDA)
	_crescimento.avancar(BlockRegistry.get_block(MUDA).tempo_crescimento_seg + 4.0)
	for i in range(4):
		assert_eq(_cm.get_block(BASE + Vector3i(0, i, 0)), TRONCO, "tronco no andar %d" % i)
	assert_eq(_cm.get_block(BASE + Vector3i(1, 3, 0)), FOLHAS, "folhas em volta do topo")
	assert_eq(_cm.get_block(BASE + Vector3i(0, 5, 0)), FOLHAS, "folha no alto")
	assert_eq(_cm.get_block(BASE + Vector3i(0, 6, 0)), 0, "só isso")


func test_muda_nao_cresce_antes_do_tempo() -> void:
	_cm.trocar_bloco_sem_evento(BASE, MUDA)
	_crescimento.avancar(BlockRegistry.get_block(MUDA).tempo_crescimento_seg - 10.0)
	assert_eq(_cm.get_block(BASE), MUDA)
	assert_gt(_crescimento.tempo_acumulado(BASE), 0.0)


func test_arvore_entra_no_save_como_edicao() -> void:
	_cm.trocar_bloco_sem_evento(BASE, MUDA)
	_crescimento.avancar(BlockRegistry.get_block(MUDA).tempo_crescimento_seg + 4.0)
	var delta := _cm.exportar_delta()
	assert_eq(delta["%d,%d,%d" % [BASE.x, BASE.y, BASE.z]], TRONCO)
	assert_eq(delta["%d,%d,%d" % [BASE.x, BASE.y + 5, BASE.z]], FOLHAS)


func test_muda_com_teto_sobre_o_tronco_espera() -> void:
	_cm.trocar_bloco_sem_evento(BASE, MUDA)
	_cm.trocar_bloco_sem_evento(BASE + Vector3i(0, 2, 0), 3)  # pedra no caminho
	_crescimento.avancar(BlockRegistry.get_block(MUDA).tempo_crescimento_seg + 4.0)
	assert_eq(_cm.get_block(BASE), MUDA, "muda continua esperando")
	assert_eq(_cm.get_block(BASE + Vector3i(0, 2, 0)), 3, "pedra intacta")


func test_trigo_avanca_tres_estagios() -> void:
	_cm.trocar_bloco_sem_evento(BASE, TRIGO_1)
	_crescimento.avancar(BlockRegistry.get_block(TRIGO_1).tempo_crescimento_seg + 2.0)
	assert_eq(_cm.get_block(BASE), TRIGO_2)
	_crescimento.avancar(BlockRegistry.get_block(TRIGO_2).tempo_crescimento_seg + 2.0)
	assert_eq(_cm.get_block(BASE), TRIGO_3)
	_crescimento.avancar(100000.0)
	assert_eq(_cm.get_block(BASE), TRIGO_3, "maduro fica maduro")


func test_trocar_bloco_sem_evento_nao_emite_nada() -> void:
	var emitidos: Array = []
	var ao_colocar := func(pos: Vector3i, id: int) -> void: emitidos.append([pos, id])
	EventBus.block_placed.connect(ao_colocar)
	_cm.trocar_bloco_sem_evento(BASE, TRIGO_1)
	_crescimento.avancar(BlockRegistry.get_block(TRIGO_1).tempo_crescimento_seg + 2.0)
	EventBus.block_placed.disconnect(ao_colocar)
	assert_eq(emitidos.size(), 0, "crescer não conta como construir")


func test_planta_longe_do_jogador_nao_cresce() -> void:
	_cm.trocar_bloco_sem_evento(BASE, TRIGO_1)
	_jogador.global_position = Vector3(BASE) + Vector3(16.0 * 4, 0.0, 0.0)  # 4 chunks
	_crescimento.avancar(1000.0)
	assert_eq(_cm.get_block(BASE), TRIGO_1)


func test_planta_quebrada_e_replantada_comeca_do_zero() -> void:
	_cm.trocar_bloco_sem_evento(BASE, TRIGO_1)
	_crescimento.avancar(50.0)
	assert_gt(_crescimento.tempo_acumulado(BASE), 40.0)
	_cm.trocar_bloco_sem_evento(BASE, 0)
	_crescimento.avancar(2.0)
	_cm.trocar_bloco_sem_evento(BASE, TRIGO_1)
	_crescimento.avancar(2.0)
	assert_lt(_crescimento.tempo_acumulado(BASE), 5.0)


func test_muitas_plantas_crescem_todas_em_rodizio() -> void:
	var posicoes: Array[Vector3i] = []
	for dx in range(-3, 4):
		for dz in range(-3, 4):
			posicoes.append(BASE + Vector3i(dx, 0, dz))
	## 49 plantas > 40 por passo: o rodízio ainda leva todas ao estágio 2.
	for pos: Vector3i in posicoes:
		_cm.trocar_bloco_sem_evento(pos, TRIGO_1)
	_crescimento.avancar(BlockRegistry.get_block(TRIGO_1).tempo_crescimento_seg * 3.0)
	for pos: Vector3i in posicoes:
		assert_ne(_cm.get_block(pos), TRIGO_1, "planta em %s ficou parada" % pos)


func test_trigo_maduro_dropa_trigo_e_sementes() -> void:
	var spawner := LootSpawner.new()
	spawner.rng.seed = 7
	add_child_autofree(spawner)
	EventBus.block_broken.emit(BASE, TRIGO_3)
	var itens: Dictionary = {}
	for filho: Node in spawner.get_children():
		var drop := filho as ItemDrop
		itens[drop.item_id] = int(itens.get(drop.item_id, 0)) + drop.quantidade
	assert_eq(itens.get("trigo", 0), 1)
	assert_between(int(itens.get("semente", 0)), 1, 2)


func test_folhas_dropam_muda_em_quinze_por_cento_das_vezes() -> void:
	var spawner := LootSpawner.new()
	spawner.rng.seed = 123
	add_child_autofree(spawner)
	var mudas: int = 0
	var rodadas: int = 400
	for i in range(rodadas):
		EventBus.block_broken.emit(BASE, FOLHAS)
	for filho: Node in spawner.get_children():
		if (filho as ItemDrop).item_id == "muda":
			mudas += 1
	assert_between(mudas, int(rodadas * 0.15 * 0.6), int(rodadas * 0.15 * 1.4))
