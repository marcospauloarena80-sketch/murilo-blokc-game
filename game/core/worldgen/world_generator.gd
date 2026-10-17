class_name WorldGenerator
extends RefCounted
## Geração procedural determinística por seed (ADR-005, docs/02-ARQUITETURA.md §4.2).
## Puro: mesma seed + mesmas coordenadas de chunk sempre produzem o mesmo ChunkData,
## chamado em qualquer ordem, sem estado compartilhado entre chunks.

const ALTURA_BASE: int = 30
const ALTURA_AMPLITUDE: float = 8.0
const CHANCE_ARVORE: float = 0.04
const MARGEM_ARVORE: int = 2
const CHANCE_FERRITE: float = 0.018
const CHANCE_CARVAO: float = 0.035
const CHANCE_CRISTAL_DOURADO: float = 0.003  ## raro — tier de ferramenta final (F10, ADR-023)
const SEMENTE_MINERIO: int = 7919  ## offset pra descorrelacionar do hash de árvores

## Anéis de bioma por distância do centro do mundo (F11, ADR-024) — decidido
## por chunk inteiro (centro do chunk), sem blending, sem noise novo.
const CENTRO_MUNDO: Vector2 = Vector2(64.0, 64.0)
const RAIO_CAMPOS_DOURADOS: float = 25.0
const RAIO_FLORESTA_CUBICA: float = 40.0
const RAIO_COLINAS_DE_PEDRA: float = 52.0
const RAIO_DESERTO_DE_AMBAR: float = 65.0
## Clareira sem árvores em volta do spawn e do vilarejo: o jogador nasce no
## chão (não em cima de uma copa) e vê os NPCs logo de cara (ADR-027).
const RAIO_CLAREIRA_SPAWN: float = 7.0
const CHANCE_AMBAR: float = 0.05  ## nódulo raro na areia do Deserto de Âmbar (F11)
## Lagos (Ciclo 4, ADR-027): todo vale abaixo do nível da água enche, com
## fundo e margem de areia. Nos Picos Gelados o lago é gelo sólido até o nível
## da água; no Deserto de Âmbar os vales ficam secos.
const NIVEL_AGUA: int = 27
## Sem lago perto do vilarejo: os NPCs são aterrados no bloco sólido mais alto
## e em ~22% das sementes algum deles (até a Lina) ficava no fundo de um lago.
const RAIO_VILAREJO_SECO: float = 19.0

## Cavernas decoradas (F11, ADR-024): bolsão pequeno e determinístico, não
## geração 3D completa — resolve o hedge do ADR-020 sem risco de perf novo.
const SEMENTE_CAVERNA: int = 104729
const CHANCE_CAVERNA_POR_CHUNK: float = 0.35
const MARGEM_CAVERNA: int = 3
const RAIO_CAVERNA: int = 2
const Y_MIN_CAVERNA: int = 10
const Y_MAX_CAVERNA: int = 16

## Túneis (Ciclo 8, 8E): "minhocas" são caminhos aleatórios determinísticos que
## cavam ar contínuo no subsolo, sempre dentro do próprio chunk.
const SEMENTE_MINHOCA: int = 130363
const CHANCE_MINHOCAS_POR_CHUNK: float = 0.2
const MINHOCAS_POR_CHUNK: int = 2
const PASSOS_MINHOCA: int = 24
const RAIO_MINHOCA: float = 1.5
const Y_MIN_MINHOCA: int = 8
const Y_MAX_MINHOCA: int = 24
const MARGEM_MINHOCA: int = 2  ## o centro da minhoca fica a esta distância da borda do chunk
const FOLGA_SUPERFICIE_MINHOCA: int = 3  ## o túnel nunca chega perto do topo do terreno

var _seed: int
var _ruido: FastNoiseLite
var _luzes_locais_ultima_chunk: Array[Vector3i] = []  ## posições locais (lx,y,lz) de tochas geradas


func _init(mundo_seed: int) -> void:
	_seed = mundo_seed
	_ruido = FastNoiseLite.new()
	_ruido.seed = mundo_seed
	_ruido.frequency = 0.02


func _altura_em(world_x: int, world_z: int) -> int:
	var n := _ruido.get_noise_2d(float(world_x), float(world_z))
	return ALTURA_BASE + int(round(n * ALTURA_AMPLITUDE))


func _bloco_de_subsolo(world_x: int, y: int, world_z: int) -> int:
	## Minérios em clusters determinísticos dentro da pedra (sem cavernas
	## de verdade — "strip mining" cavando reto pra baixo já funciona; F6).
	var h := _hash01(_seed + SEMENTE_MINERIO, world_x, world_z * 10007 + y)
	if h < CHANCE_FERRITE:
		return 11  # ferrite
	if h < CHANCE_FERRITE + CHANCE_CARVAO:
		return 10  # carvao
	if h < CHANCE_FERRITE + CHANCE_CARVAO + CHANCE_CRISTAL_DOURADO:
		return 12  # cristal dourado
	return 3  # pedra


static func bioma_em(world_x: int, world_z: int) -> String:
	var cx := int(floor(float(world_x) / ChunkData.SIZE_H))
	var cz := int(floor(float(world_z) / ChunkData.SIZE_H))
	var centro_chunk := Vector2(
		cx * ChunkData.SIZE_H + ChunkData.SIZE_H / 2.0,
		cz * ChunkData.SIZE_H + ChunkData.SIZE_H / 2.0
	)
	var dist := centro_chunk.distance_to(CENTRO_MUNDO)
	if dist < RAIO_CAMPOS_DOURADOS:
		return "campos_dourados"
	if dist < RAIO_FLORESTA_CUBICA:
		return "floresta_cubica"
	if dist < RAIO_COLINAS_DE_PEDRA:
		return "colinas_de_pedra"
	if dist < RAIO_DESERTO_DE_AMBAR:
		return "deserto_de_ambar"
	return "picos_gelados"


func _talvez_cavar_caverna(chunk: ChunkData, cx: int, cz: int) -> void:
	## Bolsão pequeno e raro, sempre bem abaixo da superfície (Y_MAX_CAVERNA
	## está bem abaixo da altura mínima do terreno) — nunca vaza pra fora.
	var h_existe := _hash01(_seed + SEMENTE_CAVERNA, cx, cz)
	if h_existe >= CHANCE_CAVERNA_POR_CHUNK:
		return
	var largura_util := ChunkData.SIZE_H - 2 * MARGEM_CAVERNA
	var h_x := _hash01(_seed + SEMENTE_CAVERNA + 1, cx, cz)
	var h_z := _hash01(_seed + SEMENTE_CAVERNA + 2, cx, cz)
	var h_y := _hash01(_seed + SEMENTE_CAVERNA + 3, cx, cz)
	var lx_centro := MARGEM_CAVERNA + int(h_x * largura_util)
	var lz_centro := MARGEM_CAVERNA + int(h_z * largura_util)
	var y_centro := Y_MIN_CAVERNA + int(h_y * (Y_MAX_CAVERNA - Y_MIN_CAVERNA + 1))

	for dx in range(-RAIO_CAVERNA, RAIO_CAVERNA + 1):
		for dz in range(-RAIO_CAVERNA, RAIO_CAVERNA + 1):
			for dy in range(-RAIO_CAVERNA, RAIO_CAVERNA + 1):
				if dx * dx + dz * dz + dy * dy <= RAIO_CAVERNA * RAIO_CAVERNA:
					chunk.set_block(
						lx_centro + dx, y_centro + dy, lz_centro + dz, BlockRegistry.AR_ID
					)

	var lx_tocha := lx_centro + RAIO_CAVERNA
	chunk.set_block(lx_tocha, y_centro, lz_centro, 9)  # tocha decorativa (id 9)
	_luzes_locais_ultima_chunk.append(Vector3i(lx_tocha, y_centro, lz_centro))


func _talvez_cavar_minhocas(chunk: ChunkData, cx: int, cz: int) -> void:
	if _hash01(_seed + SEMENTE_MINHOCA, cx, cz) >= CHANCE_MINHOCAS_POR_CHUNK:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = (
		((_seed * 73856093) ^ (cx * 19349663) ^ (cz * 83492791) ^ SEMENTE_MINHOCA) & 0x7fffffff
	)
	var limite_h := float(ChunkData.SIZE_H - 1 - MARGEM_MINHOCA)
	for _m in range(MINHOCAS_POR_CHUNK):
		var pos := Vector3(
			rng.randf_range(MARGEM_MINHOCA, limite_h),
			rng.randf_range(Y_MIN_MINHOCA + 2, Y_MAX_MINHOCA - 2),
			rng.randf_range(MARGEM_MINHOCA, limite_h)
		)
		var direcao := Vector3(
			rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.3), rng.randf_range(-1, 1)
		)
		direcao = direcao.normalized()
		for _passo in range(PASSOS_MINHOCA):
			_cavar_esfera(chunk, cx, cz, pos)
			## Vira um pouco a cada passo; ao chegar numa borda do chunk ou nos
			## limites de altura, reflete o componente para continuar dentro.
			direcao += Vector3(
				rng.randf_range(-0.5, 0.5), rng.randf_range(-0.25, 0.25), rng.randf_range(-0.5, 0.5)
			)
			direcao = direcao.normalized()
			var proxima := pos + direcao
			if proxima.x < MARGEM_MINHOCA or proxima.x > limite_h:
				direcao.x = -direcao.x
			if proxima.z < MARGEM_MINHOCA or proxima.z > limite_h:
				direcao.z = -direcao.z
			if proxima.y < Y_MIN_MINHOCA or proxima.y > Y_MAX_MINHOCA:
				direcao.y = -direcao.y
			pos += direcao


func _cavar_esfera(chunk: ChunkData, cx: int, cz: int, centro: Vector3) -> void:
	var r := int(ceil(RAIO_MINHOCA))
	var cxi := roundi(centro.x)
	var cyi := roundi(centro.y)
	var czi := roundi(centro.z)
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if float(dx * dx + dy * dy + dz * dz) > RAIO_MINHOCA * RAIO_MINHOCA:
					continue
				var lx := cxi + dx
				var lz := czi + dz
				var y := cyi + dy
				if lx < 0 or lx >= ChunkData.SIZE_H or lz < 0 or lz >= ChunkData.SIZE_H:
					continue
				if y < 1:
					continue
				var altura := _altura_em(cx * ChunkData.SIZE_H + lx, cz * ChunkData.SIZE_H + lz)
				if y > altura - FOLGA_SUPERFICIE_MINHOCA:
					continue
				var atual := chunk.get_block(lx, y, lz)
				if atual == 9 or atual == BlockRegistry.AGUA_ID:
					continue  # preserva a tocha da caverna decorada
				chunk.set_block(lx, y, lz, BlockRegistry.AR_ID)


static func _hash01(seed: int, x: int, z: int) -> float:
	var h: int = seed
	h = (h * 374761393 + x * 668265263) & 0x7fffffff
	h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff
	h = (h ^ (z * 2246822519)) & 0x7fffffff
	h = (h ^ (h >> 16)) & 0x7fffffff
	return float(h) / float(0x7fffffff)


func luzes_locais_da_ultima_chunk() -> Array[Vector3i]:
	return _luzes_locais_ultima_chunk


func gerar_chunk(cx: int, cz: int) -> ChunkData:
	var chunk := ChunkData.new()
	var alturas: Dictionary = {}
	_luzes_locais_ultima_chunk = []
	var bioma_id := bioma_em(
		cx * ChunkData.SIZE_H + ChunkData.SIZE_H / 2, cz * ChunkData.SIZE_H + ChunkData.SIZE_H / 2
	)

	for lx in range(ChunkData.SIZE_H):
		for lz in range(ChunkData.SIZE_H):
			var world_x := cx * ChunkData.SIZE_H + lx
			var world_z := cz * ChunkData.SIZE_H + lz
			var altura := _altura_em(world_x, world_z)
			alturas[Vector2i(lx, lz)] = altura
			for y in range(0, altura - 2):
				chunk.set_block(lx, y, lz, _bloco_de_subsolo(world_x, y, world_z))
			_aplicar_superficie(chunk, lx, lz, altura, bioma_id, world_x, world_z)
			_encher_lago(chunk, lx, lz, altura, bioma_id, world_x, world_z)

	_talvez_cavar_caverna(chunk, cx, cz)
	_talvez_cavar_minhocas(chunk, cx, cz)

	var tem_arvore := bioma_id == "campos_dourados" or bioma_id == "floresta_cubica"
	if tem_arvore:
		for lx in range(MARGEM_ARVORE, ChunkData.SIZE_H - MARGEM_ARVORE):
			for lz in range(MARGEM_ARVORE, ChunkData.SIZE_H - MARGEM_ARVORE):
				var world_x := cx * ChunkData.SIZE_H + lx
				var world_z := cz * ChunkData.SIZE_H + lz
				if Vector2(world_x, world_z).distance_to(CENTRO_MUNDO) < RAIO_CLAREIRA_SPAWN:
					continue
				if alturas[Vector2i(lx, lz)] <= NIVEL_AGUA + 1:
					continue  # nada de árvore no lago nem na praia
				if _hash01(_seed, world_x, world_z) < CHANCE_ARVORE:
					_plantar_arvore(
						chunk, lx, alturas[Vector2i(lx, lz)], lz, bioma_id == "floresta_cubica"
					)

	_aplicar_vilarejo(chunk, cx, cz)

	return chunk


func nivel_do_vilarejo() -> int:
	## Nível do chão do vilarejo: a altura do terreno no centro do mundo.
	return _altura_em(int(CENTRO_MUNDO.x), int(CENTRO_MUNDO.y))


func _aplicar_vilarejo(chunk: ChunkData, cx: int, cz: int) -> void:
	## Casas e arenas (Ciclo 8, 8D) entram depois de árvores e cavernas, recortadas
	## pelo chunk: o terreno do footprint é aplainado no nível do chão central (some
	## árvore, morro e água) e só então entram os blocos da estrutura.
	var nivel := nivel_do_vilarejo()
	var origem := Vector2i(cx * ChunkData.SIZE_H, cz * ChunkData.SIZE_H)
	for npc_id: String in Vilarejo.POSICOES_NPCS:
		for coluna: Vector2i in Vilarejo.colunas_do_footprint(npc_id):
			var local := coluna - origem
			if local.x < 0 or local.x >= ChunkData.SIZE_H:
				continue
			if local.y < 0 or local.y >= ChunkData.SIZE_H:
				continue
			_aplainar_coluna(chunk, local.x, local.y, _altura_em(coluna.x, coluna.y), nivel)
		var blocos: Array[Dictionary] = []
		var ancora := Vector2i.ZERO
		if Vilarejo.tem_casa(npc_id):
			blocos = Vilarejo.casa_para(npc_id)
			ancora = Vilarejo.canto_da_casa(npc_id)
		else:
			blocos = Vilarejo.arena_para(npc_id)
			ancora = Vilarejo.centro_da_arena(npc_id)
		for bloco: Dictionary in blocos:
			var rel: Vector3i = bloco["pos"]
			var lx := ancora.x + rel.x - origem.x
			var lz := ancora.y + rel.z - origem.y
			if lx < 0 or lx >= ChunkData.SIZE_H or lz < 0 or lz >= ChunkData.SIZE_H:
				continue
			chunk.set_block(lx, nivel + rel.y, lz, bloco["id"])
			if bloco["id"] == Vilarejo.TOCHA_ID:
				_luzes_locais_ultima_chunk.append(Vector3i(lx, nivel + rel.y, lz))


func _aplainar_coluna(chunk: ChunkData, lx: int, lz: int, altura: int, nivel: int) -> void:
	for y in range(maxi(0, mini(altura, nivel - 3)), nivel):
		chunk.set_block(lx, y, lz, 2)  # terra sob o piso
	for y in range(nivel, ChunkData.SIZE_V):
		chunk.set_block(lx, y, lz, BlockRegistry.AR_ID)


func _aplicar_superficie(
	chunk: ChunkData, lx: int, lz: int, altura: int, bioma_id: String, world_x: int, world_z: int
) -> void:
	## Cada bioma tem seu material de superfície (F11, ADR-024) — sem isso
	## todos os biomas seriam iguais debaixo dos pés, só mudando quem spawna.
	match bioma_id:
		"colinas_de_pedra":
			for y in range(max(altura - 2, 0), altura + 1):
				chunk.set_block(lx, y, lz, 3)  # pedra exposta, sem capa de terra/grama
		"deserto_de_ambar":
			for y in range(max(altura - 2, 0), altura):
				chunk.set_block(lx, y, lz, 6)  # areia
			if _hash01(_seed + SEMENTE_MINERIO + 31, world_x, world_z) < CHANCE_AMBAR:
				chunk.set_block(lx, altura, lz, 15)  # âmbar
			else:
				chunk.set_block(lx, altura, lz, 6)  # areia
		"picos_gelados":
			for y in range(max(altura - 2, 0), altura):
				chunk.set_block(lx, y, lz, 2)  # terra
			chunk.set_block(lx, altura, lz, 14)  # gelo
		_:
			for y in range(max(altura - 2, 0), altura):
				chunk.set_block(lx, y, lz, 2)  # terra
			chunk.set_block(lx, altura, lz, 1)  # grama


func _encher_lago(
	chunk: ChunkData, lx: int, lz: int, altura: int, bioma_id: String, world_x: int, world_z: int
) -> void:
	if bioma_id == "deserto_de_ambar" or altura > NIVEL_AGUA + 1:
		return
	if Vector2(world_x, world_z).distance_to(CENTRO_MUNDO) < RAIO_VILAREJO_SECO:
		return
	if bioma_id == "picos_gelados":
		## Lago congelado é gelo sólido até o nível da água, sem água por baixo:
		## quebrar o gelo de cima deixa um degrau de 1 bloco. Com água embaixo
		## o piso ficava 2 blocos abaixo e quem caía não saía mais (o pulo sobe
		## ~1,3 bloco; nadando sai ainda mais baixo).
		for y in range(altura + 1, NIVEL_AGUA + 1):
			chunk.set_block(lx, y, lz, 14)
		return
	if bioma_id != "colinas_de_pedra":
		chunk.set_block(lx, altura, lz, 6)  # fundo e praia de areia
		if altura > 0:
			chunk.set_block(lx, altura - 1, lz, 6)
	for y in range(altura + 1, NIVEL_AGUA + 1):
		chunk.set_block(lx, y, lz, BlockRegistry.AGUA_ID)


func _plantar_arvore(
	chunk: ChunkData, lx: int, altura_solo: int, lz: int, usar_madeira_rara: bool = false
) -> void:
	var base_tronco := altura_solo + 1
	var id_tronco := 13 if usar_madeira_rara else 4  # tronco raro (Floresta Cúbica) ou comum
	for i in range(4):
		chunk.set_block(lx, base_tronco + i, lz, id_tronco)
	var topo := base_tronco + 3
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for dy in range(0, 2):
				if dx == 0 and dz == 0 and dy == 0:
					continue
				chunk.set_block(lx + dx, topo + dy, lz + dz, 5)  # folhas
	chunk.set_block(lx, topo + 2, lz, 5)
