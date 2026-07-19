extends GutTest
## Ver docs/01-GDD.md (baú) e docs/07-DECISOES.md ADR-018 — baú persistido no
## mundo, aberto via "interagir" (E), transferência bidirecional com a mochila.

const ChestScreenScene := preload("res://ui/chest_screen/chest_screen.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")


func before_each() -> void:
	GameState.baus = {}
	GameState.inventario_mochila = InventoryModel.new(24)


func after_each() -> void:
	GameState.baus = {}


func test_interagir_com_bau_emite_chest_requested_com_chave_certa() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 44
	add_child_autofree(cm)

	var pos := Vector3i(7, 40, 7)
	cm.set_block(pos, 8)  # id do baú

	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	var recebido: Array = [""]
	var callback := func(chave: String) -> void: recebido[0] = chave
	EventBus.chest_requested.connect(callback)

	player._processar_interacao(pos)

	EventBus.chest_requested.disconnect(callback)
	assert_eq(recebido[0], GameState.chave_posicao(pos))


func test_abrir_pausa_o_jogo_e_mostra_a_tela() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)
	var tela := ChestScreenScene.instantiate() as ChestScreen
	add_child_autofree(tela)

	tela._abrir("1,2,3")

	assert_true(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PAUSED)


func test_fechar_despausa_o_jogo_e_esconde_a_tela() -> void:
	var tela := ChestScreenScene.instantiate() as ChestScreen
	add_child_autofree(tela)
	tela._abrir("1,2,3")

	tela._fechar()

	assert_false(tela.visible)
	assert_eq(GameState.current_state, GameState.State.PLAYING)


func test_clicar_slot_do_bau_move_stack_pra_mochila() -> void:
	var chave := "4,5,6"
	GameState.obter_bau(chave).adicionar("pedra", 3)
	var tela := ChestScreenScene.instantiate() as ChestScreen
	add_child_autofree(tela)
	tela._abrir(chave)

	tela._ao_clicar_bau(0)

	assert_eq(GameState.inventario_mochila.contar("pedra"), 3)
	assert_true(GameState.obter_bau(chave).slot_vazio(0))


func test_clicar_slot_da_mochila_move_stack_pro_bau() -> void:
	var chave := "7,8,9"
	GameState.inventario_mochila.adicionar("tronco", 2)
	var tela := ChestScreenScene.instantiate() as ChestScreen
	add_child_autofree(tela)
	tela._abrir(chave)

	tela._ao_clicar_mochila(0)

	assert_eq(GameState.obter_bau(chave).contar("tronco"), 2)
	assert_true(GameState.inventario_mochila.slot_vazio(0))


func test_clicar_slot_vazio_nao_faz_nada() -> void:
	var chave := "10,11,12"
	var tela := ChestScreenScene.instantiate() as ChestScreen
	add_child_autofree(tela)
	tela._abrir(chave)

	tela._ao_clicar_bau(0)
	tela._ao_clicar_mochila(0)

	assert_true(GameState.obter_bau(chave).slot_vazio(0))
	assert_true(GameState.inventario_mochila.slot_vazio(0))
