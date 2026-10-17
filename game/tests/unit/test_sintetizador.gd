extends GutTest
## Frente 5D (ADR-028): o Sintetizador gera AudioStreamWAV (22050 Hz, 16 bits,
## mono) em código — o que toca na Web no modo de amostras, sem asset externo.

const FORMAS: Array = ["seno", "triangulo", "quadrada", "serra"]


func _pico(stream: AudioStreamWAV) -> int:
	var pico := 0
	var dados := stream.data
	for i: int in range(0, dados.size(), 2):
		pico = maxi(pico, absi(dados.decode_s16(i)))
	return pico


func test_tom_de_0_1s_tem_2205_quadros_mono_16_bits_a_22050() -> void:
	var stream := Sintetizador.tom(440.0, 0.1)
	assert_is(stream, AudioStreamWAV)
	assert_eq(stream.data.size(), 2 * 2205)
	assert_eq(stream.mix_rate, 22050)
	assert_false(stream.stereo)
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_almost_eq(stream.get_length(), 0.1, 0.001)


func test_tom_tem_som_e_nao_estoura() -> void:
	var pico := _pico(Sintetizador.tom(440.0, 0.1))
	assert_gt(pico, 1000, "tom de 440 Hz deveria ter amplitude audível")
	assert_lt(pico, 32768)


func test_envelope_queda_termina_em_silencio() -> void:
	var dados := Sintetizador.tom(440.0, 0.1, "seno", "queda").data
	assert_lt(absi(dados.decode_s16(dados.size() - 2)), 200)


func test_todas_as_formas_de_onda_produzem_som() -> void:
	for forma: String in FORMAS:
		assert_gt(_pico(Sintetizador.tom(220.0, 0.05, forma)), 1000, forma)


func test_ruido_tem_tamanho_certo_som_e_e_deterministico() -> void:
	var stream := Sintetizador.ruido(0.1)
	assert_eq(stream.data.size(), 2 * 2205)
	assert_gt(_pico(stream), 1000)
	assert_eq(stream.data, Sintetizador.ruido(0.1).data, "mesma semente, mesmo ruído")


func test_sequencia_de_4_notas_a_120_bpm_dura_2s() -> void:
	var notas: Array = [[440.0, 1.0], [494.0, 1.0], [523.25, 1.0], [587.33, 1.0]]
	var stream := Sintetizador.sequencia(notas, 120.0)
	assert_almost_eq(stream.get_length(), 2.0, 0.001)
	assert_eq(stream.data.size(), 2 * 2 * 22050)
	assert_gt(_pico(stream), 1000)


func test_pausa_na_sequencia_e_silencio() -> void:
	var stream := Sintetizador.sequencia([[0.0, 1.0]], 60.0)
	assert_eq(stream.data.size(), 2 * 22050)
	assert_eq(_pico(stream), 0)


func test_acorde_de_3_notas_soa_sem_estourar() -> void:
	var stream := Sintetizador.acorde([523.25, 659.25, 783.99], 0.2)
	assert_eq(stream.data.size(), 2 * 4410)
	assert_gt(_pico(stream), 1000)
	assert_lt(_pico(stream), 32768)


func test_varredura_tem_duracao_e_som() -> void:
	var stream := Sintetizador.varredura(220.0, 55.0, 0.2, "serra")
	assert_eq(stream.data.size(), 2 * 4410)
	assert_gt(_pico(stream), 1000)


func test_em_loop_marca_loop_forward_do_inicio_ao_fim() -> void:
	var stream := Sintetizador.em_loop(Sintetizador.tom(440.0, 0.1))
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(stream.loop_begin, 0)
	assert_eq(stream.loop_end, 2205)


func test_loops_de_ambiente_duram_6s_em_loop_e_tem_som() -> void:
	var loops: Dictionary = {
		"vento": Sintetizador.vento(6.0),
		"passaros": Sintetizador.passaros(6.0),
		"grilos": Sintetizador.grilos(6.0),
	}
	for nome: String in loops:
		var stream: AudioStreamWAV = loops[nome]
		assert_almost_eq(stream.get_length(), 6.0, 0.001, nome)
		assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, nome)
		assert_gt(_pico(stream), 500, nome)
		assert_lt(_pico(stream), 32768, nome)
