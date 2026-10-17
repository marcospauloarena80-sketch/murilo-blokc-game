class_name Sintetizador
extends RefCounted
## Gera AudioStreamWAV (22050 Hz, 16 bits, mono) em código: tons, ruído,
## sequências de notas, acordes, varreduras e os loops de ambiente. Puro — não
## conhece AudioServer nem buses, só devolve streams prontos pra um
## AudioStreamPlayer. Ciclo 5 (ADR-028): na Web o gerador em tempo real não toca
## no modo de amostras e asset de terceiros é proibido (ADR-024), então todo som
## do jogo nasce aqui.
## Formas de onda: "seno", "triangulo", "quadrada", "serra".
## Envelopes: "queda" (linear até zero), "plano" (constante com bordas suaves),
## "nota" (ataque curto, decaimento parcial e solta no fim) e "sino" (ataque
## curto e decaimento exponencial).

const MIX_RATE: int = 22050
const AMPLITUDE: float = 0.5  ## folga pra somar vozes sem estourar
const BORDA_SEG: float = 0.005  ## suaviza início e fim pra não dar clique
const ALFA_VENTO: float = 0.06  ## passa-baixa de um polo (~200 Hz) do vento


static func tom(
	freq: float, dur: float, forma: String = "seno", envelope: String = "queda"
) -> AudioStreamWAV:
	return empacotar(onda(freq, dur, forma, envelope))


static func ruido(dur: float, envelope: String = "queda", semente: int = 1) -> AudioStreamWAV:
	return empacotar(ruido_bruto(dur, envelope, semente))


static func varredura(
	freq_inicial: float,
	freq_final: float,
	dur: float,
	forma: String = "seno",
	envelope: String = "queda"
) -> AudioStreamWAV:
	return empacotar(varredura_bruta(freq_inicial, freq_final, dur, forma, envelope))


static func sequencia(notas: Array, bpm: float, forma: String = "seno") -> AudioStreamWAV:
	## notas = [[freq, batidas], ...]; freq 0 é pausa. Cada nota distinta é
	## sintetizada uma vez e reaproveitada: a melodia inteira amostra por amostra
	## em GDScript seria lenta demais na Web.
	var seg_por_batida: float = 60.0 / bpm
	var cache: Dictionary = {}
	var amostras := PackedFloat32Array()
	for nota: Array in notas:
		var chave := "%s|%s" % [nota[0], nota[1]]
		if not cache.has(chave):
			cache[chave] = onda(float(nota[0]), float(nota[1]) * seg_por_batida, forma, "nota")
		var trecho: PackedFloat32Array = cache[chave]
		amostras.append_array(trecho)
	return empacotar(amostras)


static func acorde(
	freqs: Array, dur: float, forma: String = "seno", envelope: String = "queda"
) -> AudioStreamWAV:
	var soma := PackedFloat32Array()
	soma.resize(_frames(dur))
	for freq: float in freqs:
		_misturar_em(soma, onda(freq, dur, forma, envelope), 0)
	return empacotar(_escalar(soma, 1.0 / maxf(1.0, float(freqs.size()))))


static func em_loop(stream: AudioStreamWAV) -> AudioStreamWAV:
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames_de(stream)
	return stream


static func frames_de(stream: AudioStreamWAV) -> int:
	return stream.data.size() / 2  ## 16 bits mono: 2 bytes por quadro


static func vento(dur: float) -> AudioStreamWAV:
	## Ruído passado por um passa-baixa simples (rumor grave) com rajadas lentas
	## cujo ciclo fecha exatamente na duração do loop (sem emenda audível).
	var n := _frames(dur)
	var a := PackedFloat32Array()
	a.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var filtrado: float = 0.0
	for i: int in n:
		filtrado += ALFA_VENTO * (rng.randf_range(-1.0, 1.0) - filtrado)
		var rajada: float = 0.65 + 0.35 * sin(TAU * float(i) / float(n))
		a[i] = 3.0 * AMPLITUDE * filtrado * rajada
	return em_loop(empacotar(a))


static func passaros(dur: float, semente: int = 3) -> AudioStreamWAV:
	## Silêncio com alguns trinados (3 a 5 chilros curtos, varredura pra cima)
	## em instantes sorteados; semente fixa pra o loop ser sempre o mesmo.
	var n := _frames(dur)
	var a := PackedFloat32Array()
	a.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for _trinado: int in 5:
		var inicio := rng.randi_range(0, n - 1)
		var base := rng.randf_range(2200.0, 3400.0)
		for _chilro: int in rng.randi_range(3, 5):
			var pio := varredura_bruta(base, base * 1.35, 0.06, "seno", "sino")
			_misturar_em(a, pio, inicio)
			inicio += pio.size() + _frames(0.04)
	return em_loop(empacotar(a))


static func grilos(dur: float) -> AudioStreamWAV:
	## Dois grilos: tons agudos pulsando (~38 Hz) em rajadas, num padrão de 2 s
	## repetido até fechar o loop.
	var padrao_seg: float = 2.0
	var repeticoes: int = maxi(1, roundi(dur / padrao_seg))
	var n := _frames(padrao_seg)
	var padrao := PackedFloat32Array()
	padrao.resize(n)
	var passo_a: float = 4200.0 / float(MIX_RATE)
	var passo_b: float = 3900.0 / float(MIX_RATE)
	var fase_a: float = 0.0
	var fase_b: float = 0.0
	for i: int in n:
		var t: float = float(i) / float(MIX_RATE)
		var pulso: float = 0.5 + 0.5 * sin(TAU * 38.0 * t)
		var rajada_a: float = _rajada(fmod(t, 0.6), 0.35) if t < 1.8 else 0.0
		var rajada_b: float = _rajada(fmod(t - 0.3, 1.0), 0.2) if t >= 0.3 and t < 1.6 else 0.0
		padrao[i] = (
			AMPLITUDE
			* pulso
			* (0.5 * rajada_a * sin(TAU * fase_a) + 0.4 * rajada_b * sin(TAU * fase_b))
		)
		fase_a += passo_a
		fase_b += passo_b
	var a := PackedFloat32Array()
	for _repeticao: int in repeticoes:
		a.append_array(padrao)
	return em_loop(empacotar(a))


static func empacotar(amostras: PackedFloat32Array) -> AudioStreamWAV:
	## PCM 16 bits little-endian, como AudioStreamWAV espera em `data`.
	var dados := PackedByteArray()
	dados.resize(amostras.size() * 2)
	for i: int in amostras.size():
		dados.encode_s16(i * 2, clampi(roundi(amostras[i] * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = dados
	return stream


static func onda(
	freq: float, dur: float, forma: String = "seno", envelope: String = "queda"
) -> PackedFloat32Array:
	var n := _frames(dur)
	var a := PackedFloat32Array()
	a.resize(n)
	if freq <= 0.0 or n == 0:
		return a  ## pausa: silêncio
	var passo: float = freq / float(MIX_RATE)  ## ciclos por quadro
	var fase: float = 0.0
	## Um laço por forma: chamar função por amostra dobraria o custo.
	match forma:
		"triangulo":
			for i: int in n:
				a[i] = AMPLITUDE * (1.0 - 4.0 * absf(fase - floorf(fase) - 0.5))
				fase += passo
		"quadrada":
			for i: int in n:
				a[i] = 0.7 * AMPLITUDE if fase - floorf(fase) < 0.5 else -0.7 * AMPLITUDE
				fase += passo
		"serra":
			for i: int in n:
				a[i] = 0.7 * AMPLITUDE * (2.0 * (fase - floorf(fase)) - 1.0)
				fase += passo
		_:
			for i: int in n:
				a[i] = AMPLITUDE * sin(TAU * fase)
				fase += passo
	return _aplicar_envelope(a, envelope)


static func ruido_bruto(
	dur: float, envelope: String = "queda", semente: int = 1
) -> PackedFloat32Array:
	var n := _frames(dur)
	var a := PackedFloat32Array()
	a.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for i: int in n:
		a[i] = AMPLITUDE * rng.randf_range(-1.0, 1.0)
	return _aplicar_envelope(a, envelope)


static func varredura_bruta(
	freq_inicial: float,
	freq_final: float,
	dur: float,
	forma: String = "seno",
	envelope: String = "queda"
) -> PackedFloat32Array:
	## Frequência muda linearmente do início ao fim (chilro de pássaro, tom de
	## morte descendo). Som curto: aqui pode dispatchar a forma por amostra.
	var n := _frames(dur)
	var a := PackedFloat32Array()
	a.resize(n)
	var fase: float = 0.0
	for i: int in n:
		var freq: float = lerpf(freq_inicial, freq_final, float(i) / float(maxi(n - 1, 1)))
		a[i] = AMPLITUDE * _valor_onda(forma, fase)
		fase += freq / float(MIX_RATE)
	return _aplicar_envelope(a, envelope)


static func _valor_onda(forma: String, fase: float) -> float:
	var fracao: float = fase - floorf(fase)
	match forma:
		"triangulo":
			return 1.0 - 4.0 * absf(fracao - 0.5)
		"quadrada":
			return 0.7 if fracao < 0.5 else -0.7
		"serra":
			return 0.7 * (2.0 * fracao - 1.0)
	return sin(TAU * fase)


static func _aplicar_envelope(a: PackedFloat32Array, envelope: String) -> PackedFloat32Array:
	var n := a.size()
	if n == 0:
		return a
	var borda: float = float(mini(_frames(BORDA_SEG), maxi(1, n / 4)))
	match envelope:
		"plano":
			for i: int in n:
				a[i] *= minf(1.0, minf(float(i + 1) / borda, float(n - i) / borda))
		"nota":
			var cauda: float = float(maxi(_frames(0.02), 1))
			for i: int in n:
				var ganho: float = minf(1.0, float(i + 1) / borda)
				ganho *= 1.0 - 0.6 * float(i) / float(n)
				ganho *= minf(1.0, float(n - i) / cauda)
				a[i] *= ganho
		"sino":
			for i: int in n:
				a[i] *= minf(1.0, float(i + 1) / borda) * exp(-5.0 * float(i) / float(n))
		_:
			for i: int in n:
				a[i] *= (1.0 - float(i) / float(n)) * minf(1.0, float(i + 1) / borda)
	return a


static func _rajada(t_local: float, dur_rajada: float) -> float:
	## Janela de 0 a 1 com rampas de 20 ms, pra rajada não dar clique.
	return clampf(minf(t_local / 0.02, (dur_rajada - t_local) / 0.02), 0.0, 1.0)


static func _misturar_em(
	destino: PackedFloat32Array, trecho: PackedFloat32Array, inicio: int
) -> void:
	## Soma `trecho` em `destino` a partir de `inicio`, cortando o que passar
	## do fim. Packed arrays são passados por referência, então altera o original.
	var fim: int = mini(destino.size(), inicio + trecho.size())
	for i: int in range(maxi(inicio, 0), fim):
		destino[i] += trecho[i - inicio]


static func _escalar(a: PackedFloat32Array, fator: float) -> PackedFloat32Array:
	for i: int in a.size():
		a[i] *= fator
	return a


static func _frames(dur: float) -> int:
	return roundi(dur * float(MIX_RATE))
