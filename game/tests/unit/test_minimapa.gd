extends GutTest
## Minimapa (Ciclo 8, 8D): textura 64 x 64, marcadores e tecla M.

var _mapa: Minimapa


func before_each() -> void:
	_mapa = Minimapa.new()
	add_child_autofree(_mapa)
	_mapa.centro_forcado = Vector2i(64, 64)
	_mapa.atualizar_completo()


func after_each() -> void:
	GameState.mudar_estado(GameState.State.MENU)


func test_textura_64_por_64() -> void:
	assert_eq(_mapa.texture.get_width(), 64)
	assert_eq(_mapa.texture.get_height(), 64)
	assert_eq(_mapa.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)


func test_pixel_central_e_branco() -> void:
	assert_eq(_mapa.pixel(32, 32), Color.WHITE)


func test_marcador_do_vilarejo_na_posicao_esperada() -> void:
	## Jogador no centro do vilarejo: o marcador dourado cai no pixel central,
	## então desloca o jogador para ver o vilarejo em outro pixel.
	var cama_original := GameState.ponto_respawn
	GameState.ponto_respawn = Vector3(30, 45, 30)  ## cama longe do vilarejo
	_mapa.centro_forcado = Vector2i(64 - 20, 64)
	_mapa.atualizar_completo()
	GameState.ponto_respawn = cama_original
	assert_eq(_mapa.pixel_do_mundo(64, 64), Vector2i(42, 32))
	assert_eq(_mapa.pixel(42, 32), Minimapa.COR_VILAREJO)
	assert_eq(_mapa.pixel(32, 32), Color.WHITE)
	var pixel_cama := _mapa.pixel_do_mundo(30, 30)
	assert_eq(_mapa.pixel(pixel_cama.x, pixel_cama.y), Minimapa.COR_CAMA)


func test_fora_do_mundo_e_preto_e_nao_carregado_e_cinza() -> void:
	_mapa.centro_forcado = Vector2i(0, 0)
	_mapa.atualizar_completo()
	assert_eq(_mapa.pixel(0, 0), Color.BLACK)
	assert_eq(_mapa.pixel(40, 40), Minimapa.COR_NAO_CARREGADO)


func test_m_alterna_tamanho() -> void:
	GameState.mudar_estado(GameState.State.PLAYING)
	_mapa._process(0.0)
	assert_eq(_mapa.tamanho_atual(), 160.0)
	var evento := InputEventAction.new()
	evento.action = "mapa"
	evento.pressed = true
	_mapa._unhandled_input(evento)
	assert_eq(_mapa.tamanho_atual(), 320.0)
	assert_eq(_mapa.offset_bottom - _mapa.offset_top, 320.0)
	_mapa._unhandled_input(evento)
	assert_eq(_mapa.tamanho_atual(), 160.0)


func test_so_visivel_jogando() -> void:
	GameState.mudar_estado(GameState.State.MENU)
	_mapa._process(0.0)
	assert_false(_mapa.visible)
	GameState.mudar_estado(GameState.State.PLAYING)
	_mapa._process(0.0)
	assert_true(_mapa.visible)


func test_calculo_em_fatias_de_16_linhas() -> void:
	_mapa.iniciar_passada()
	_mapa._calcular_linhas(Minimapa.LINHAS_POR_QUADRO)
	assert_eq(_mapa._linha, 16)
