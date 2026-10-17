extends GutTest
## Ciclo 8 (Frente 8C): portas de dois blocos. Interagir (E) alterna aberta e
## fechada nos dois blocos, colocar põe os dois e quebrar tira os dois. Usa o
## main.tscn (padrão de test_player_cama.gd).

const MainScene := preload("res://scenes/main.tscn")
const BASE := Vector3i(5, 40, 5)
const TOPO := Vector3i(5, 41, 5)

var _cm: ChunkManager
var _player: Player


func before_each() -> void:
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.hotbar_selecionado = 0
	var principal := MainScene.instantiate() as Node3D
	add_child_autofree(principal)
	_cm = principal.get_node("ChunkManager")
	while _cm.tem_chunks_pendentes():
		_cm._process(0.0)
	_player = principal._player
	_player.global_position = Vector3(60, 80, 60)  # longe do bloco testado


func _montar_porta() -> void:
	_cm.set_block(BASE, BlockRegistry.PORTA_FECHADA_ID)
	_cm.set_block(TOPO, BlockRegistry.PORTA_TOPO_ID)


func test_interagir_na_porta_alterna_os_dois_blocos() -> void:
	_montar_porta()
	_player._processar_interacao(BASE)
	assert_eq(_cm.get_block(BASE), BlockRegistry.PORTA_ABERTA_ID)
	assert_eq(_cm.get_block(TOPO), BlockRegistry.PORTA_TOPO_ID, "topo continua topo")
	_player._processar_interacao(BASE)
	assert_eq(_cm.get_block(BASE), BlockRegistry.PORTA_FECHADA_ID)


func test_interagir_no_topo_alterna_o_bloco_de_baixo() -> void:
	_montar_porta()
	_player._processar_interacao(TOPO)
	assert_eq(_cm.get_block(BASE), BlockRegistry.PORTA_ABERTA_ID)


func test_alternar_porta_nao_conta_como_colocar_bloco() -> void:
	_montar_porta()
	watch_signals(EventBus)
	_player._processar_interacao(BASE)
	assert_signal_not_emitted(EventBus, "block_placed")
	assert_signal_not_emitted(EventBus, "block_broken")


func test_colocar_porta_poe_base_e_topo_e_gasta_um() -> void:
	GameState.inventario_hotbar.adicionar("porta", 2)
	_player._tentar_colocar_bloco(BASE)
	assert_eq(_cm.get_block(BASE), BlockRegistry.PORTA_FECHADA_ID)
	assert_eq(_cm.get_block(TOPO), BlockRegistry.PORTA_TOPO_ID)
	assert_eq(GameState.inventario_hotbar.contar("porta"), 1)


func test_colocar_porta_sem_espaco_em_cima_nao_faz_nada() -> void:
	GameState.inventario_hotbar.adicionar("porta", 1)
	_cm.set_block(TOPO, 3)
	_player._tentar_colocar_bloco(BASE)
	assert_eq(_cm.get_block(BASE), BlockRegistry.AR_ID)
	assert_eq(GameState.inventario_hotbar.contar("porta"), 1)


func test_quebrar_uma_metade_tira_a_porta_inteira() -> void:
	_montar_porta()
	_player._remover_bloco(TOPO)
	assert_eq(_cm.get_block(TOPO), BlockRegistry.AR_ID)
	assert_eq(_cm.get_block(BASE), BlockRegistry.AR_ID)
	_montar_porta()
	_player._remover_bloco(BASE)
	assert_eq(_cm.get_block(TOPO), BlockRegistry.AR_ID)
	assert_eq(_cm.get_block(BASE), BlockRegistry.AR_ID)
