extends SceneTree
## Gera assets/textures/icones_itens.png: ícones 32 x 32 dos itens em pixel art
## própria desenhada por código (Ciclo 6, 6B), numa grade de IconesItens.COLUNAS
## colunas na ordem de IconesItens.NOMES. Item que é bloco (bloco_id != 0) copia
## o tile lateral do AtlasBlocos; os demais são desenhados aqui e ganham um
## contorno escuro de 1 px pra ler bem sobre o fundo dos slots. Determinístico.
## Uso: godot --headless -s res://tools/gerar_icones.gd

const L: int = IconesItens.LADO
const CONTORNO := Color("1b1420")
## Paletas [sombra, base, luz].
const CABO: Array[String] = ["5e3c19", "8e5f2c", "b98245"]
const MADEIRA: Array[String] = ["8e5f2c", "b98245", "cf9a58"]
const PEDRA: Array[String] = ["6c7387", "9aa1b3", "c3c8d2"]
const FERRITE: Array[String] = ["7a3f1c", "c4753a", "e8a066"]
const CRISTAL: Array[String] = ["a87612", "ffd34d", "fff0b0"]
const VIDRO: Array[String] = ["7fa6c9", "b8d8f2", "e8f6ff"]
const MACA: Array[String] = ["a01020", "d8202e", "ff6b6b"]
const MACA_ASSADA: Array[String] = ["7a3a10", "b0602a", "e0975a"]
const POCAO_CURA: Array[String] = ["a01020", "e23b4e", "ff8a94"]
const AZUL: Array[String] = ["1f4fa8", "3a86ff", "8ab8ff"]
const CARVAO: Array[String] = ["1d1a24", "3a3545", "5a526b"]
const AMBAR: Array[String] = ["c86e0a", "f0a020", "ffd070"]


func _init() -> void:
	var nomes: Array[String] = IconesItens.NOMES
	var colunas: int = IconesItens.COLUNAS
	var linhas: int = ceili(nomes.size() / float(colunas))
	var folha := Image.create(colunas * L, linhas * L, false, Image.FORMAT_RGBA8)
	var atlas: Image = Image.load_from_file(ProjectSettings.globalize_path(AtlasBlocos.CAMINHO_PNG))
	for i: int in range(nomes.size()):
		var icone := _desenhar(nomes[i], atlas)
		var destino := Vector2i((i % colunas) * L, (i / colunas) * L)
		folha.blit_rect(icone, Rect2i(0, 0, L, L), destino)
	var caminho := ProjectSettings.globalize_path(IconesItens.CAMINHO_PNG)
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	folha.save_png(caminho)
	print("ICONES ", caminho, " ", folha.get_size())
	quit()


func _desenhar(item_id: String, atlas: Image) -> Image:
	var def: ItemDef = ItemRegistry.get_item(item_id)
	var img := Image.create(L, L, false, Image.FORMAT_RGBA8)
	if def.bloco_id != 0 and item_id != "semente":  # semente tem desenho próprio
		_copiar_tile(img, atlas, BlockRegistry.get_block(def.bloco_id).textura_lado)
		return img
	match item_id:
		"picareta_madeira":
			_picareta(img, MADEIRA)
		"picareta_pedra":
			_picareta(img, PEDRA)
		"picareta_ferrite":
			_picareta(img, FERRITE)
		"picareta_cristal_dourado":
			_picareta(img, CRISTAL)
		"machado_madeira":
			_machado(img, MADEIRA)
		"machado_ferrite":
			_machado(img, FERRITE)
		"espada_pedra":
			_espada(img, PEDRA)
		"espada_cristal_dourado":
			_espada(img, CRISTAL)
		"graveto":
			_graveto(img)
		"tabua":
			_tabua(img)
		"bancada":
			_bancada(img)
		"fornalha":
			_fornalha(img)
		"maca":
			_maca(img, MACA, false)
		"maca_assada":
			_maca(img, MACA_ASSADA, true)
		"pocao_cura":
			_pocao(img, POCAO_CURA)
		"pocao_maior":
			_pocao(img, CRISTAL)
		"cubo_captura":
			_cubo(img, AZUL)
		"cubo_captura_avancado":
			_cubo(img, CRISTAL)
		"carvao":
			_pedras(img, CARVAO)
		"ferrite":
			_lingote(img, FERRITE)
		"cristal_dourado":
			_gema(img, CRISTAL)
		"ambar":
			_gota(img, AMBAR)
		"semente":
			_semente(img)
		"trigo":
			_trigo_item(img)
		"pao":
			_pao(img)
		"enxada_madeira":
			_enxada(img, MADEIRA)
		_:
			_quadrado(img, def.cor)
	_contornar(img)
	return img


# --- utilidades -------------------------------------------------------------


func _cores(hexes: Array[String]) -> Array[Color]:
	var cores: Array[Color] = []
	for h: String in hexes:
		cores.append(Color.html(h))
	return cores


func _ponto(img: Image, x: int, y: int, cor: Color) -> void:
	if x >= 0 and y >= 0 and x < L and y < L:
		img.set_pixel(x, y, cor)


func _retangulo(img: Image, x0: int, y0: int, x1: int, y1: int, cor: Color) -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			_ponto(img, x, y, cor)


func _disco(img: Image, centro: Vector2, raio: float, cor: Color) -> void:
	var r: int = ceili(raio)
	var cx: int = roundi(centro.x)
	var cy: int = roundi(centro.y)
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			if Vector2(cx + dx, cy + dy).distance_to(centro) <= raio:
				_ponto(img, cx + dx, cy + dy, cor)


func _linha(img: Image, de: Vector2, ate: Vector2, espessura: float, cor: Color) -> void:
	## Segmento grosso: discos encadeados de "de" até "ate".
	var passos: int = maxi(1, ceili(de.distance_to(ate) * 2.0))
	for k: int in range(passos + 1):
		_disco(img, de.lerp(ate, float(k) / passos), espessura / 2.0, cor)


func _esfera(img: Image, centro: Vector2, raio: float, paleta: Array[Color]) -> void:
	## Disco sombreado: luz no alto à esquerda, sombra embaixo à direita.
	var r: int = ceili(raio)
	var cx: int = roundi(centro.x)
	var cy: int = roundi(centro.y)
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			var d: float = Vector2(cx + dx, cy + dy).distance_to(centro)
			if d > raio:
				continue
			var luz: float = (-dx - dy) / (raio * 2.0) + 0.5
			var cor: Color = paleta[1]
			if d > raio - 1.5 and dx + dy > 0:
				cor = paleta[0]
			elif luz > 0.72:
				cor = paleta[2]
			_ponto(img, cx + dx, cy + dy, cor)


func _cabo(img: Image, de: Vector2, ate: Vector2) -> void:
	## Cabo de madeira diagonal com fio de luz em cima e sombra embaixo.
	var cores := _cores(CABO)
	var luz := Vector2(-0.7, -0.7)
	_linha(img, de, ate, 3.0, cores[1])
	_linha(img, de + luz, ate + luz, 1.0, cores[2])
	_linha(img, de - luz, ate - luz, 1.0, cores[0])


func _contornar(img: Image) -> void:
	## Contorno escuro de 1 px: pixel transparente vizinho de um pixel pintado.
	var base: Image = img.duplicate()
	var vizinhos: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	for y: int in range(L):
		for x: int in range(L):
			if base.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in vizinhos:
				var px: int = x + d.x
				var py: int = y + d.y
				if px >= 0 and py >= 0 and px < L and py < L and base.get_pixel(px, py).a > 0.0:
					img.set_pixel(x, y, CONTORNO)
					break


# --- ícones -----------------------------------------------------------------


func _copiar_tile(img: Image, atlas: Image, nome: String) -> void:
	var i: int = maxi(0, AtlasBlocos.indice(nome))
	var lado: int = AtlasBlocos.LADO
	var origem := Vector2i((i % AtlasBlocos.COLUNAS) * lado, (i / AtlasBlocos.COLUNAS) * lado)
	img.blit_rect(atlas, Rect2i(origem, Vector2i(lado, lado)), Vector2i.ZERO)


func _picareta(img: Image, tier: Array[String]) -> void:
	var cores := _cores(tier)
	var centro := Vector2(19.5, 12.5)
	_cabo(img, Vector2(5.0, 27.0), centro)
	## Cabeça: arco por cima da ponta do cabo, mais escuro na borda de fora.
	for faixa: int in range(4):
		var raio: float = 6.5 + faixa
		var cor: Color = cores[maxi(0, 2 - faixa)]
		for grau: int in range(188, 353, 3):
			var ang: float = deg_to_rad(grau)
			_disco(img, centro + Vector2(cos(ang), sin(ang)) * raio, 0.8, cor)


func _machado(img: Image, tier: Array[String]) -> void:
	var cores := _cores(tier)
	_cabo(img, Vector2(5.0, 27.0), Vector2(18.0, 10.0))
	## Lâmina à direita da ponta do cabo, com o gume bojudo e claro.
	for y: int in range(4, 19):
		var bojo: int = mini(y - 4, 18 - y)
		var direita: int = 22 + mini(bojo, 6)
		for x: int in range(16, direita + 1):
			var cor: Color = cores[1]
			if x == direita or y == 4:
				cor = cores[2]
			elif x == 16 or y >= 17:
				cor = cores[0]
			_ponto(img, x, y, cor)


func _espada(img: Image, tier: Array[String]) -> void:
	var cores := _cores(tier)
	var cabo := _cores(CABO)
	var ouro := _cores(CRISTAL)
	var ponta := Vector2(26.0, 5.0)
	var base := Vector2(13.0, 18.0)
	var luz := Vector2(-0.8, -0.8)
	_linha(img, base, ponta, 3.2, cores[1])
	_linha(img, base + luz, ponta + luz, 1.0, cores[2])
	_linha(img, base - luz, ponta - luz, 1.0, cores[0])
	_disco(img, ponta + Vector2(0.7, -0.7), 0.8, cores[2])
	## Guarda perpendicular, punho e pomo.
	_linha(img, Vector2(9.0, 15.0), Vector2(17.0, 23.0), 2.2, ouro[1])
	_linha(img, Vector2(12.0, 19.5), Vector2(6.5, 25.0), 2.6, cabo[0])
	_disco(img, Vector2(5.5, 26.5), 1.6, ouro[1])


func _graveto(img: Image) -> void:
	var cores := _cores(CABO)
	var luz := Vector2(-0.7, -0.7)
	_linha(img, Vector2(7.0, 25.0), Vector2(24.0, 7.0), 2.4, cores[1])
	_linha(img, Vector2(7.0, 25.0) + luz, Vector2(24.0, 7.0) + luz, 0.9, cores[2])
	_linha(img, Vector2(15.0, 16.0), Vector2(20.0, 15.0), 1.6, cores[1])  # galhinho
	_disco(img, Vector2(20.5, 14.5), 1.3, Color.html("5fae3c"))  # folhinha
	_linha(img, Vector2(12.0, 19.5), Vector2(9.5, 18.5), 1.4, cores[0])  # nó


func _tabua(img: Image) -> void:
	var cores := _cores(MADEIRA)
	_retangulo(img, 3, 11, 28, 21, cores[1])
	_retangulo(img, 3, 11, 28, 11, cores[2])
	_retangulo(img, 3, 21, 28, 21, cores[0])
	_retangulo(img, 28, 11, 28, 21, cores[0])
	## Veios e um nó.
	_retangulo(img, 6, 14, 12, 14, cores[0])
	_retangulo(img, 15, 14, 22, 14, cores[0])
	_retangulo(img, 8, 18, 13, 18, cores[0])
	_retangulo(img, 18, 18, 25, 18, cores[0])
	_disco(img, Vector2(21.0, 16.0), 1.4, cores[0])
	_ponto(img, 21, 16, cores[1])


func _bancada(img: Image) -> void:
	var madeira := _cores(MADEIRA)
	var escuro := _cores(CABO)
	var metal := _cores(PEDRA)
	## Tampo e pernas.
	_retangulo(img, 3, 9, 28, 13, madeira[1])
	_retangulo(img, 3, 9, 28, 9, madeira[2])
	_retangulo(img, 3, 13, 28, 13, madeira[0])
	_retangulo(img, 4, 14, 6, 27, escuro[1])
	_retangulo(img, 25, 14, 27, 27, escuro[1])
	_retangulo(img, 6, 14, 6, 27, escuro[0])
	_retangulo(img, 27, 14, 27, 27, escuro[0])
	## Gaveta no meio com puxador.
	_retangulo(img, 7, 15, 24, 22, madeira[0])
	_retangulo(img, 9, 16, 22, 21, madeira[1])
	_retangulo(img, 14, 18, 17, 19, escuro[0])
	## Martelo e serra em cima.
	_retangulo(img, 7, 5, 9, 8, metal[1])
	_retangulo(img, 10, 6, 14, 7, escuro[1])
	_retangulo(img, 18, 5, 26, 7, metal[2])
	for x: int in range(18, 27, 2):
		_ponto(img, x, 8, metal[2])


func _fornalha(img: Image) -> void:
	var pedra := _cores(PEDRA)
	var fogo := _cores(["c23a05", "ff6a1a", "ffd447"] as Array[String])
	## Corpo de pedra com juntas desencontradas.
	_retangulo(img, 4, 3, 27, 28, pedra[1])
	for y: int in range(3, 29):
		var fileira: int = (y - 3) / 6
		var deslocamento: int = 3 if fileira % 2 == 1 else 0
		for x: int in range(4, 28):
			if (y - 3) % 6 == 5 or (x + deslocamento) % 8 == 7:
				_ponto(img, x, y, pedra[0])
			elif (x * 7 + y * 13) % 11 == 0:
				_ponto(img, x, y, pedra[2])
	## Fenda de cima e boca com fogo.
	_retangulo(img, 10, 7, 21, 10, CONTORNO)
	_retangulo(img, 11, 8, 20, 9, Color.html("3a3545"))
	_retangulo(img, 10, 16, 21, 26, CONTORNO)
	_retangulo(img, 11, 22, 20, 26, fogo[0])
	_retangulo(img, 12, 20, 19, 25, fogo[1])
	_retangulo(img, 13, 23, 18, 26, fogo[2])
	_ponto(img, 13, 19, fogo[1])
	_ponto(img, 17, 18, fogo[1])
	_ponto(img, 15, 19, fogo[2])
	_ponto(img, 15, 18, fogo[1])


func _maca(img: Image, tons: Array[String], assada: bool) -> void:
	var cores := _cores(tons)
	_esfera(img, Vector2(16.0, 18.0), 9.0, cores)
	_disco(img, Vector2(12.5, 14.0), 1.8, cores[2])
	_ponto(img, 11, 13, Color.html("ffffff"))
	## Cabinho; folha na maçã crua, vapor na assada.
	_retangulo(img, 15, 5, 16, 10, Color.html("5e3c19"))
	if assada:
		for k: int in range(3):
			_ponto(img, 10 + k * 5, 4 - (k % 2), Color.html("e8e8f0"))
			_ponto(img, 11 + k * 5, 2 - (k % 2), Color.html("f6f6fa"))
	else:
		_disco(img, Vector2(19.5, 8.5), 2.0, Color.html("5fae3c"))
		_ponto(img, 21, 8, Color.html("8ade63"))


func _pocao(img: Image, liquido: Array[String]) -> void:
	var vidro := _cores(VIDRO)
	var liq := _cores(liquido)
	var bojo := Vector2(16.0, 20.0)
	## Bojo, gargalo e rolha.
	_disco(img, bojo, 9.0, vidro[1])
	_retangulo(img, 13, 5, 18, 13, vidro[1])
	_retangulo(img, 13, 5, 13, 13, vidro[2])
	_retangulo(img, 18, 5, 18, 13, vidro[0])
	_retangulo(img, 12, 2, 19, 5, Color.html("8e5f2c"))
	_retangulo(img, 12, 2, 19, 2, Color.html("b98245"))
	## Líquido na metade de baixo do bojo, mais escuro na borda direita.
	for y: int in range(17, 30):
		for x: int in range(6, 27):
			var d: float = Vector2(x, y).distance_to(bojo)
			if d > 8.0:
				continue
			var cor: Color = liq[1]
			if y == 17:
				cor = liq[2]
			elif d > 6.5 and x > 16:
				cor = liq[0]
			_ponto(img, x, y, cor)
	## Reflexo do vidro e uma bolha.
	_linha(img, Vector2(10.0, 17.0), Vector2(9.0, 21.0), 1.2, vidro[2])
	_disco(img, Vector2(12.0, 24.5), 0.9, liq[2])


func _cubo(img: Image, tons: Array[String]) -> void:
	var cores := _cores(tons)
	_retangulo(img, 6, 6, 25, 25, cores[1])
	_retangulo(img, 6, 6, 25, 7, cores[2])
	_retangulo(img, 6, 6, 7, 25, cores[2])
	_retangulo(img, 6, 24, 25, 25, cores[0])
	_retangulo(img, 24, 6, 25, 25, cores[0])
	## Faixa escura no meio com o botão de captura.
	_retangulo(img, 6, 14, 25, 17, CONTORNO)
	_disco(img, Vector2(15.5, 15.5), 2.6, Color.html("f6f6fa"))
	_disco(img, Vector2(15.5, 15.5), 1.2, cores[1])
	_retangulo(img, 9, 9, 10, 9, Color.html("ffffff"))
	_ponto(img, 9, 10, Color.html("ffffff"))


func _pedras(img: Image, tons: Array[String]) -> void:
	var cores := _cores(tons)
	_esfera(img, Vector2(11.5, 19.5), 6.0, cores)
	_esfera(img, Vector2(20.0, 20.0), 6.5, cores)
	_esfera(img, Vector2(16.0, 12.5), 5.5, cores)
	_ponto(img, 13, 10, Color.html("8a8296"))
	_ponto(img, 14, 10, Color.html("8a8296"))


func _lingote(img: Image, tons: Array[String]) -> void:
	var cores := _cores(tons)
	## Face de cima em perspectiva (trapézio claro) e corpo.
	for y: int in range(9, 24):
		var recuo: int = maxi(0, 13 - y)
		var cor: Color = cores[2] if y < 13 else cores[1]
		if y >= 22:
			cor = cores[0]
		_retangulo(img, 4 + recuo, y, 27 - recuo, y, cor)
	_retangulo(img, 4, 13, 4, 23, cores[0])
	_retangulo(img, 27, 13, 27, 23, cores[0])
	_retangulo(img, 9, 10, 20, 10, Color.html("ffd6b0"))


func _gema(img: Image, tons: Array[String]) -> void:
	var cores := _cores(tons)
	var cima: int = 3
	var cintura: int = 12
	var baixo: int = 29
	var meio: float = 15.5
	for y: int in range(cima, baixo + 1):
		var meia: float = 8.0 * (y - cima) / float(cintura - cima)
		if y > cintura:
			meia = 8.0 * (baixo - y) / float(baixo - cintura)
		for x: int in range(floori(meio - meia), ceili(meio + meia) + 1):
			if absf(x - meio) > meia + 0.5:
				continue
			var cor: Color = cores[1]
			if y == cintura:
				cor = cores[2]
			elif x < meio - meia * 0.35 or y < cintura - 3:
				cor = cores[2]
			elif x > meio + meia * 0.45 or y > cintura + 9:
				cor = cores[0]
			_ponto(img, x, y, cor)
	_ponto(img, 12, 8, Color.html("ffffff"))
	_ponto(img, 13, 7, Color.html("ffffff"))


func _gota(img: Image, tons: Array[String]) -> void:
	var cores := _cores(tons)
	_esfera(img, Vector2(16.0, 19.0), 8.5, cores)
	## Bico da gota pra cima.
	for y: int in range(5, 13):
		var meia: float = 0.5 + (y - 5) * 0.75
		for x: int in range(floori(15.5 - meia), ceili(15.5 + meia) + 1):
			if absf(x - 15.5) <= meia:
				_ponto(img, x, y, cores[1] if x <= 15 else cores[0])
	_disco(img, Vector2(12.5, 15.0), 1.8, cores[2])
	_ponto(img, 11, 14, Color.html("fff4c8"))
	## Inseto preso no âmbar.
	_retangulo(img, 18, 20, 19, 20, Color.html("5e3c19"))
	_ponto(img, 18, 21, Color.html("5e3c19"))


func _quadrado(img: Image, cor: Color) -> void:
	## Reserva para item sem desenho próprio: quadrado na cor do ItemDef.
	_retangulo(img, 5, 5, 26, 26, cor)
	_retangulo(img, 5, 5, 26, 6, cor.lightened(0.3))
	_retangulo(img, 5, 25, 26, 26, cor.darkened(0.3))


func _enxada(img: Image, tier: Array[String]) -> void:
	var cores := _cores(tier)
	_cabo(img, Vector2(5.0, 27.0), Vector2(19.0, 9.0))
	## Lâmina chata dobrada pra baixo na ponta do cabo.
	_retangulo(img, 15, 5, 26, 8, cores[1])
	_retangulo(img, 15, 5, 26, 5, cores[2])
	_retangulo(img, 15, 8, 26, 8, cores[0])
	_retangulo(img, 23, 9, 26, 13, cores[1])
	_retangulo(img, 26, 9, 26, 13, cores[0])
	_retangulo(img, 23, 9, 23, 13, cores[2])


func _semente(img: Image) -> void:
	var cores := _cores(["6b4a1e", "a8782f", "d9a95a"] as Array[String])
	for p: Vector2 in [
		Vector2(16, 16), Vector2(9, 20), Vector2(22, 11), Vector2(21, 22), Vector2(10, 10)
	]:
		_esfera(img, p, 3.4, cores)
	_ponto(img, 17, 12, cores[2])
	_ponto(img, 10, 16, cores[2])


func _trigo_item(img: Image) -> void:
	var haste := Color.html("b89a2e")
	var grao := _cores(["a87612", "e0b830", "ffe27a"] as Array[String])
	var topos: Array[Vector2] = [Vector2(10, 8), Vector2(16, 6), Vector2(22, 8)]
	var bases: Array[Vector2] = [Vector2(13, 28), Vector2(16, 28), Vector2(19, 28)]
	for i: int in range(3):
		_linha(img, bases[i], topos[i], 1.6, haste)
		for k: int in range(5):
			var cor: Color = grao[1] if k % 2 == 0 else grao[0]
			_disco(img, topos[i] + Vector2((k % 2) * 1.5 - 0.75, k * 2.2), 1.6, cor)
		_ponto(img, roundi(topos[i].x), roundi(topos[i].y), grao[2])


func _pao(img: Image) -> void:
	var cores := _cores(["8a4a16", "c47a2a", "e8a859"] as Array[String])
	_esfera(img, Vector2(16.0, 17.0), 10.0, cores)
	for x: int in range(8, 25):  # fundo achatado
		_ponto(img, x, 26, cores[0])
	for g: int in range(3):  # cortes da casca
		_linha(img, Vector2(11.0 + g * 5.0, 12.0), Vector2(13.0 + g * 5.0, 18.0), 1.2, cores[0])
		_ponto(img, 12 + g * 5, 13, cores[2])
