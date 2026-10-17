extends GutTest
## Poderes temporários do toque: voar com duplo toque pra cima, acelerar, e uma
## barra de carga que esvazia e recarrega.


func test_primeiro_toque_pula_e_segundo_ativa_o_voo() -> void:
	var p := Poderes.new()

	assert_eq(p.tocar_cima(1.0), "pulo")
	assert_false(p.voando)
	assert_eq(p.tocar_cima(1.2), "voo")
	assert_true(p.voando)


func test_toques_separados_nao_ativam_o_voo() -> void:
	var p := Poderes.new()
	p.tocar_cima(1.0)

	assert_eq(p.tocar_cima(2.0), "pulo")
	assert_false(p.voando)


func test_baixo_voando_pousa_e_no_chao_agacha() -> void:
	var p := Poderes.new()
	p.tocar_cima(1.0)
	p.tocar_cima(1.1)

	assert_eq(p.tocar_baixo(), "cair")
	assert_false(p.voando)
	assert_eq(p.tocar_baixo(), "agachar")


func test_voo_gasta_carga_e_desliga_ao_zerar() -> void:
	var p := Poderes.new()
	p.tocar_cima(1.0)
	p.tocar_cima(1.1)

	p.atualizar(5.0)
	assert_almost_eq(p.carga, 0.5, 0.001)
	assert_true(p.voando)
	p.atualizar(6.0)

	assert_false(p.voando)
	assert_true(p.bloqueado)
	assert_eq(p.carga, 0.0)


func test_bloqueado_so_volta_ao_recarregar_o_minimo() -> void:
	var p := Poderes.new()
	p.carga = 0.0
	p.bloqueado = true
	p.alternar_turbo()
	assert_false(p.turbo, "zerado não liga")

	p.atualizar(1.0)  # +0,12
	p.alternar_turbo()
	assert_false(p.turbo, "ainda abaixo de 0,25")
	p.atualizar(2.0)  # +0,24, total 0,36
	p.alternar_turbo()

	assert_true(p.turbo)
	assert_false(p.bloqueado)


func test_turbo_alterna_e_gasta_carga() -> void:
	var p := Poderes.new()
	p.alternar_turbo()
	assert_true(p.turbo)

	p.atualizar(1.0)
	assert_almost_eq(p.carga, 1.0 - Poderes.CONSUMO_TURBO_POR_SEG, 0.001)
	p.alternar_turbo()
	assert_false(p.turbo)


func test_descansando_recarrega_ate_o_maximo() -> void:
	var p := Poderes.new()
	p.carga = 0.2

	p.atualizar(100.0)

	assert_eq(p.carga, Poderes.CARGA_MAXIMA)
