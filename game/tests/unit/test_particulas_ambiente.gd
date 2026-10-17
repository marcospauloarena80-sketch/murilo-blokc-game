extends GutTest
## Partículas de vida (Ciclo 5, Frente 5C): pólen de dia, vagalumes de noite,
## acompanhando o jogador e desligadas dentro da água. Puramente cosmético,
## mesmo padrão de BlockBreakParticles/WeatherSystem.

var _ciclo_original: float


func before_each() -> void:
	_ciclo_original = GameState.ciclo_dia_noite_seg


func after_each() -> void:
	GameState.ciclo_dia_noite_seg = _ciclo_original


func _montar_de_dia() -> ParticulasAmbiente:
	GameState.ciclo_dia_noite_seg = GameState.DURACAO_CICLO_SEG * 0.1  # meio do dia
	var sistema := ParticulasAmbiente.new()
	add_child_autofree(sistema)
	return sistema


func test_de_dia_polen_emite_e_vagalumes_nao() -> void:
	var sistema := _montar_de_dia()

	assert_true((sistema.get_node("Polen") as GPUParticles3D).emitting, "pólen de dia")
	assert_false((sistema.get_node("Vagalumes") as GPUParticles3D).emitting, "sem vagalumes de dia")


func test_de_noite_vagalumes_emitem_e_polen_nao() -> void:
	GameState.ciclo_dia_noite_seg = GameState.DURACAO_CICLO_SEG * 0.9  # meio da noite
	var sistema := ParticulasAmbiente.new()
	add_child_autofree(sistema)

	assert_false((sistema.get_node("Polen") as GPUParticles3D).emitting, "sem pólen de noite")
	assert_true((sistema.get_node("Vagalumes") as GPUParticles3D).emitting, "vagalumes de noite")


func test_night_started_inverte_e_day_started_volta() -> void:
	var sistema := _montar_de_dia()
	var polen := sistema.get_node("Polen") as GPUParticles3D
	var vagalumes := sistema.get_node("Vagalumes") as GPUParticles3D

	EventBus.night_started.emit()
	assert_false(polen.emitting, "pólen apaga ao anoitecer")
	assert_true(vagalumes.emitting, "vagalumes acendem ao anoitecer")

	EventBus.day_started.emit()
	assert_true(polen.emitting, "pólen volta ao amanhecer")
	assert_false(vagalumes.emitting, "vagalumes somem ao amanhecer")


func test_dentro_da_agua_nada_emite() -> void:
	var sistema := _montar_de_dia()

	sistema._na_agua = true
	sistema._atualizar_emissao()

	assert_false((sistema.get_node("Polen") as GPUParticles3D).emitting)
	assert_false((sistema.get_node("Vagalumes") as GPUParticles3D).emitting)


func test_polen_tem_24_particulas_e_vagalumes_16() -> void:
	var sistema := _montar_de_dia()

	assert_eq((sistema.get_node("Polen") as GPUParticles3D).amount, 24)
	assert_eq((sistema.get_node("Vagalumes") as GPUParticles3D).amount, 16)


func test_segue_o_jogador_2_blocos_acima() -> void:
	var jogador := Node3D.new()
	jogador.add_to_group("player")
	add_child_autofree(jogador)
	jogador.global_position = Vector3(10, 20, 30)
	var sistema := _montar_de_dia()

	sistema._process(0.0)

	assert_eq(sistema.global_position, Vector3(10, 22, 30))
