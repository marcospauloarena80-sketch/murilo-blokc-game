extends GutTest
## Ciclo 6 (Frente 6E): com a fome quase cheia a vida volta sozinha — +1 a cada
## 4 s e, a cada 2 regenerações, -1 de fome. Só vale jogando: pausado ou em
## batalha o main._process nem roda. Segue test_death_and_bed.gd (instancia
## main.tscn e chama métodos privados direto, sem esperar quadros).

const MainScene := preload("res://scenes/main.tscn")

var _estado_original: GameState.State
var _ciclo_original: float
var _tempo_original: float


func before_each() -> void:
	_estado_original = GameState.current_state
	_ciclo_original = GameState.ciclo_dia_noite_seg
	_tempo_original = GameState.tempo_de_jogo_seg
	GameState.inventario_hotbar = InventoryModel.new(8)
	GameState.inventario_mochila = InventoryModel.new(24)
	GameState.vida_atual = 10
	GameState.fome_atual = 20


func after_each() -> void:
	GameState.mudar_estado(_estado_original)
	GameState.ciclo_dia_noite_seg = _ciclo_original
	GameState.tempo_de_jogo_seg = _tempo_original
	GameState.vida_atual = GameState.vida_maxima
	GameState.fome_atual = GameState.fome_maxima


func _criar_main() -> Node3D:
	var main_instance := MainScene.instantiate() as Node3D
	add_child_autofree(main_instance)
	return main_instance


func test_vida_sobe_1_depois_de_4_segundos_jogando_com_fome_cheia() -> void:
	var main_instance := _criar_main()
	GameState.mudar_estado(GameState.State.PLAYING)

	main_instance._process(2.0)
	assert_eq(GameState.vida_atual, 10, "antes de 4 s não regenera")
	main_instance._process(2.1)

	assert_eq(GameState.vida_atual, 11)


func test_com_fome_10_nao_regenera() -> void:
	var main_instance := _criar_main()
	GameState.fome_atual = 10
	GameState.mudar_estado(GameState.State.PLAYING)

	main_instance._process(4.1)

	assert_eq(GameState.vida_atual, 10)


func test_pausado_nao_regenera() -> void:
	var main_instance := _criar_main()
	GameState.mudar_estado(GameState.State.PAUSED)

	main_instance._process(4.1)

	assert_eq(GameState.vida_atual, 10)


func test_a_cada_duas_regeneracoes_gasta_1_de_fome() -> void:
	var main_instance := _criar_main()
	GameState.mudar_estado(GameState.State.PLAYING)

	main_instance._process(4.1)
	assert_eq(GameState.fome_atual, 20, "a primeira regeneração ainda não cobra fome")
	main_instance._process(4.1)

	assert_eq(GameState.vida_atual, 12)
	assert_eq(GameState.fome_atual, 19)


func test_com_vida_cheia_nao_regenera_nem_gasta_fome() -> void:
	var main_instance := _criar_main()
	GameState.vida_atual = GameState.vida_maxima
	GameState.mudar_estado(GameState.State.PLAYING)

	main_instance._process(4.1)
	main_instance._process(4.1)

	assert_eq(GameState.vida_atual, GameState.vida_maxima)
	assert_eq(GameState.fome_atual, 20)
