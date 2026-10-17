class_name ChunkManager
extends Node3D
## Orquestra os chunks do mundo: geração, malha e colisão. Mundo finito 8x8 chunks
## (ADR-005). API pública: get_block/set_block em coordenadas de mundo.
##
## Carregamento em fluxo (ADR-026, achado jogando o build real): os chunks são
## gerados do chunk do jogador pra fora, dentro de um orçamento de tempo por frame,
## e o jogo libera o jogador assim que a área 3x3 em volta dele está pronta
## (sinal area_inicial_pronta). O resto do mundo continua carregando em segundo
## plano. Antes, o chunk do jogador era o 36º de 64 e cada frame de carregamento
## levava ~0,5 s mesmo nativo, o que travava a entrada no mundo na Web.

signal area_inicial_pronta
signal chunk_pronto(coord: Vector2i)
signal mundo_gerado

const TerrenoShader := preload("res://assets/shaders/terreno.gdshader")
const DecoracaoShader := preload("res://assets/shaders/decoracao.gdshader")
const AguaShader := preload("res://assets/shaders/agua.gdshader")
const WORLD_CHUNKS_X: int = 8
const WORLD_CHUNKS_Z: int = 8
const RAIO_AREA_INICIAL: int = 1
## Orçamento de trabalho por frame. Antes da área inicial o jogador não se move,
## então dá pra gastar mais por frame; depois, o jogo precisa continuar fluido.
const ORCAMENTO_CARREGANDO_USEC: int = 30000
const ORCAMENTO_JOGANDO_USEC: int = 6000
## SIZE_H é 16: coordenada de chunk = x >> 4, local = x & 15 (vale pra negativos).
const _DESLOCAMENTO_CHUNK: int = 4
const _MASCARA_LOCAL: int = 15

@export var world_seed: int = 12345
## Limita a geração ao quadrado de chunks em volta do centro (-1 = mundo
## inteiro, o padrão). O menu usa 1: só os 3x3 do centro pro cenário de fundo.
@export var raio_chunks: int = -1

var area_pronta: bool = false
## Cópias das constantes lidas em _process: os testes zeram o orçamento pra
## verificar o fatiamento sem depender do relógio.
var orcamento_carregando_usec: int = ORCAMENTO_CARREGANDO_USEC
var orcamento_jogando_usec: int = ORCAMENTO_JOGANDO_USEC

var _worldgen: WorldGenerator
var _mesher: ChunkMesher
var _material: ShaderMaterial
var _material_decoracao: ShaderMaterial
var _material_agua: ShaderMaterial
var _chunks: Dictionary = {}
var _chunk_nodes: Dictionary = {}
var _chunks_com_malha: Dictionary = {}
var _fila_geracao: Array[Vector2i] = []
var _fila_malha: Array[Vector2i] = []
var _fila_ordenada: bool = false
var _centro_area: Vector2i = Vector2i.ZERO
var _fila_sujos: Array[Vector2i] = []
var _edicoes: Dictionary = {}
var _plantas: Dictionary = {}  ## Vector3i -> true: blocos com cresce_para (Ciclo 8)
var _delta_pendente: Dictionary = {}
var _mundo_gerado_emitido: bool = false


func _ready() -> void:
	add_to_group("chunk_manager")
	if GameState.seed_atual != 0:
		world_seed = GameState.seed_atual
	_worldgen = WorldGenerator.new(world_seed)
	_mesher = ChunkMesher.new()
	_material = ShaderMaterial.new()
	_material.shader = TerrenoShader
	_material.set_shader_parameter("texturas", AtlasBlocos.textura_array())
	_material.set_shader_parameter("camada_folhas", float(AtlasBlocos.indice("folhas")))
	_material_decoracao = ShaderMaterial.new()
	_material_decoracao.shader = DecoracaoShader
	_material_decoracao.set_shader_parameter("texturas", AtlasBlocos.textura_array())
	_material_agua = ShaderMaterial.new()
	_material_agua.shader = AguaShader
	for cx in range(WORLD_CHUNKS_X):
		for cz in range(WORLD_CHUNKS_Z):
			_fila_geracao.append(Vector2i(cx, cz))


func _process(_delta: float) -> void:
	if not _fila_ordenada:
		_ordenar_fila_de_geracao()
	var inicio := Time.get_ticks_usec()
	var orcamento := orcamento_jogando_usec if area_pronta else orcamento_carregando_usec
	var houve_trabalho := false

	## Edições do jogador primeiro: minerar não pode esperar o resto do mundo.
	## Pelo menos um remesh por quadro (o chunk do bloco editado entra antes dos
	## vizinhos), o resto obedece ao orçamento: um bloco de quina marca 3 chunks
	## (~33 ms cada na Web) e remontar os 3 no mesmo quadro engasgava ao minerar.
	while not _fila_sujos.is_empty():
		_remesh_chunk(_fila_sujos.pop_front())
		houve_trabalho = true
		if Time.get_ticks_usec() - inicio >= orcamento:
			break

	## Gerar e montar a malha são unidades separadas de trabalho: com o
	## orçamento curto de jogo, um frame paga só uma delas (sem engasgo na Web).
	## Se o remesh de edição já gastou o orçamento, o resto espera o próximo quadro.
	var orcamento_gasto := houve_trabalho and Time.get_ticks_usec() - inicio >= orcamento
	while not orcamento_gasto and (not _fila_malha.is_empty() or not _fila_geracao.is_empty()):
		if not _fila_malha.is_empty():
			_remesh_chunk(_fila_malha.pop_front())
			_verificar_area_inicial()
		else:
			var coord: Vector2i = _fila_geracao.pop_front()
			_gerar_um_chunk(coord)
			_fila_malha.append(coord)
		houve_trabalho = true
		if Time.get_ticks_usec() - inicio >= orcamento:
			break

	_verificar_area_inicial()
	if not _mundo_gerado_emitido and not tem_chunks_pendentes() and houve_trabalho:
		## Uma vez só: edições depois do carregamento também esvaziam a fila e
		## não podem reemitir "mundo pronto" (ADR-026).
		_mundo_gerado_emitido = true
		mundo_gerado.emit()


func _ordenar_fila_de_geracao() -> void:
	## Feito no primeiro _process, não no _ready: o _ready do ChunkManager roda
	## antes do Player existir (e em testes pode nem haver Player).
	_fila_ordenada = true
	_centro_area = _chunk_central()
	var centro := _centro_area
	if raio_chunks >= 0:
		var dentro_do_raio: Array[Vector2i] = []
		for coord: Vector2i in _fila_geracao:
			var distancia := (coord - centro).abs()
			if maxi(distancia.x, distancia.y) <= raio_chunks:
				dentro_do_raio.append(coord)
		_fila_geracao = dentro_do_raio
	_fila_geracao.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			return (a - centro).length_squared() < (b - centro).length_squared()
	)


func _chunk_central() -> Vector2i:
	var pos := Vector3(
		WORLD_CHUNKS_X * ChunkData.SIZE_H / 2.0, 0.0, WORLD_CHUNKS_Z * ChunkData.SIZE_H / 2.0
	)
	var jogador := get_tree().get_first_node_in_group("player") as Node3D
	if jogador != null:
		pos = jogador.global_position
	elif GameState.veio_de_continuar:
		pos = GameState.posicao_salva
	return Vector2i(
		clampi(floori(pos.x) >> _DESLOCAMENTO_CHUNK, 0, WORLD_CHUNKS_X - 1),
		clampi(floori(pos.z) >> _DESLOCAMENTO_CHUNK, 0, WORLD_CHUNKS_Z - 1)
	)


func _verificar_area_inicial() -> void:
	if area_pronta or not _fila_ordenada:
		return
	for dx in range(-RAIO_AREA_INICIAL, RAIO_AREA_INICIAL + 1):
		for dz in range(-RAIO_AREA_INICIAL, RAIO_AREA_INICIAL + 1):
			var coord := _centro_area + Vector2i(dx, dz)
			if _dentro_do_mundo(coord) and not _chunks_com_malha.has(coord):
				return
	area_pronta = true
	area_inicial_pronta.emit()


func _gerar_um_chunk(coord: Vector2i) -> void:
	var chunk := _worldgen.gerar_chunk(coord.x, coord.y)
	_chunks[coord] = chunk
	var candidatos_luz: Array[Vector3i] = _worldgen.luzes_locais_da_ultima_chunk().duplicate()
	if _delta_pendente.has(coord):
		for edicao: Vector4i in _delta_pendente[coord]:
			chunk.set_block(edicao.x, edicao.y, edicao.z, edicao.w)
			candidatos_luz.append(Vector3i(edicao.x, edicao.y, edicao.z))
		_delta_pendente.erase(coord)
	## _process só roda depois de todos os _ready() da árvore inicial, então o
	## TorchLightManager já está escutando (mesma classe de bug do CreatureSpawner
	## na F7, ADR-020).
	for local: Vector3i in candidatos_luz:
		var id := chunk.get_block(local.x, local.y, local.z)
		var def := BlockRegistry.get_block(id)
		if def != null and def.emite_luz:
			EventBus.light_block_loaded.emit(_local_para_mundo(coord, local), id)


func get_block(world_pos: Vector3i) -> int:
	if world_pos.y < 0 or world_pos.y >= ChunkData.SIZE_V:
		return BlockRegistry.AR_ID
	var chunk: ChunkData = _chunks.get(_coord_do_chunk(world_pos))
	if chunk == null:
		return BlockRegistry.AR_ID
	return chunk.get_block(world_pos.x & _MASCARA_LOCAL, world_pos.y, world_pos.z & _MASCARA_LOCAL)


func set_block(world_pos: Vector3i, id: int) -> void:
	## Edição feita pelo jogador durante o jogo: emite os eventos de jogo (drop,
	## som, partícula, missão). Save carregado usa aplicar_delta, que não emite.
	if world_pos.y < 0 or world_pos.y >= ChunkData.SIZE_V:
		return
	var coord := _coord_do_chunk(world_pos)
	if not _chunks.has(coord):
		return
	var chunk: ChunkData = _chunks[coord]
	var local := Vector3i(world_pos.x & _MASCARA_LOCAL, world_pos.y, world_pos.z & _MASCARA_LOCAL)
	var id_anterior := chunk.get_block(local.x, local.y, local.z)
	chunk.set_block(local.x, local.y, local.z, id)
	_edicoes[world_pos] = id
	_atualizar_planta(world_pos, id)
	if id == BlockRegistry.AR_ID:
		EventBus.block_broken.emit(world_pos, id_anterior)
	else:
		EventBus.block_placed.emit(world_pos, id)
	_marcar_sujo_com_vizinhos(coord, local)


func exportar_delta() -> Dictionary:
	## Chaves viram String pra caber em JSON (ADR-006).
	var resultado: Dictionary = {}
	for pos: Vector3i in _edicoes:
		resultado["%d,%d,%d" % [pos.x, pos.y, pos.z]] = _edicoes[pos]
	return resultado


func aplicar_delta(delta: Dictionary) -> void:
	## Save carregado: a edição vai direto pros dados do chunk, sem EventBus.
	## Reaplicar um bloco minerado não é o jogador minerando de novo; antes isso
	## dropava o item outra vez e avançava missão de construir a cada Continuar
	## (achado real, ADR-026). Chunk ainda não gerado guarda a edição até gerar.
	## _edicoes é preenchido já aqui, então salvar antes do mundo terminar de
	## carregar não perde nada.
	for chave: String in delta:
		var partes: PackedStringArray = chave.split(",")
		var pos := Vector3i(int(partes[0]), int(partes[1]), int(partes[2]))
		if pos.y < 0 or pos.y >= ChunkData.SIZE_V:
			continue
		var id: int = int(delta[chave])
		_edicoes[pos] = id
		_atualizar_planta(pos, id)
		var coord := _coord_do_chunk(pos)
		var edicao := Vector4i(pos.x & _MASCARA_LOCAL, pos.y, pos.z & _MASCARA_LOCAL, id)
		if _chunks.has(coord):
			(_chunks[coord] as ChunkData).set_block(edicao.x, edicao.y, edicao.z, id)
			_marcar_sujo_com_vizinhos(coord, Vector3i(edicao.x, edicao.y, edicao.z))
			var def := BlockRegistry.get_block(id)
			if def != null and def.emite_luz:
				EventBus.light_block_loaded.emit(pos, id)
		else:
			if not _delta_pendente.has(coord):
				_delta_pendente[coord] = []
			(_delta_pendente[coord] as Array).append(edicao)


func _atualizar_planta(pos: Vector3i, id: int) -> void:
	var def := BlockRegistry.get_block(id)
	if def != null and def.cresce_para != 0:
		_plantas[pos] = true
	else:
		_plantas.erase(pos)


func plantas_perto(chunk_central: Vector2i, raio_chunks: int) -> Array[Vector3i]:
	## Blocos que crescem (muda, trigo) nos chunks a até raio_chunks do central,
	## em ordem estável (Crescimento depende disso pra ser determinístico).
	var achadas: Array[Vector3i] = []
	for pos: Vector3i in _plantas:
		var coord := _coord_do_chunk(pos)
		if maxi(absi(coord.x - chunk_central.x), absi(coord.y - chunk_central.y)) <= raio_chunks:
			achadas.append(pos)
	achadas.sort_custom(
		func(a: Vector3i, b: Vector3i) -> bool:
			if a.x != b.x:
				return a.x < b.x
			if a.y != b.y:
				return a.y < b.y
			return a.z < b.z
	)
	return achadas


func trocar_bloco_sem_evento(pos: Vector3i, id: int) -> void:
	## Troca feita pelo mundo (planta que cresce), não pelo jogador: entra no
	## save como edição mas não solta drop, som nem avança missão.
	aplicar_delta({"%d,%d,%d" % [pos.x, pos.y, pos.z]: id})


func plantar_arvore(pos: Vector3i) -> bool:
	## Reproduz _plantar_arvore do WorldGenerator em blocos editados (entram no
	## save), com a base do tronco em pos (onde estava a muda). false se algo
	## sólido atrapalha o tronco: a muda fica e tenta de novo depois.
	var topo: int = pos.y + 3
	if topo + 2 >= ChunkData.SIZE_V:
		return false
	var id_tronco: int = 4
	if WorldGenerator.bioma_em(pos.x, pos.z) == "floresta_cubica":
		id_tronco = 13
	var delta: Dictionary = {}
	for i in range(4):
		var celula := Vector3i(pos.x, pos.y + i, pos.z)
		if i > 0 and not _celula_livre_pra_arvore(celula):
			return false
		delta["%d,%d,%d" % [celula.x, celula.y, celula.z]] = id_tronco
	var folhas: Array[Vector3i] = [Vector3i(pos.x, topo + 2, pos.z)]
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for dy in range(0, 2):
				if dx == 0 and dz == 0 and dy == 0:
					continue
				folhas.append(Vector3i(pos.x + dx, topo + dy, pos.z + dz))
	for celula: Vector3i in folhas:
		if _celula_livre_pra_arvore(celula):
			delta["%d,%d,%d" % [celula.x, celula.y, celula.z]] = 5
	aplicar_delta(delta)
	return true


func _celula_livre_pra_arvore(celula: Vector3i) -> bool:
	var id := get_block(celula)
	return id == BlockRegistry.AR_ID or BlockRegistry.e_cruz(id)


func tem_chunks_pendentes() -> bool:
	return not _fila_geracao.is_empty() or not _fila_malha.is_empty() or not _fila_sujos.is_empty()


func fila_pendente_tamanho() -> int:
	return _fila_sujos.size()


func definir_cor_do_ceu(cor: Color) -> void:
	## A água reflete o céu do momento (scenes/main.gd chama a cada quadro).
	_material_agua.set_shader_parameter("cor_ceu", cor)


func altura_da_superficie(x: int, z: int) -> int:
	## y do bloco sólido mais alto na coluna, ou -1 se não houver (fora do mundo
	## ou chunk não gerado). Único lugar desse cálculo (antes duplicado em 3).
	for y in range(ChunkData.SIZE_V - 1, -1, -1):
		if BlockRegistry.e_solido(get_block(Vector3i(x, y, z))):
			return y
	return -1


func chunk_pronto_em(pos: Vector3) -> bool:
	## true quando o chunk dessa posição já tem malha e colisão. Fora do mundo
	## nunca vai existir chunk, então não bloqueia (senão o jogador congelaria na borda).
	var coord := Vector2i(
		floori(pos.x) >> _DESLOCAMENTO_CHUNK, floori(pos.z) >> _DESLOCAMENTO_CHUNK
	)
	if not _dentro_do_mundo(coord):
		return true
	return _chunks_com_malha.has(coord)


func _dentro_do_mundo(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < WORLD_CHUNKS_X and coord.y < WORLD_CHUNKS_Z


func _coord_do_chunk(world_pos: Vector3i) -> Vector2i:
	return Vector2i(world_pos.x >> _DESLOCAMENTO_CHUNK, world_pos.z >> _DESLOCAMENTO_CHUNK)


func _local_para_mundo(coord: Vector2i, local: Vector3i) -> Vector3i:
	return Vector3i(
		coord.x * ChunkData.SIZE_H + local.x, local.y, coord.y * ChunkData.SIZE_H + local.z
	)


func _marcar_sujo_com_vizinhos(coord: Vector2i, local: Vector3i) -> void:
	_marcar_sujo(coord, true)
	if local.x == 0:
		_marcar_sujo(coord + Vector2i(-1, 0))
	if local.x == ChunkData.SIZE_H - 1:
		_marcar_sujo(coord + Vector2i(1, 0))
	if local.z == 0:
		_marcar_sujo(coord + Vector2i(0, -1))
	if local.z == ChunkData.SIZE_H - 1:
		_marcar_sujo(coord + Vector2i(0, 1))


func _marcar_sujo(coord: Vector2i, na_frente: bool = false) -> void:
	if not _chunks.has(coord):
		return
	if na_frente:
		_fila_sujos.erase(coord)  # já estava como vizinho: a edição passa na frente
		_fila_sujos.push_front(coord)
	elif not _fila_sujos.has(coord):
		_fila_sujos.append(coord)


func _remesh_chunk(coord: Vector2i) -> void:
	var chunk: ChunkData = _chunks[coord]
	var vizinho_solido := func(lx: int, ly: int, lz: int) -> bool:
		var wx: int = coord.x * ChunkData.SIZE_H + lx
		var wz: int = coord.y * ChunkData.SIZE_H + lz
		return BlockRegistry.e_oclusor(get_block(Vector3i(wx, ly, wz)))
	var malha := _mesher.construir_malha(chunk, vizinho_solido)
	var detalhes := _mesher.construir_detalhes(
		chunk, coord.x * 7919 + coord.y * 104729 + world_seed
	)
	_atualizar_no_chunk(coord, malha, detalhes)
	if not _chunks_com_malha.has(coord):
		_chunks_com_malha[coord] = true
		chunk_pronto.emit(coord)


func _atualizar_no_chunk(coord: Vector2i, malha: ArrayMesh, detalhes: Dictionary = {}) -> void:
	if _chunk_nodes.has(coord):
		var antigo: Node3D = _chunk_nodes[coord]
		antigo.queue_free()
		_chunk_nodes.erase(coord)
	if malha == null:
		return
	var no := StaticBody3D.new()
	no.position = Vector3(coord.x * ChunkData.SIZE_H, 0, coord.y * ChunkData.SIZE_H)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = malha
	mesh_instance.material_override = _material
	no.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	collision.shape = malha.create_trimesh_shape()
	no.add_child(collision)
	## Água e decoração ficam fora da colisão: a mira e o jogador atravessam.
	for chave: String in ["decoracao", "agua"]:
		var extra: ArrayMesh = detalhes.get(chave, null)
		if extra == null:
			continue
		var instancia := MeshInstance3D.new()
		instancia.mesh = extra
		instancia.material_override = _material_agua if chave == "agua" else _material_decoracao
		instancia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		no.add_child(instancia)
	add_child(no)
	_chunk_nodes[coord] = no
