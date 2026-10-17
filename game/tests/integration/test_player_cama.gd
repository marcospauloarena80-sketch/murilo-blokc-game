extends GutTest
## Ciclo 6 (Frente 6E): a cama à noite faz dormir — o Player emite
## EventBus.player_slept e o main.gd amanhece (ciclo 0), cura 4 e avisa
## "Bom dia!" com um fade preto; de dia a cama só marca o respawn e avisa.
## Instancia main.tscn porque é o main.gd que reage ao sinal (padrão de
## test_death_and_bed.gd).

const MainScene := preload("res://scenes/main.tscn")
const ID_BLOCO_CAMA: int = 7  # data/blocks/cama.tres
const POS_CAMA := Vector3i(5, 40, 5)
const CICLO_NOITE: float = GameState.DURACAO_CICLO_SEG * 0.9
const CICLO_DIA: float = GameState.DURACAO_CICLO_SEG * 0.25

var _ciclo_original: float


func before_each() -> void:
	_ciclo_original = GameState.ciclo_dia_noite_seg
	GameState.vida_atual = GameState.vida_maxima
	GameState.ponto_respawn = Vector3(64, 45, 64)


func after_each() -> void:
	GameState.ciclo_dia_noite_seg = _ciclo_original
	GameState.vida_atual = GameState.vida_maxima
	GameState.ponto_respawn = Vector3(64, 45, 64)


func _criar_main_com_cama() -> Node3D:
	var main_instance := MainScene.instantiate() as Node3D
	add_child_autofree(main_instance)
	var cm: ChunkManager = main_instance.get_node("ChunkManager")
	## Geração de chunk é time-sliced (ADR-026): o chunk precisa existir antes
	## do set_block da cama.
	while cm.tem_chunks_pendentes():
		cm._process(0.0)
	cm.set_block(POS_CAMA, ID_BLOCO_CAMA)
	return main_instance


func test_a_noite_interagir_na_cama_emite_player_slept_e_amanhece() -> void:
	var main_instance := _criar_main_com_cama()
	GameState.ciclo_dia_noite_seg = CICLO_NOITE
	watch_signals(EventBus)

	main_instance._player._processar_interacao(POS_CAMA)

	assert_signal_emitted(EventBus, "player_slept")
	assert_eq(GameState.ciclo_dia_noite_seg, 0.0, "dormir amanhece o dia")


func test_dormir_cura_4_e_avisa_bom_dia() -> void:
	var main_instance := _criar_main_com_cama()
	GameState.ciclo_dia_noite_seg = CICLO_NOITE
	GameState.vida_atual = 10
	watch_signals(EventBus)

	main_instance._player._processar_interacao(POS_CAMA)

	assert_eq(GameState.vida_atual, 14)
	assert_signal_emitted_with_parameters(EventBus, "aviso", ["Bom dia!"])


func test_dormir_nao_passa_da_vida_maxima() -> void:
	var main_instance := _criar_main_com_cama()
	GameState.ciclo_dia_noite_seg = CICLO_NOITE
	GameState.vida_atual = GameState.vida_maxima - 1

	main_instance._player._processar_interacao(POS_CAMA)

	assert_eq(GameState.vida_atual, GameState.vida_maxima)


func test_dormir_marca_o_respawn_e_cria_o_fade_preto() -> void:
	var main_instance := _criar_main_com_cama()
	GameState.ciclo_dia_noite_seg = CICLO_NOITE

	main_instance._player._processar_interacao(POS_CAMA)

	assert_eq(GameState.ponto_respawn, Vector3(POS_CAMA) + Vector3(0.5, 1.0, 0.5))
	var fade: ColorRect = main_instance._fade_dormir
	assert_not_null(fade, "dormir deveria criar o ColorRect do fade")
	assert_eq(fade.color, Color.BLACK)
	assert_true(fade.get_parent() is CanvasLayer, "o fade fica numa CanvasLayer própria")


func test_de_dia_a_cama_so_marca_o_respawn_e_avisa() -> void:
	var main_instance := _criar_main_com_cama()
	GameState.ciclo_dia_noite_seg = CICLO_DIA
	watch_signals(EventBus)

	main_instance._player._processar_interacao(POS_CAMA)

	assert_signal_not_emitted(EventBus, "player_slept")
	assert_signal_emitted_with_parameters(EventBus, "aviso", ["Você só consegue dormir à noite"])
	assert_eq(GameState.ciclo_dia_noite_seg, CICLO_DIA, "de dia o ciclo não muda")
	assert_eq(GameState.ponto_respawn, Vector3(POS_CAMA) + Vector3(0.5, 1.0, 0.5))
