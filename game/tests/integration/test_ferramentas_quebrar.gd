extends GutTest
## Ciclo 8 (8E) no Player: tier insuficiente não quebra e avisa; ferramenta gasta
## 1 de durabilidade por bloco e some ao zerar.

const PlayerScene := preload("res://entities/player/player.tscn")
const POS: Vector3i = Vector3i(3, 40, 3)

var _cm: ChunkManager
var _player: Player


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.hotbar_selecionado = 0
	_cm = ChunkManager.new()
	_cm.world_seed = 1
	add_child_autofree(_cm)
	while _cm.tem_chunks_pendentes():
		_cm._process(0.0)
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)


func test_ferrite_com_picareta_de_madeira_nao_quebra_e_avisa() -> void:
	GameState.inventario_hotbar.adicionar("picareta_madeira", 1)
	_cm.set_block(POS, 11)
	watch_signals(EventBus)

	_player._quebrar_bloco(POS, 100.0)
	_player._quebrar_bloco(POS, 100.0)

	assert_eq(_cm.get_block(POS), 11, "ferrite continua no lugar")
	assert_signal_emit_count(EventBus, "aviso", 1)
	assert_signal_emitted_with_parameters(EventBus, "aviso", ["Precisa de picareta melhor"])
	assert_eq(GameState.inventario_hotbar.get_durabilidade(0), 60, "não gastou")


func test_ferrite_com_picareta_de_pedra_quebra_e_gasta_1() -> void:
	GameState.inventario_hotbar.adicionar("picareta_pedra", 1)
	_cm.set_block(POS, 11)

	_player._quebrar_bloco(POS, 100.0)

	assert_eq(_cm.get_block(POS), BlockRegistry.AR_ID)
	assert_eq(GameState.inventario_hotbar.get_durabilidade(0), 129)


func test_picareta_de_madeira_quebra_apos_60_blocos() -> void:
	GameState.inventario_hotbar.adicionar("picareta_madeira", 1)
	for i in range(59):
		_cm.set_block(POS, 3)
		_player._quebrar_bloco(POS, 100.0)
	assert_false(GameState.inventario_hotbar.slot_vazio(0), "ainda inteira no 59º")
	assert_eq(GameState.inventario_hotbar.get_durabilidade(0), 1)
	_cm.set_block(POS, 3)
	_player._quebrar_bloco(POS, 100.0)
	assert_true(GameState.inventario_hotbar.slot_vazio(0), "quebrou no 60º")


func test_mao_nua_quebra_terra_sem_gastar_nada() -> void:
	_cm.set_block(POS, 2)
	_player._quebrar_bloco(POS, 100.0)
	assert_eq(_cm.get_block(POS), BlockRegistry.AR_ID)
