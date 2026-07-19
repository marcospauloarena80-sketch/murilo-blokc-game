extends GutTest
## Ver docs/01-GDD.md §3 e docs/07-DECISOES.md ADR-024 — cor ambiente por
## bioma + escurecida no clima (polimento visual da F11).

const MainScene := preload("res://scenes/main.tscn")


func test_cor_ambiente_reflete_o_bioma_do_jogador() -> void:
	var main := MainScene.instantiate() as Node3D
	add_child_autofree(main)
	main._player.global_position = Vector3(64, 45, 64)  # campos_dourados

	main._atualizar_cor_ambiente()

	var esperado: Color = BiomeRegistry.get_bioma("campos_dourados").cor_ambiente
	assert_eq(main._ambiente.environment.ambient_light_color, esperado)


func test_cor_ambiente_muda_em_outro_bioma() -> void:
	var main := MainScene.instantiate() as Node3D
	add_child_autofree(main)
	main._player.global_position = Vector3(0, 45, 0)  # picos_gelados

	main._atualizar_cor_ambiente()

	var esperado: Color = BiomeRegistry.get_bioma("picos_gelados").cor_ambiente
	assert_eq(main._ambiente.environment.ambient_light_color, esperado)


func test_cor_ambiente_escurece_na_tempestade() -> void:
	var main := MainScene.instantiate() as Node3D
	add_child_autofree(main)
	main._player.global_position = Vector3(64, 45, 64)
	var clima: WeatherSystem = main.get_node("WeatherSystem")
	clima._sortear_clima(0.95)  # tempestade

	main._atualizar_cor_ambiente()

	var base: Color = BiomeRegistry.get_bioma("campos_dourados").cor_ambiente
	assert_eq(main._ambiente.environment.ambient_light_color, base.darkened(0.25))
