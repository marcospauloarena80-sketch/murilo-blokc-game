extends GutTest
## Frente 5D (ADR-028): partituras das músicas geradas — pentatônica de dó,
## compasso 4/4, com o número de compassos combinado no plano.


func test_dia_tem_16_compassos() -> void:
	assert_almost_eq(Partituras.batidas(Partituras.DIA), 64.0, 0.001)


func test_noite_tem_16_compassos() -> void:
	assert_almost_eq(Partituras.batidas(Partituras.NOITE), 64.0, 0.001)


func test_batalha_tem_8_compassos() -> void:
	assert_almost_eq(Partituras.batidas(Partituras.BATALHA), 32.0, 0.001)


func test_vitoria_tem_2_compassos() -> void:
	assert_almost_eq(Partituras.batidas(Partituras.VITORIA), 8.0, 0.001)


func test_toda_nota_e_da_escala_pentatonica_ou_pausa() -> void:
	var partituras: Array = [
		Partituras.DIA, Partituras.NOITE, Partituras.BATALHA, Partituras.VITORIA
	]
	for partitura: Array in partituras:
		for nota: Array in partitura:
			var freq: float = nota[0]
			assert_true(
				freq == Partituras.PAUSA or Partituras.ESCALA.has(freq),
				"nota fora da pentatônica: %s" % freq
			)


func test_duracao_do_dia_a_100_bpm_e_38_4s() -> void:
	assert_almost_eq(Partituras.duracao_seg(Partituras.DIA, Partituras.BPM_DIA), 38.4, 0.001)
