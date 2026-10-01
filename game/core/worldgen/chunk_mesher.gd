class_name ChunkMesher
extends RefCounted
## Constrói 1 ArrayMesh por chunk, só faces expostas (face culling). Puro e testável:
## não conhece ChunkManager nem coordenadas de mundo. Vizinhos dentro do chunk são
## lidos direto dos dados do ChunkData; o Callable só é consultado para posições
## fora do chunk em x/z (borda com o chunk vizinho). Acima do topo é ar; abaixo de
## y=0 conta como sólido (ninguém vê o fundo do mundo).
## Achado real (ADR-026): a versão anterior chamava o Callable e o SurfaceTool para
## cada face/vértice e custava ~250 ms por chunk mesmo nativo, o que travava a
## entrada no mundo na Web. Agora monta arrays compactos e um único add_surface.
## Ciclo 4 (ADR-027): cada vértice leva UV da face e uma cor que não é cor:
## r = oclusão de ambiente do canto, g = camada da textura / 255, b = direção da
## face / 255 (o shader reconstrói a normal) e a = brilho próprio. Assim são só
## 3 arrays por vértice, o que pesa no laço em GDScript. Os vizinhos ficam numa
## grade com 1 bloco de margem, então face e oclusão leem sem ramificar na borda.
## Ver docs/02-ARQUITETURA.md §4.2.

## Por face: deslocamento do vizinho, normal e os 4 cantos (anti-horário visto
## de fora; a ordem dos índices abaixo corrige pra convenção do Godot).
const _VIZINHOS := [
	Vector3i(0, 1, 0),
	Vector3i(0, -1, 0),
	Vector3i(0, 0, -1),
	Vector3i(0, 0, 1),
	Vector3i(1, 0, 0),
	Vector3i(-1, 0, 0),
]
const _CANTOS := [
	[Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)],
	[Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)],
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	[Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0)],
]
## Luz do canto pela quantidade de vizinhos que o encobrem (3 = livre).
const _LUZ_AO: Array[float] = [0.42, 0.62, 0.81, 1.0]
const _BORDA_DESCONHECIDA: int = 2
const _GRAMA_ID: int = 1
const _DENSIDADE_DECORACAO: float = 0.14  ## fração das gramas com capim ou flor
const _ALTURA_AGUA: float = 0.88  ## topo do lago um pouco abaixo da margem

## Cantos e UVs por (face * 4 + canto), montados uma vez (sem match por vértice).
static var _tab_cantos := PackedVector3Array()
static var _tab_uvs := PackedVector2Array()


func construir_malha(chunk: ChunkData, vizinho_solido: Callable) -> ArrayMesh:
	var dados: PackedByteArray = chunk.dados()
	var solidos: PackedByteArray = BlockRegistry.tabela_solidos()
	var texturas: PackedInt32Array = BlockRegistry.tabela_texturas()
	var brilhos: PackedFloat32Array = BlockRegistry.tabela_brilhos()
	var h: int = ChunkData.SIZE_H
	var v: int = ChunkData.SIZE_V

	## Grade de sólidos com margem de 1: índice (y+1)*a2 + (z+1)*h2 + (x+1).
	var h2: int = h + 2
	var a2: int = h2 * h2
	var grade := PackedByteArray()
	grade.resize(a2 * (v + 2))
	var y_max: int = -1  ## camada mais alta com bloco: acima dela não há face
	var i: int = -1
	for y in range(v):
		for z in range(h):
			var linha: int = (y + 1) * a2 + (z + 1) * h2 + 1
			for x in range(h):
				i += 1
				var id: int = dados[i]
				if id != BlockRegistry.AR_ID:
					grade[linha + x] = solidos[id]
					y_max = y
	if y_max < 0:
		return null
	for k in range(a2):
		grade[k] = 1  # abaixo de y=0: fundo do mundo nunca aparece
	_preencher_borda(grade, dados, vizinho_solido, y_max)
	if _tab_cantos.is_empty():
		for f in range(6):
			for c in range(4):
				_tab_cantos.append(_CANTOS[f][c])
				_tab_uvs.append(_uv(f, _CANTOS[f][c]))

	var desloc: PackedInt32Array = [a2, -a2, -h2, h2, 1, -1]
	var ao_a := PackedInt32Array()
	var ao_b := PackedInt32Array()
	_montar_deslocamentos_de_oclusao(ao_a, ao_b, h2, a2)

	var verts := PackedVector3Array()
	var cores_v := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var luz := PackedFloat32Array([1.0, 1.0, 1.0, 1.0])
	i = -1
	for y in range(y_max + 1):
		for z in range(h):
			for x in range(h):
				i += 1
				var id: int = dados[i]
				if solidos[id] == 0:
					continue  # ar e água (a água sai em construir_detalhes, sem colisão)
				var g: int = (y + 1) * a2 + (z + 1) * h2 + (x + 1)
				if (
					grade[g + a2] == 1
					and grade[g - a2] == 1
					and grade[g - h2] == 1
					and grade[g + h2] == 1
					and grade[g + 1] == 1
					and grade[g - 1] == 1
				):
					continue  # bloco enterrado: o caso mais comum, sai cedo
				var origem := Vector3(x, y, z)
				var brilho: float = brilhos[id]
				for f in range(6):
					var fora: int = g + desloc[f]
					if grade[fora] == 1:
						continue
					var base: int = verts.size()
					var camada_tex: float = texturas[id * 6 + f] / 255.0
					var face: float = f / 255.0
					for c in range(4):
						var k: int = f * 4 + c
						var lado_a: int = grade[fora + ao_a[k]]
						var lado_b: int = grade[fora + ao_b[k]]
						var nivel: int = 0
						if lado_a != 1 or lado_b != 1:
							var quina: int = grade[fora + ao_a[k] + ao_b[k]]
							nivel = (3 - int(lado_a == 1) - int(lado_b == 1) - int(quina == 1))
						var l: float = _LUZ_AO[nivel]
						luz[c] = l
						verts.append(origem + _tab_cantos[k])
						cores_v.append(Color(l, camada_tex, face, brilho))
						uvs.append(_tab_uvs[k])
					## Ordem invertida (0-2-1, 0-3-2): os cantos de _CANTOS estão em
					## sentido anti-horário visto de fora, e o Godot trata horário
					## como frente. Com 0-1-2 o mundo inteiro era desenhado do avesso
					## desde a F2 (ADR-027). A diagonal do quad acompanha a oclusão
					## pra o escurecido não formar um "X" no meio da face.
					var d: int = 0 if luz[0] + luz[2] >= luz[1] + luz[3] else 1
					indices.append(base + d)
					indices.append(base + (2 + d) % 4)
					indices.append(base + (1 + d) % 4)
					indices.append(base + d)
					indices.append(base + (3 + d) % 4)
					indices.append(base + (2 + d) % 4)

	if indices.is_empty():
		return null
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cores_v
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return malha


func _preencher_borda(
	grade: PackedByteArray, dados: PackedByteArray, vizinho_solido: Callable, y_max: int
) -> void:
	## A margem em x/z só é consultada em volta de bloco na beira do chunk (face e
	## oclusão leem a vizinhança 3x3x3 dele). Bloco no meio não chama o Callable.
	var h: int = ChunkData.SIZE_H
	var v: int = ChunkData.SIZE_V
	var h2: int = h + 2
	var a2: int = h2 * h2
	for y in range(v):
		for z in range(1, h + 1):
			grade[(y + 1) * a2 + z * h2] = _BORDA_DESCONHECIDA
			grade[(y + 1) * a2 + z * h2 + h + 1] = _BORDA_DESCONHECIDA
		for x in range(h2):
			grade[(y + 1) * a2 + x] = _BORDA_DESCONHECIDA
			grade[(y + 1) * a2 + (h + 1) * h2 + x] = _BORDA_DESCONHECIDA
	var camada: int = h * h
	for y in range(y_max + 1):
		for z in range(h):
			var passo_x: int = 1 if z == 0 or z == h - 1 else h - 1  # só a beira
			for x in range(0, h, passo_x):
				if dados[y * camada + z * h + x] == BlockRegistry.AR_ID:
					continue
				for dy in range(-1, 2):
					var yy: int = y + dy
					if yy < 0 or yy >= v:
						continue
					for dz in range(-1, 2):
						for dx in range(-1, 2):
							var lx: int = x + dx
							var lz: int = z + dz
							if lx >= 0 and lx < h and lz >= 0 and lz < h:
								continue
							var g: int = (yy + 1) * a2 + (lz + 1) * h2 + (lx + 1)
							if grade[g] == _BORDA_DESCONHECIDA:
								grade[g] = 1 if vizinho_solido.call(lx, yy, lz) else 0


func _montar_deslocamentos_de_oclusao(
	ao_a: PackedInt32Array, ao_b: PackedInt32Array, h2: int, a2: int
) -> void:
	## Para cada face e canto: os dois vizinhos laterais na camada de fora da
	## face (eixos tangentes), apontando pro lado do canto.
	var passo := Vector3i(1, a2, h2)  # x, y, z
	for f in range(6):
		var eixo_normal: int = 1 if f < 2 else (2 if f < 4 else 0)
		var tangentes: Array[int] = []
		for e: int in [0, 1, 2]:
			if e != eixo_normal:
				tangentes.append(e)
		for c in range(4):
			var canto: Vector3 = _CANTOS[f][c]
			var sinal_a: int = 1 if canto[tangentes[0]] > 0.5 else -1
			var sinal_b: int = 1 if canto[tangentes[1]] > 0.5 else -1
			ao_a.append(sinal_a * passo[tangentes[0]])
			ao_b.append(sinal_b * passo[tangentes[1]])


static func _uv(face: int, canto: Vector3) -> Vector2:
	## Textura em pé nas laterais (v=0 no alto), vista de fora sem espelhar.
	match face:
		0, 1:
			return Vector2(canto.x, canto.z)
		2:
			return Vector2(1.0 - canto.x, 1.0 - canto.y)
		3:
			return Vector2(canto.x, 1.0 - canto.y)
		4:
			return Vector2(1.0 - canto.z, 1.0 - canto.y)
		_:
			return Vector2(canto.z, 1.0 - canto.y)


func construir_detalhes(chunk: ChunkData, semente: int) -> Dictionary:
	## O que fica fora da colisão (Ciclo 4, ADR-027): superfície dos lagos e a
	## decoração de capim e flores. A decoração não é bloco salvo: nasce de
	## "grama com ar em cima", então some sozinha quando a grama é quebrada ou
	## coberta. Devolve {"agua": ArrayMesh ou null, "decoracao": ArrayMesh ou null}.
	var dados: PackedByteArray = chunk.dados()
	var h: int = ChunkData.SIZE_H
	var v: int = ChunkData.SIZE_V
	var camada: int = h * h
	var agua := _NovaMalha.new()
	var decoracao := _NovaMalha.new()
	var tiles: PackedInt32Array = [
		AtlasBlocos.indice("capim"),
		AtlasBlocos.indice("capim"),
		AtlasBlocos.indice("capim"),
		AtlasBlocos.indice("flor_amarela"),
		AtlasBlocos.indice("flor_rosa"),
		AtlasBlocos.indice("flor_lumen"),
	]
	for y in range(v - 1):
		for z in range(h):
			for x in range(h):
				var i: int = y * camada + z * h + x
				var id: int = dados[i]
				var acima: int = dados[i + camada]
				if id == BlockRegistry.AGUA_ID and acima == BlockRegistry.AR_ID:
					_quad_de_agua(agua, Vector3(x, y, z))
				elif id == _GRAMA_ID and acima == BlockRegistry.AR_ID:
					var sorteio: float = _hash01(semente, x + 31 * z, y)
					if sorteio < _DENSIDADE_DECORACAO:
						var tipo: int = int(sorteio / _DENSIDADE_DECORACAO * tiles.size())
						var tile: int = tiles[mini(tipo, tiles.size() - 1)]
						var brilho: float = 0.8 if tipo == tiles.size() - 1 else 0.0
						_cruz(decoracao, Vector3(x, y + 1, z), tile, brilho, sorteio)
	return {"agua": agua.fechar(), "decoracao": decoracao.fechar()}


func _quad_de_agua(m: _NovaMalha, origem: Vector3) -> void:
	var base: int = m.verts.size()
	for canto: Vector3 in _CANTOS[0]:
		m.verts.append(origem + Vector3(canto.x, _ALTURA_AGUA, canto.z))
		m.cores.append(Color(1, 0, 0, 0))
		m.uvs.append(Vector2(canto.x, canto.z))
	m.indices.append_array([base, base + 2, base + 1, base, base + 3, base + 2])


func _cruz(m: _NovaMalha, origem: Vector3, tile: int, brilho: float, sorteio: float) -> void:
	## Dois planos cruzados em X, um pouco deslocados pra não ficarem alinhados.
	var desvio := Vector3(fmod(sorteio * 97.0, 0.3) - 0.15, 0.0, fmod(sorteio * 57.0, 0.3) - 0.15)
	var c := origem + Vector3(0.5, 0.0, 0.5) + desvio
	var r: float = 0.42
	var altura: float = 0.75 + fmod(sorteio * 13.0, 0.3)
	var camada_tex: float = tile / 255.0
	for diagonal: Vector3 in [Vector3(r, 0, r), Vector3(r, 0, -r)]:
		var base: int = m.verts.size()
		(
			m
			. verts
			. append_array(
				[
					c - diagonal,
					c - diagonal + Vector3(0, altura, 0),
					c + diagonal + Vector3(0, altura, 0),
					c + diagonal,
				]
			)
		)
		for uv: Vector2 in [Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]:
			m.uvs.append(uv)
			m.cores.append(Color(1.0, camada_tex, 0.0, brilho))
		m.indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])


static func _hash01(semente: int, a: int, b: int) -> float:
	var hh: int = (semente * 374761393 + a * 668265263) & 0x7fffffff
	hh = ((hh ^ (hh >> 13)) * 1274126177) & 0x7fffffff
	hh = (hh ^ (b * 2246822519)) & 0x7fffffff
	hh = (hh ^ (hh >> 16)) & 0x7fffffff
	return float(hh) / float(0x7fffffff)


class _NovaMalha:
	var verts := PackedVector3Array()
	var cores := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	func fechar() -> ArrayMesh:
		if indices.is_empty():
			return null
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_COLOR] = cores
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		var malha := ArrayMesh.new()
		malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return malha
