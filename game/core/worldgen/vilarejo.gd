class_name Vilarejo
extends RefCounted
## Plano estático do vilarejo (Ciclo 8, frente 8D): casas dos 4 NPCs do centro e
## arenas de pedra dos guardiões. Puro e determinístico: só números e ids de bloco,
## sem acesso ao mundo. O WorldGenerator aplica por chunk; o main posiciona os NPCs.

const PEDRA_ID: int = 3
const TOCHA_ID: int = 9
const TABUA_ID: int = 23
const VIDRO_ID: int = 24
const LAJE_ID: int = 25

const LADO_CASA: int = 7
const ALTURA_CASA: int = 5  ## piso, 3 de parede, telhado
const RAIO_ARENA: int = 4

## Posição x,z dos 9 NPCs no mundo (as mesmas que estavam em main.tscn). Para os
## NPCs com casa vale a posição de dentro da casa (ver posicao_do_npc).
const POSICOES_NPCS: Dictionary = {
	"lina": Vector2i(66, 66),
	"refugio": Vector2i(70, 64),
	"comerciante": Vector2i(62, 66),
	"construtor": Vector2i(66, 62),
	"guardiao_pedra": Vector2i(74, 74),
	"guardiao_brasa": Vector2i(54, 74),
	"guardiao_gota": Vector2i(54, 54),
	"guardiao_faisca": Vector2i(74, 54),
	"guardiao_final": Vector2i(64, 80),
}

## Treinadores de mundo (Ciclo 9, 9E): só x,z; o main.gd aterra pelo chão da superfície.
const POSICOES_TREINADORES: Dictionary = {
	"treinador_tico": Vector2i(40, 64),
	"treinador_bia": Vector2i(88, 64),
}

## Centro da casa e direção da porta (sempre voltada ao centro do mundo).
const CASAS: Dictionary = {
	"lina": {"centro": Vector2i(64, 72), "porta": Vector2i(0, -1)},
	"refugio": {"centro": Vector2i(72, 64), "porta": Vector2i(-1, 0)},
	"comerciante": {"centro": Vector2i(56, 64), "porta": Vector2i(1, 0)},
	"construtor": {"centro": Vector2i(64, 56), "porta": Vector2i(0, 1)},
}


static func ids_com_casa() -> Array[String]:
	var ids: Array[String] = []
	for id: String in CASAS:
		ids.append(id)
	return ids


static func ids_com_arena() -> Array[String]:
	var ids: Array[String] = []
	for id: String in POSICOES_NPCS:
		if not CASAS.has(id):
			ids.append(id)
	return ids


static func tem_casa(npc_id: String) -> bool:
	return CASAS.has(npc_id)


static func centro_da_casa(npc_id: String) -> Vector2i:
	return CASAS[npc_id]["centro"]


static func canto_da_casa(npc_id: String) -> Vector2i:
	## Canto de menor x,z da casa; as posições de casa_para são relativas a ele.
	return centro_da_casa(npc_id) - Vector2i(LADO_CASA / 2, LADO_CASA / 2)


static func centro_da_arena(npc_id: String) -> Vector2i:
	return POSICOES_NPCS[npc_id]


static func casa_para(npc_id: String) -> Array[Dictionary]:
	## Blocos de uma casa 7 x 5 x 7 como {"pos": Vector3i relativo ao canto (y 0 = piso),
	## "id": int}. O interior (ar) não entra na lista.
	var blocos: Array[Dictionary] = []
	if not CASAS.has(npc_id):
		return blocos
	var porta: Vector2i = CASAS[npc_id]["porta"]
	var meio: int = LADO_CASA / 2
	var pos_porta := Vector2i(meio + porta.x * meio, meio + porta.y * meio)
	## Janelas nas duas paredes laterais (as que não são a da porta).
	var lateral := Vector2i(absi(porta.y), absi(porta.x))
	var janela_a := Vector2i(meio - lateral.x * meio, meio - lateral.y * meio)
	var janela_b := Vector2i(meio + lateral.x * meio, meio + lateral.y * meio)
	for i in range(LADO_CASA):
		for j in range(LADO_CASA):
			var p := Vector2i(i, j)
			blocos.append({"pos": Vector3i(i, 0, j), "id": PEDRA_ID})
			blocos.append({"pos": Vector3i(i, ALTURA_CASA - 1, j), "id": LAJE_ID})
			var parede: bool = i == 0 or j == 0 or i == LADO_CASA - 1 or j == LADO_CASA - 1
			if not parede:
				continue
			for y in range(1, ALTURA_CASA - 1):
				var bloco: int = TABUA_ID
				if p == pos_porta and y == 1:
					bloco = BlockRegistry.PORTA_FECHADA_ID
				elif p == pos_porta and y == 2:
					bloco = BlockRegistry.PORTA_TOPO_ID
				elif (p == janela_a or p == janela_b) and y == 2:
					bloco = VIDRO_ID
				blocos.append({"pos": Vector3i(i, y, j), "id": bloco})
	## Tocha no chão, junto da parede do fundo (oposta à porta).
	blocos.append({"pos": Vector3i(meio - porta.x * 2, 1, meio - porta.y * 2), "id": TOCHA_ID})
	return blocos


static func arena_para(npc_id: String) -> Array[Dictionary]:
	## Anel de pedra de raio 4 com piso (y 0) e uma mureta baixa (y 1) na borda,
	## aberta nos quatro eixos. Posições relativas ao centro do guardião.
	var blocos: Array[Dictionary] = []
	if not POSICOES_NPCS.has(npc_id) or CASAS.has(npc_id):
		return blocos
	for dx in range(-RAIO_ARENA, RAIO_ARENA + 1):
		for dz in range(-RAIO_ARENA, RAIO_ARENA + 1):
			var d2: int = dx * dx + dz * dz
			if d2 > RAIO_ARENA * RAIO_ARENA:
				continue
			blocos.append({"pos": Vector3i(dx, 0, dz), "id": PEDRA_ID})
			if d2 > 9 and absi(dx) > 1 and absi(dz) > 1:
				blocos.append({"pos": Vector3i(dx, 1, dz), "id": PEDRA_ID})
	return blocos


static func colunas_do_footprint(npc_id: String) -> Array[Vector2i]:
	## Colunas x,z do mundo que o terreno aplaina para esse NPC (casa 7 x 7 ou disco da arena).
	var colunas: Array[Vector2i] = []
	if CASAS.has(npc_id):
		var canto := canto_da_casa(npc_id)
		for i in range(LADO_CASA):
			for j in range(LADO_CASA):
				colunas.append(canto + Vector2i(i, j))
	elif POSICOES_NPCS.has(npc_id):
		var centro := centro_da_arena(npc_id)
		for dx in range(-RAIO_ARENA, RAIO_ARENA + 1):
			for dz in range(-RAIO_ARENA, RAIO_ARENA + 1):
				if dx * dx + dz * dz <= RAIO_ARENA * RAIO_ARENA:
					colunas.append(centro + Vector2i(dx, dz))
	return colunas


static func posicao_do_npc(npc_id: String, nivel_piso: int) -> Vector3:
	## Onde o NPC pisa, dado o y do bloco de piso: o meio da casa, ou o centro da arena.
	var xz: Vector2i = POSICOES_NPCS[npc_id]
	if CASAS.has(npc_id):
		xz = centro_da_casa(npc_id)
	return Vector3(float(xz.x) + 0.5, float(nivel_piso) + 1.0, float(xz.y) + 0.5)
