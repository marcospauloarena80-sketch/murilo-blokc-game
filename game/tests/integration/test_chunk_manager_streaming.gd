extends GutTest
## Ver docs/07-DECISOES.md ADR-026 — achados jogando o build real: o chunk do
## jogador era o 36º de 64 (entrada no mundo travava) e reaplicar o save pelo
## set_block dropava de novo cada bloco minerado a cada Continuar.

var _eventos_de_jogo: Array[int] = [0]


func after_each() -> void:
	GameState.veio_de_continuar = false


func _contar_evento(_pos: Vector3i, _id: int) -> void:
	_eventos_de_jogo[0] += 1


func test_chunk_central_e_o_primeiro_a_ficar_pronto() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)
	var prontos: Array[Vector2i] = []
	cm.chunk_pronto.connect(func(coord: Vector2i) -> void: prontos.append(coord))

	while prontos.is_empty():
		cm._process(0.0)

	assert_eq(prontos[0], Vector2i(4, 4), "sem jogador, o centro do mundo é o primeiro da fila")


func test_area_inicial_fica_pronta_antes_do_mundo_inteiro() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)
	var ainda_carregando_quando_area_ficou_pronta := false

	while cm.tem_chunks_pendentes():
		cm._process(0.0)
		if cm.area_pronta and cm.tem_chunks_pendentes():
			ainda_carregando_quando_area_ficou_pronta = true
			break

	assert_true(cm.area_pronta)
	assert_true(
		ainda_carregando_quando_area_ficou_pronta,
		"o jogador é liberado antes do mundo inteiro terminar de carregar"
	)


func test_aplicar_delta_antes_de_gerar_nao_emite_eventos_de_jogo() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 3
	add_child_autofree(cm)
	EventBus.block_broken.connect(_contar_evento)
	EventBus.block_placed.connect(_contar_evento)
	_eventos_de_jogo[0] = 0

	cm.aplicar_delta({"5,40,5": 3, "6,40,6": BlockRegistry.AR_ID})
	while cm.tem_chunks_pendentes():
		cm._process(0.0)

	EventBus.block_broken.disconnect(_contar_evento)
	EventBus.block_placed.disconnect(_contar_evento)
	assert_eq(cm.get_block(Vector3i(5, 40, 5)), 3)
	assert_eq(cm.get_block(Vector3i(6, 40, 6)), BlockRegistry.AR_ID)
	assert_eq(_eventos_de_jogo[0], 0, "carregar o save não pode dropar item nem contar missão")


func test_delta_carregado_ja_entra_no_proximo_save() -> void:
	## Salvar enquanto o mundo ainda carrega não pode apagar as edições salvas.
	var cm := ChunkManager.new()
	cm.world_seed = 3
	add_child_autofree(cm)

	cm.aplicar_delta({"5,40,5": 3})

	assert_true(cm.exportar_delta().has("5,40,5"))


func test_fora_do_mundo_nao_bloqueia_movimento() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)

	assert_true(cm.chunk_pronto_em(Vector3(-50, 0, -50)))
	assert_false(cm.chunk_pronto_em(Vector3(72, 0, 72)), "nada carregado antes do 1º frame")
