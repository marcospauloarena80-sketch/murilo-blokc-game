extends SceneTree
## Gera assets/textures/atlas_blocos.png: pixel art própria do Vale Dourado,
## desenhada por código (Ciclo 4, ADR-027). Determinístico (semente fixa por
## tile), então rodar de novo produz o mesmo PNG. Todo tile emenda nas bordas
## (ruído com grade periódica), porque blocos vizinhos repetem a textura.
## Uso: godot --headless -s res://tools/gerar_atlas.gd

const L: int = AtlasBlocos.LADO


func _init() -> void:
	var nomes: Array[String] = AtlasBlocos.NOMES
	var linhas: int = ceili(nomes.size() / float(AtlasBlocos.COLUNAS))
	var atlas := Image.create(AtlasBlocos.COLUNAS * L, linhas * L, false, Image.FORMAT_RGBA8)
	for i: int in range(nomes.size()):
		var tile := _desenhar(nomes[i], i)
		var destino := Vector2i((i % AtlasBlocos.COLUNAS) * L, (i / AtlasBlocos.COLUNAS) * L)
		atlas.blit_rect(tile, Rect2i(0, 0, L, L), destino)
	var caminho := ProjectSettings.globalize_path(AtlasBlocos.CAMINHO_PNG)
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	atlas.save_png(caminho)
	print("ATLAS ", caminho, " ", atlas.get_size())
	quit()


func _desenhar(nome: String, semente: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * (semente + 1)
	var img := Image.create(L, L, false, Image.FORMAT_RGBA8)
	match nome:
		"grama_topo":
			_grama_topo(img, rng)
		"grama_lado":
			_terra(img, rng)
			_franja_de_grama(img, rng)
		"terra":
			_terra(img, rng)
		"pedra":
			_pedra(img, rng)
		"tronco_lado":
			_casca(img, rng, _paleta(["5a3a20", "6e4826", "84592f", "3f2814"]), false)
		"tronco_topo":
			_aneis(img, rng, _paleta(["9a6d38", "b5854a", "c99a5c", "5a3a20"]), false)
		"folhas":
			_folhas(img, rng)
		"areia":
			_areia(img, rng)
		"gelo":
			_gelo(img, rng)
		"ambar":
			_ambar(img, rng)
		"carvao":
			_pedra(img, rng)
			_minerio(img, rng, _paleta(["2b2733", "3a3545", "4f4860", "1d1a24"]), false)
		"ferrite":
			_pedra(img, rng)
			_minerio(img, rng, _paleta(["a85f2e", "c4753a", "e8a066", "7a3f1c"]), false)
		"cristal_dourado":
			_pedra(img, rng)
			_minerio(img, rng, _paleta(["d9a520", "ffd34d", "fff0b0", "a87612"]), true)
		"bau_lado":
			_bau(img, rng, false)
		"bau_topo":
			_bau(img, rng, true)
		"cama_topo":
			_cama_topo(img, rng)
		"cama_lado":
			_cama_lado(img, rng)
		"tocha":
			_lanterna(img, rng)
		"tronco_raro_lado":
			_casca(img, rng, _paleta(["7a2e1c", "92402a", "a8523a", "561d10"]), true)
		"tronco_raro_topo":
			_aneis(img, rng, _paleta(["a8523a", "c06a48", "d8875e", "561d10"]), true)
		"capim":
			_capim(img, rng)
		"flor_amarela":
			_flor(img, rng, Color.html("ffd447"), Color.html("ff9f1c"))
		"flor_rosa":
			_flor(img, rng, Color.html("ff8fc4"), Color.html("ffe066"))
		"flor_lumen":
			_flor(img, rng, Color.html("8fe9ff"), Color.html("ffffff"))
		"muda":
			_muda(img, rng)
		"cogumelo":
			_cogumelo(img, rng)
		"trigo_1":
			_trigo(img, rng, 8, Color.html("6fbf4a"), false)
		"trigo_2":
			_trigo(img, rng, 16, Color.html("a8c23a"), false)
		"trigo_3":
			_trigo(img, rng, 22, Color.html("d9b43a"), true)
		"terra_arada_topo":
			_terra_arada_topo(img, rng)
		"tabuas":
			_tabuas(img, rng)
		"vidro":
			_vidro(img)
		"porta_baixo":
			_porta(img, rng, false)
		"porta_cima":
			_porta(img, rng, true)
	return img


# --- utilidades -------------------------------------------------------------


func _paleta(hexes: Array) -> Array[Color]:
	var cores: Array[Color] = []
	for h: String in hexes:
		cores.append(Color.html(h))
	return cores


func _ruido(rng: RandomNumberGenerator, grade: int) -> PackedFloat32Array:
	## Ruído de valor periódico: grade x grade pontos aleatórios com volta nas
	## bordas e interpolação suave, então o tile emenda com ele mesmo.
	var pontos := PackedFloat32Array()
	pontos.resize(grade * grade)
	for i: int in range(grade * grade):
		pontos[i] = rng.randf()
	var saida := PackedFloat32Array()
	saida.resize(L * L)
	var passo: float = float(L) / grade
	for y: int in range(L):
		for x: int in range(L):
			var gx: float = x / passo
			var gy: float = y / passo
			var x0: int = floori(gx) % grade
			var y0: int = floori(gy) % grade
			var x1: int = (x0 + 1) % grade
			var y1: int = (y0 + 1) % grade
			var tx: float = smoothstep(0.0, 1.0, gx - floorf(gx))
			var ty: float = smoothstep(0.0, 1.0, gy - floorf(gy))
			var a: float = lerpf(pontos[y0 * grade + x0], pontos[y0 * grade + x1], tx)
			var b: float = lerpf(pontos[y1 * grade + x0], pontos[y1 * grade + x1], tx)
			saida[y * L + x] = lerpf(a, b, ty)
	return saida


func _fbm(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var a := _ruido(rng, 4)
	var b := _ruido(rng, 8)
	var c := _ruido(rng, 16)
	var saida := PackedFloat32Array()
	saida.resize(L * L)
	for i: int in range(L * L):
		saida[i] = a[i] * 0.5 + b[i] * 0.3 + c[i] * 0.2
	return saida


func _tom(paleta: Array[Color], valor: float) -> Color:
	## paleta em ordem: [escuro, médio, claro, mais escuro] -> do escuro ao claro.
	var ordem: Array[Color] = [paleta[3], paleta[0], paleta[1], paleta[2]]
	var idx: int = clampi(int(valor * ordem.size()), 0, ordem.size() - 1)
	return ordem[idx]


func _pintar_ruido(img: Image, rng: RandomNumberGenerator, paleta: Array[Color]) -> void:
	var n := _fbm(rng)
	for y: int in range(L):
		for x: int in range(L):
			var v: float = n[y * L + x] + rng.randf_range(-0.08, 0.08)
			img.set_pixel(x, y, _tom(paleta, clampf((v - 0.25) * 1.8, 0.0, 0.999)))


func _ponto(img: Image, x: int, y: int, cor: Color) -> void:
	img.set_pixel(posmod(x, L), posmod(y, L), cor)


func _bolha(img: Image, cx: int, cy: int, raio: float, paleta: Array[Color]) -> void:
	## Disco com luz no alto à esquerda e sombra embaixo à direita.
	var r: int = ceili(raio)
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			var d: float = Vector2(dx, dy).length()
			if d > raio:
				continue
			var luz: float = (-dx - dy) / (raio * 2.0) + 0.5
			var cor: Color = paleta[0]
			if d > raio - 1.0 and dx + dy > 0:
				cor = paleta[3]
			elif luz > 0.72:
				cor = paleta[2]
			elif luz > 0.45:
				cor = paleta[1]
			_ponto(img, cx + dx, cy + dy, cor)


# --- tiles ------------------------------------------------------------------


func _grama_topo(img: Image, rng: RandomNumberGenerator) -> void:
	var verdes := _paleta(["43a23a", "55b545", "72cc56", "34862f"])
	_pintar_ruido(img, rng, verdes)
	for i: int in range(26):  # folhinhas claras em pé
		var x: int = rng.randi_range(0, L - 1)
		var y: int = rng.randi_range(0, L - 1)
		_ponto(img, x, y, verdes[2])
		_ponto(img, x, y - 1, Color.html("9be86f"))
	for i: int in range(3):  # florzinhas do Vale
		var x: int = rng.randi_range(0, L - 1)
		var y: int = rng.randi_range(0, L - 1)
		var petala: Color = Color.html("ffffff") if i % 2 == 0 else Color.html("ffa8d6")
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			_ponto(img, x + d.x, y + d.y, petala)
		_ponto(img, x, y, Color.html("ffd84a"))
	for i: int in range(3):  # brilho dourado
		_ponto(img, rng.randi_range(0, L - 1), rng.randi_range(0, L - 1), Color.html("fff3a0"))


func _terra(img: Image, rng: RandomNumberGenerator) -> void:
	var marrons := _paleta(["7d5233", "8f6240", "a3744d", "5f3b22"])
	_pintar_ruido(img, rng, marrons)
	var pedrinhas := _paleta(["9a8a7a", "b0a090", "c8baa8", "6e6052"])
	for i: int in range(7):
		_bolha(img, rng.randi_range(0, L - 1), rng.randi_range(0, L - 1), 1.3, pedrinhas)


func _franja_de_grama(img: Image, rng: RandomNumberGenerator) -> void:
	var verdes := _paleta(["43a23a", "55b545", "72cc56", "34862f"])
	var alturas := _ruido(rng, 8)
	for x: int in range(L):
		var fundo: int = 5 + int(alturas[x] * 6.0)
		if rng.randf() < 0.12:
			fundo += rng.randi_range(2, 4)  # fio que escorre
		for y: int in range(fundo):
			var cor: Color = verdes[1] if (x + y) % 3 else verdes[0]
			if y == 0:
				cor = verdes[2]
			elif y == fundo - 1:
				cor = verdes[3]
			img.set_pixel(x, y, cor)


func _pedra(img: Image, rng: RandomNumberGenerator) -> void:
	var cinzas := _paleta(["868ea2", "9aa1b3", "b4bac9", "6c7387"])
	var n := _fbm(rng)
	for y: int in range(L):
		for x: int in range(L):
			var v: float = n[y * L + x]
			var relevo: float = v - n[posmod(y + 1, L) * L + posmod(x + 1, L)]
			var valor: float = clampf((v - 0.25) * 1.6 + relevo * 4.0, 0.0, 0.999)
			img.set_pixel(x, y, _tom(cinzas, valor))
	for i: int in range(3):  # rachaduras
		var p := Vector2i(rng.randi_range(0, L - 1), rng.randi_range(0, L - 1))
		for passo: int in range(rng.randi_range(5, 10)):
			_ponto(img, p.x, p.y, Color.html("565d70"))
			p += Vector2i(rng.randi_range(-1, 1), 1 if rng.randf() < 0.6 else 0)


func _casca(img: Image, rng: RandomNumberGenerator, paleta: Array[Color], dourada: bool) -> void:
	var faixas := _ruido(rng, 8)
	var detalhe := _ruido(rng, 16)
	for y: int in range(L):
		for x: int in range(L):
			var v: float = faixas[x] * 0.75 + detalhe[(y / 4) * L + x] * 0.25
			var cor: Color = paleta[0]
			if v < 0.3:
				cor = paleta[3]  # sulco
			elif v > 0.62:
				cor = paleta[2]
			elif v > 0.45:
				cor = paleta[1]
			img.set_pixel(x, y, cor)
	if dourada:
		for i: int in range(6):
			_ponto(img, rng.randi_range(0, L - 1), rng.randi_range(0, L - 1), Color.html("f2c14e"))


func _aneis(img: Image, rng: RandomNumberGenerator, paleta: Array[Color], dourada: bool) -> void:
	var n := _ruido(rng, 4)
	var centro := Vector2(15.5, 15.5)
	for y: int in range(L):
		for x: int in range(L):
			var r: float = Vector2(x, y).distance_to(centro)
			var cor: Color
			if r > 13.5:
				cor = paleta[3]  # casca na borda
			else:
				var anel: float = sin(r * 1.5 + n[y * L + x] * 2.5)
				cor = paleta[2] if anel > 0.35 else (paleta[1] if anel > -0.35 else paleta[0])
				if dourada and absf(r - 7.0) < 0.6:
					cor = Color.html("f2c14e")
			img.set_pixel(x, y, cor)


func _folhas(img: Image, rng: RandomNumberGenerator) -> void:
	var verdes := _paleta(["3f9a3c", "57b84a", "7ad35d", "2f7d32"])
	img.fill(Color.html("23602a"))
	for i: int in range(26):
		_bolha(
			img,
			rng.randi_range(0, L - 1),
			rng.randi_range(0, L - 1),
			rng.randf_range(2.5, 4.5),
			verdes
		)
	for i: int in range(4):  # flor rosa entre as folhas
		_ponto(img, rng.randi_range(0, L - 1), rng.randi_range(0, L - 1), Color.html("ff8fc4"))


func _areia(img: Image, rng: RandomNumberGenerator) -> void:
	var tons := _paleta(["e3cd8f", "edd9a0", "f6e8bb", "d2b878"])
	var n := _fbm(rng)
	for y: int in range(L):
		for x: int in range(L):
			var onda: float = sin((y + n[y * L + x] * 6.0) * TAU / 8.0) * 0.18
			var v: float = n[y * L + x] + onda + rng.randf_range(-0.12, 0.12)
			img.set_pixel(x, y, _tom(tons, clampf((v - 0.2) * 1.5, 0.0, 0.999)))


func _gelo(img: Image, rng: RandomNumberGenerator) -> void:
	var azuis := _paleta(["a6d8fa", "bfe6ff", "e2f5ff", "8cc6f0"])
	_pintar_ruido(img, rng, azuis)
	for y: int in range(L):  # reflexos diagonais
		for x: int in range(L):
			var faixa: int = posmod(x + y, 16)
			if faixa == 0 or faixa == 1:
				img.set_pixel(x, y, Color.html("f4fbff"))
	for i: int in range(2):
		var p := Vector2i(rng.randi_range(0, L - 1), rng.randi_range(0, L - 1))
		for passo: int in range(8):
			_ponto(img, p.x, p.y, Color.html("ffffff"))
			p += Vector2i(1, rng.randi_range(-1, 1))


func _ambar(img: Image, rng: RandomNumberGenerator) -> void:
	var mel := _paleta(["e08a12", "f0a020", "ffc040", "c86e0a"])
	_pintar_ruido(img, rng, mel)
	for i: int in range(6):
		_bolha(
			img,
			rng.randi_range(0, L - 1),
			rng.randi_range(0, L - 1),
			rng.randf_range(1.0, 2.2),
			_paleta(["ffd070", "ffe08a", "fff4c8", "f0a020"])
		)


func _minerio(img: Image, rng: RandomNumberGenerator, paleta: Array[Color], brilho: bool) -> void:
	for i: int in range(5):
		var c := Vector2i(rng.randi_range(2, L - 3), rng.randi_range(2, L - 3))
		for j: int in range(rng.randi_range(3, 5)):
			var p := c + Vector2i(rng.randi_range(-2, 2), rng.randi_range(-2, 2))
			_bolha(img, p.x, p.y, rng.randf_range(1.0, 1.8), paleta)
		if brilho:
			_ponto(img, c.x - 1, c.y - 1, Color.html("ffffff"))


func _tabuas(img: Image, rng: RandomNumberGenerator) -> void:
	var madeira := _paleta(["a8743a", "b98245", "cf9a58", "8e5f2c"])
	var n := _ruido(rng, 16)
	for y: int in range(L):
		for x: int in range(L):
			var v: float = n[(y / 2) * L + x]
			var cor: Color = madeira[2] if v > 0.66 else (madeira[1] if v > 0.4 else madeira[0])
			if y % 8 == 7:
				cor = Color.html("5e3c19")  # junta entre tábuas
			elif y % 8 == 0:
				cor = madeira[2]
			img.set_pixel(x, y, cor)


func _bau(img: Image, rng: RandomNumberGenerator, topo: bool) -> void:
	_tabuas(img, rng)
	var metal := Color.html("8a8f99")
	var metal_claro := Color.html("c3c8d2")
	for y: int in range(L):
		for x: int in range(L):
			var borda: bool = x < 2 or x > L - 3 or (topo and (y < 2 or y > L - 3))
			if borda:
				img.set_pixel(x, y, metal_claro if (x + y) % 2 == 0 else metal)
	if not topo:
		for y: int in range(11, 19):  # fecho dourado
			for x: int in range(13, 19):
				var cor := Color.html("e8c24a") if y < 17 else Color.html("b8901f")
				img.set_pixel(x, y, cor)
		img.set_pixel(15, 14, Color.html("3b2814"))
		img.set_pixel(16, 14, Color.html("3b2814"))


func _cama_topo(img: Image, rng: RandomNumberGenerator) -> void:
	var cobertor := _paleta(["c93f3f", "dc5252", "ef7a7a", "a62e2e"])
	_pintar_ruido(img, rng, cobertor)
	for y: int in range(L):
		for x: int in range(L):
			if x < 2 or x > L - 3:
				img.set_pixel(x, y, Color.html("8e5f2c"))
			elif y >= 3 and y <= 10 and x >= 5 and x <= L - 6:
				img.set_pixel(x, y, Color.html("f6f2ea") if y < 9 else Color.html("d8d2c4"))
			elif y % 6 == 0 and y > 12:
				img.set_pixel(x, y, cobertor[3])


func _cama_lado(img: Image, rng: RandomNumberGenerator) -> void:
	_tabuas(img, rng)
	var cobertor := _paleta(["c93f3f", "dc5252", "ef7a7a", "a62e2e"])
	for y: int in range(0, 14):
		for x: int in range(L):
			img.set_pixel(x, y, cobertor[1] if y > 1 else cobertor[2])
	for x: int in range(L):
		img.set_pixel(x, 14, cobertor[3])


func _lanterna(img: Image, _rng: RandomNumberGenerator) -> void:
	var centro := Vector2(15.5, 15.5)
	for y: int in range(L):
		for x: int in range(L):
			var borda: bool = x < 3 or x > L - 4 or y < 3 or y > L - 4
			var travessa: bool = x == 15 or x == 16 or y == 15 or y == 16
			if borda:
				img.set_pixel(x, y, Color.html("3b2814") if (x + y) % 5 else Color.html("5a3d20"))
			elif travessa:
				img.set_pixel(x, y, Color.html("4a3219"))
			else:
				var t: float = clampf(Vector2(x, y).distance_to(centro) / 13.0, 0.0, 1.0)
				img.set_pixel(x, y, Color.html("fff6c2").lerp(Color.html("ffad42"), t))


func _capim(img: Image, rng: RandomNumberGenerator) -> void:
	## Fundo transparente: vira um "X" de dois planos cruzados no mundo.
	var verdes := _paleta(["4fae3e", "66c44f", "8ade63", "3a8a33"])
	for i: int in range(11):
		var x: int = rng.randi_range(3, L - 4)
		var altura: int = rng.randi_range(12, 26)
		var inclina: float = rng.randf_range(-0.25, 0.25)
		for k: int in range(altura):
			var px: int = clampi(x + int(inclina * k), 0, L - 1)
			var cor: Color = verdes[3] if k < 4 else (verdes[2] if k > altura - 4 else verdes[1])
			img.set_pixel(px, L - 1 - k, cor)


func _flor(img: Image, rng: RandomNumberGenerator, petala: Color, miolo: Color) -> void:
	var caule := Color.html("4a9e3a")
	for k: int in range(18):
		img.set_pixel(15, L - 1 - k, caule)
		if k == 6:
			img.set_pixel(16, L - 1 - k, caule)
			img.set_pixel(17, L - 2 - k, caule)
	var centro := Vector2i(15, L - 21)
	for dy: int in range(-4, 5):
		for dx: int in range(-4, 5):
			var d: float = Vector2(dx, dy).length()
			if d <= 2.0:
				img.set_pixel(centro.x + dx, centro.y + dy, miolo)
			elif d <= 4.2 and (absi(dx) <= 1 or absi(dy) <= 1 or d <= 3.3):
				img.set_pixel(centro.x + dx, centro.y + dy, petala.lightened(0.15 * rng.randf()))


func _muda(img: Image, rng: RandomNumberGenerator) -> void:
	## Broto de árvore: tronquinho fino e uma copa redonda. Fundo transparente.
	var casca := _paleta(["6e4826", "84592f", "9a6d38", "3f2814"])
	var verdes := _paleta(["3a8a33", "4fae3e", "8ade63", "2a6a28"])
	for k: int in range(14):
		_ponto(img, 15, L - 1 - k, casca[1])
		_ponto(img, 16, L - 1 - k, casca[0])
	_bolha(img, 16, L - 21, 7.0, verdes)
	_bolha(img, 10, L - 15, 4.0, verdes)
	_bolha(img, 22, L - 16, 4.5, verdes)
	for i: int in range(6):  # folhinhas claras
		_ponto(img, rng.randi_range(10, 22), L - rng.randi_range(17, 27), verdes[2])


func _cogumelo(img: Image, rng: RandomNumberGenerator) -> void:
	var pe := _paleta(["c9b99a", "e8dcc0", "fff6e0", "8a7a5c"])
	var capa := _paleta(["a8201c", "d63a30", "ff6b5a", "701410"])
	_bolha(img, 16, L - 12, 8.0, capa)
	for dy: int in range(1, 10):  # a copa é meia esfera: apaga a metade de baixo
		for dx: int in range(-9, 10):
			_ponto(img, 16 + dx, L - 12 + dy, Color(0, 0, 0, 0))
	for k: int in range(12):
		for dx: int in range(-2, 3):
			_ponto(img, 16 + dx, L - 1 - k, pe[1] if dx < 1 else pe[0])
	for i: int in range(4):  # pintas
		_ponto(img, rng.randi_range(11, 21), L - rng.randi_range(14, 18), Color.html("fff6e0"))
	_bolha(img, 25, L - 4, 3.0, capa)
	for k: int in range(3):
		_ponto(img, 25, L - 1 - k, pe[1])


func _trigo(
	img: Image, rng: RandomNumberGenerator, altura: int, haste: Color, espiga: bool
) -> void:
	for i: int in range(7):
		var x: int = 4 + i * 4 + rng.randi_range(-1, 1)
		var h: int = altura + rng.randi_range(-2, 2)
		var inclina: float = rng.randf_range(-0.12, 0.12)
		for k: int in range(h):
			var px: int = clampi(x + int(inclina * k), 0, L - 1)
			_ponto(img, px, L - 1 - k, haste.darkened(0.2) if k < 3 else haste)
		if espiga:
			var topo_x: int = clampi(x + int(inclina * h), 1, L - 2)
			for k: int in range(5):
				var grao := Color.html("f2c94c") if k % 2 == 0 else Color.html("d9a520")
				_ponto(img, topo_x, L - 1 - h - k, grao)
				if k > 0 and k < 4:
					_ponto(img, topo_x - 1, L - 1 - h - k, grao)
					_ponto(img, topo_x + 1, L - 1 - h - k, grao)


func _terra_arada_topo(img: Image, rng: RandomNumberGenerator) -> void:
	_terra(img, rng)
	for sulco: int in range(4):
		var y: int = 3 + sulco * 8
		for x: int in range(L):
			_ponto(img, x, y, Color.html("4a2c16"))
			_ponto(img, x, y + 1, Color.html("5f3b22"))
			_ponto(img, x, y - 1, Color.html("a3744d"))
func _vidro(img: Image) -> void:
	## Moldura opaca e brilhos; o miolo fica transparente (o shader do terreno
	## descarta alpha < 0,5), então o vidro deixa ver o outro lado.
	var moldura := Color.html("9cc6e0")
	var moldura_clara := Color.html("e8f6ff")
	var moldura_escura := Color.html("5f8fb0")
	for y: int in range(L):
		for x: int in range(L):
			var borda: int = mini(mini(x, L - 1 - x), mini(y, L - 1 - y))
			if borda == 0:
				img.set_pixel(x, y, moldura_clara if (x + y) % 2 == 0 else moldura)
			elif borda == 1:
				img.set_pixel(x, y, moldura_escura)
	for k: int in range(4, 12):  # reflexo diagonal
		img.set_pixel(k + 2, 16 - k, moldura_clara)
		img.set_pixel(k + 6, 16 - k, moldura_clara)
	for k: int in range(18, 24):
		img.set_pixel(k, 38 - k, moldura_clara)


func _porta(img: Image, rng: RandomNumberGenerator, parte_de_cima: bool) -> void:
	## Porta de tábuas na vertical, com moldura. A de baixo leva a maçaneta; a
	## de cima, uma janelinha de 4 vidros.
	var madeira := _paleta(["a8743a", "b98245", "cf9a58", "8e5f2c"])
	var n := _ruido(rng, 16)
	for y: int in range(L):
		for x: int in range(L):
			var v: float = n[y * L + (x / 2)]
			var cor: Color = madeira[2] if v > 0.66 else (madeira[1] if v > 0.4 else madeira[0])
			if x % 8 == 7:
				cor = Color.html("5e3c19")  # junta entre tábuas
			elif x % 8 == 0:
				cor = madeira[2]
			img.set_pixel(x, y, cor)
	var moldura := Color.html("5e3c19")
	for y: int in range(L):
		for x: int in range(L):
			var na_beira: bool = x < 2 or x > L - 3
			if (parte_de_cima and y < 2) or (not parte_de_cima and y > L - 3):
				na_beira = true
			if na_beira:
				img.set_pixel(x, y, moldura)
	if parte_de_cima:
		for y: int in range(7, 21):
			for x: int in range(8, 24):
				var travessa: bool = x == 15 or x == 16 or y == 13 or y == 14
				img.set_pixel(x, y, moldura if travessa else Color.html("a6d8fa"))
	else:
		for y: int in range(14, 19):
			for x: int in range(23, 28):
				img.set_pixel(x, y, Color.html("e8c24a") if y < 17 else Color.html("b8901f"))
