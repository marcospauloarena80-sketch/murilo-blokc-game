extends GutTest
## Nome do alvo sob a mira (Ciclo 5, Frente 5E): o HUD lê alvo_mirado e
## alvo_tipo do jogador (grupo "player") e mostra o nome com a dica de tecla
## logo abaixo da mira, só enquanto o jogo está em PLAYING.

const CENA_HUD := preload("res://ui/hud/hud.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")
## Headless a janela tem 64 px de largura; a posição do label precisa da tela do jogo.
const TAMANHO_TELA := Vector2i(1152, 648)

var _tamanho_janela_original: Vector2i
var _player: Player


func before_each() -> void:
	_tamanho_janela_original = get_window().size
	get_window().size = TAMANHO_TELA
	GameState.mudar_estado(GameState.State.PLAYING)


func after_each() -> void:
	get_window().size = _tamanho_janela_original
	GameState.mudar_estado(GameState.State.MENU)


func _montar(alvo: String, tipo: String) -> Hud:
	## Sem ChunkManager o Player fica com a física desligada: o dublê só
	## carrega alvo_mirado/alvo_tipo, que o teste seta direto.
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_player.alvo_mirado = alvo
	_player.alvo_tipo = tipo
	var hud: Hud = CENA_HUD.instantiate()
	add_child_autofree(hud)
	return hud


func test_mostra_nome_da_criatura_com_a_dica_de_desafiar() -> void:
	var hud := _montar("Brotinho", "criatura")

	hud._process(0.0)

	assert_true(hud._label_alvo.visible)
	assert_eq(hud._label_alvo.text, "Brotinho  E desafiar")


func test_dica_por_tipo_npc_e_bloco() -> void:
	var hud := _montar("Professora Lina", "npc")
	hud._process(0.0)
	assert_eq(hud._label_alvo.text, "Professora Lina  E falar")

	_player.alvo_mirado = "Pedra"
	_player.alvo_tipo = "bloco"
	hud._process(0.0)
	assert_eq(hud._label_alvo.text, "Pedra  Q quebrar")


func test_sem_alvo_o_label_fica_invisivel() -> void:
	var hud := _montar("Brotinho", "criatura")
	hud._process(0.0)
	assert_true(hud._label_alvo.visible, "pré-condição: com alvo o label aparece")

	_player.alvo_mirado = ""
	_player.alvo_tipo = ""
	hud._process(0.0)

	assert_false(hud._label_alvo.visible)


func test_fora_de_playing_o_label_some_mesmo_com_alvo() -> void:
	var hud := _montar("Brotinho", "criatura")
	GameState.mudar_estado(GameState.State.PAUSED)

	hud._process(0.0)

	assert_false(hud._label_alvo.visible, "pausado, o nome não pode ficar por cima dos menus")


func test_label_fica_centrado_logo_abaixo_da_mira() -> void:
	var hud := _montar("Brotinho", "criatura")
	hud._process(0.0)
	await get_tree().process_frame
	await get_tree().process_frame

	var rect: Rect2 = hud._label_alvo.get_global_rect()
	var centro: Vector2 = get_viewport().get_visible_rect().size / 2.0
	assert_almost_eq(rect.get_center().x, centro.x, 4.0, "centrado na largura")
	assert_almost_eq(rect.position.y, centro.y + 28.0, 4.0, "~28 px abaixo do centro")
	assert_gt(rect.position.y, hud._mira.get_global_rect().end.y - 4.0, "abaixo da mira")
