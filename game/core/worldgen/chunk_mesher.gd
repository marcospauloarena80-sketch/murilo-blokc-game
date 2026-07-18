class_name ChunkMesher
extends RefCounted
## Constrói 1 ArrayMesh por chunk, só faces expostas (face culling). Puro e testável:
## não conhece ChunkManager nem coordenadas de mundo — recebe um Callable que resolve
## se a posição vizinha (em coordenadas locais, podendo sair dos limites do chunk) é sólida.
## Cor por bloco é placeholder até a fase de assets/atlas (ADR-009).
## Ver docs/02-ARQUITETURA.md §4.2.

const FACES := {
	"top":
	{
		"verts": [Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)],
		"normal": Vector3(0, 1, 0),
		"vizinho": Vector3i(0, 1, 0)
	},
	"bottom":
	{
		"verts": [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],
		"normal": Vector3(0, -1, 0),
		"vizinho": Vector3i(0, -1, 0)
	},
	"north":
	{
		"verts": [Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)],
		"normal": Vector3(0, 0, -1),
		"vizinho": Vector3i(0, 0, -1)
	},
	"south":
	{
		"verts": [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)],
		"normal": Vector3(0, 0, 1),
		"vizinho": Vector3i(0, 0, 1)
	},
	"east":
	{
		"verts": [Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],
		"normal": Vector3(1, 0, 0),
		"vizinho": Vector3i(1, 0, 0)
	},
	"west":
	{
		"verts": [Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0)],
		"normal": Vector3(-1, 0, 0),
		"vizinho": Vector3i(-1, 0, 0)
	},
}


func construir_malha(chunk: ChunkData, vizinho_solido: Callable) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces_adicionadas := 0

	for x in range(ChunkData.SIZE_H):
		for z in range(ChunkData.SIZE_H):
			for y in range(ChunkData.SIZE_V):
				var id := chunk.get_block(x, y, z)
				if id == BlockRegistry.AR_ID:
					continue
				var bloco := BlockRegistry.get_block(id)
				for face_nome: String in FACES:
					var face: Dictionary = FACES[face_nome]
					var offset: Vector3i = face["vizinho"]
					if vizinho_solido.call(x + offset.x, y + offset.y, z + offset.z):
						continue
					_add_face(st, Vector3(x, y, z), face, bloco.cor)
					faces_adicionadas += 1

	if faces_adicionadas == 0:
		return null
	return st.commit()


func _add_face(st: SurfaceTool, origem: Vector3, face: Dictionary, cor: Color) -> void:
	var verts: Array = face["verts"]
	var normal: Vector3 = face["normal"]
	var ordem: Array[int] = [0, 1, 2, 0, 2, 3]
	for i: int in ordem:
		st.set_normal(normal)
		st.set_color(cor)
		st.add_vertex(origem + verts[i])
