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
const _NORMAIS := [
	Vector3(0, 1, 0),
	Vector3(0, -1, 0),
	Vector3(0, 0, -1),
	Vector3(0, 0, 1),
	Vector3(1, 0, 0),
	Vector3(-1, 0, 0),
]
const _CANTOS := [
	[Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)],
	[Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)],
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	[Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0)],
]


func construir_malha(chunk: ChunkData, vizinho_solido: Callable) -> ArrayMesh:
	var dados: PackedByteArray = chunk.dados()
	var solidos: PackedByteArray = BlockRegistry.tabela_solidos()
	var cores: PackedColorArray = BlockRegistry.tabela_cores()
	var verts := PackedVector3Array()
	var normais := PackedVector3Array()
	var cores_v := PackedColorArray()
	var indices := PackedInt32Array()
	var h: int = ChunkData.SIZE_H
	var v: int = ChunkData.SIZE_V
	var camada: int = h * h

	var ocultas: Array[bool] = [false, false, false, false, false, false]
	var i: int = -1
	for y in range(v):
		for z in range(h):
			for x in range(h):
				i += 1
				var id: int = dados[i]
				if id == BlockRegistry.AR_ID:
					continue
				## Vizinhos por aritmética direta de índice (ordem igual a _VIZINHOS:
				## cima, baixo, norte z-1, sul z+1, leste x+1, oeste x-1). Só a borda
				## em x/z consulta o Callable; y fora do chunk é ar.
				ocultas[0] = y + 1 < v and solidos[dados[i + camada]] == 1
				ocultas[1] = y == 0 or solidos[dados[i - camada]] == 1  # fundo do mundo nunca aparece
				ocultas[2] = (
					solidos[dados[i - h]] == 1 if z > 0 else vizinho_solido.call(x, y, -1)
				)
				ocultas[3] = (
					solidos[dados[i + h]] == 1 if z < h - 1 else vizinho_solido.call(x, y, h)
				)
				ocultas[4] = (
					solidos[dados[i + 1]] == 1 if x < h - 1 else vizinho_solido.call(h, y, z)
				)
				ocultas[5] = solidos[dados[i - 1]] == 1 if x > 0 else vizinho_solido.call(-1, y, z)
				if (
					ocultas[0]
					and ocultas[1]
					and ocultas[2]
					and ocultas[3]
					and ocultas[4]
					and ocultas[5]
				):
					continue  # bloco enterrado: o caso mais comum, sai cedo
				var cor: Color = cores[id]
				var origem := Vector3(x, y, z)
				for f in range(6):
					if ocultas[f]:
						continue
					var base: int = verts.size()
					var cantos: Array = _CANTOS[f]
					var normal: Vector3 = _NORMAIS[f]
					for c in range(4):
						var canto: Vector3 = cantos[c]
						verts.append(origem + canto)
						normais.append(normal)
						cores_v.append(cor)
					## Ordem invertida (0-2-1, 0-3-2): os cantos de _CANTOS estão em
					## sentido anti-horário visto de fora, e o Godot trata horário
					## como frente. Com 0-1-2 o mundo inteiro era desenhado do avesso
					## desde a F2 (via-se o fundo do mundo e o teto das cavernas por
					## dentro) e a física via as faces viradas pra dentro (ADR-027).
					indices.append(base)
					indices.append(base + 2)
					indices.append(base + 1)
					indices.append(base)
					indices.append(base + 3)
					indices.append(base + 2)

	if indices.is_empty():
		return null
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normais
	arrays[Mesh.ARRAY_COLOR] = cores_v
	arrays[Mesh.ARRAY_INDEX] = indices
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return malha
