class_name BlockRegistry
extends RefCounted
## Registro estático dos BlockDef por id. id=0 é sempre "ar" (ausência de bloco).
## Ver docs/02-ARQUITETURA.md §4.2. Não é autoload (ADR: máximo 5) — acesso via métodos estáticos.

const AR_ID: int = 0
const AGUA_ID: int = 16  ## não sólida: sem colisão, desenhada à parte (Ciclo 4)
const PORTA_FECHADA_ID: int = 27  ## 8C: porta de 2 blocos; embaixo fechada, embaixo aberta
const PORTA_ABERTA_ID: int = 28
const PORTA_TOPO_ID: int = 29  ## bloco de cima, acompanha o estado do de baixo

## Códigos de forma na tabela_formas() (8C). 0 = cubo cheio.
const FORMA_CUBO: int = 0
const FORMA_VIDRO: int = 1
const FORMA_LAJE: int = 2
const FORMA_ESCADA: int = 3
const FORMA_PORTA: int = 4
const FORMA_CERCA: int = 5
const _NOMES_DE_FORMA: Array[String] = ["cubo", "vidro", "laje", "escada", "porta", "cerca"]

static var _blocos: Dictionary = {
	1: preload("res://data/blocks/grama.tres"),
	2: preload("res://data/blocks/terra.tres"),
	3: preload("res://data/blocks/pedra.tres"),
	4: preload("res://data/blocks/tronco.tres"),
	5: preload("res://data/blocks/folhas.tres"),
	6: preload("res://data/blocks/areia.tres"),
	7: preload("res://data/blocks/cama.tres"),
	8: preload("res://data/blocks/bau.tres"),
	9: preload("res://data/blocks/tocha.tres"),
	10: preload("res://data/blocks/carvao.tres"),
	11: preload("res://data/blocks/ferrite.tres"),
	12: preload("res://data/blocks/cristal_dourado.tres"),
	13: preload("res://data/blocks/tronco_raro.tres"),
	14: preload("res://data/blocks/gelo.tres"),
	15: preload("res://data/blocks/ambar_bloco.tres"),
	16: preload("res://data/blocks/agua.tres"),
	17: preload("res://data/blocks/muda.tres"),
	18: preload("res://data/blocks/cogumelo.tres"),
	19: preload("res://data/blocks/trigo_1.tres"),
	20: preload("res://data/blocks/trigo_2.tres"),
	21: preload("res://data/blocks/trigo_3.tres"),
	22: preload("res://data/blocks/terra_arada.tres"),
	23: preload("res://data/blocks/tabua.tres"),
	24: preload("res://data/blocks/vidro.tres"),
	25: preload("res://data/blocks/laje.tres"),
	26: preload("res://data/blocks/escada.tres"),
	27: preload("res://data/blocks/porta_fechada.tres"),
	28: preload("res://data/blocks/porta_aberta.tres"),
	29: preload("res://data/blocks/porta_topo.tres"),
	30: preload("res://data/blocks/cerca.tres"),
}

static var _tabela_solidos: PackedByteArray = PackedByteArray()
static var _tabela_cores: PackedColorArray = PackedColorArray()
static var _tabela_texturas: PackedInt32Array = PackedInt32Array()
static var _tabela_brilhos: PackedFloat32Array = PackedFloat32Array()
static var _tabela_oclusao: PackedByteArray = PackedByteArray()
static var _tabela_cruz: PackedByteArray = PackedByteArray()
static var _tabela_formas: PackedByteArray = PackedByteArray()


static func get_block(id: int) -> BlockDef:
	return _blocos.get(id, null)


static func tabela_solidos() -> PackedByteArray:
	## 256 entradas (1 byte por id): 1 = sólido. Consulta O(1) sem Dictionary
	## no caminho quente do mesher (ADR-026).
	if _tabela_solidos.is_empty():
		_tabela_solidos.resize(256)
		for id: int in _blocos:
			_tabela_solidos[id] = 1 if e_solido(id) else 0
	return _tabela_solidos


static func tabela_cores() -> PackedColorArray:
	if _tabela_cores.is_empty():
		_tabela_cores.resize(256)
		for id: int in _blocos:
			_tabela_cores[id] = (_blocos[id] as BlockDef).cor
	return _tabela_cores


static func tabela_texturas() -> PackedInt32Array:
	## 256 x 6 entradas: camada do AtlasBlocos por face, na ordem do ChunkMesher
	## (cima, baixo, norte, sul, leste, oeste).
	if _tabela_texturas.is_empty():
		_tabela_texturas.resize(256 * 6)
		for id: int in _blocos:
			var bloco: BlockDef = _blocos[id]
			var lado: int = maxi(0, AtlasBlocos.indice(bloco.textura_lado))
			var topo: int = lado
			if bloco.textura_topo != "":
				topo = maxi(0, AtlasBlocos.indice(bloco.textura_topo))
			var base: int = topo
			if bloco.textura_base != "":
				base = maxi(0, AtlasBlocos.indice(bloco.textura_base))
			var faces: Array[int] = [topo, base, lado, lado, lado, lado]
			for f: int in range(6):
				_tabela_texturas[id * 6 + f] = faces[f]
	return _tabela_texturas


static func tabela_brilhos() -> PackedFloat32Array:
	if _tabela_brilhos.is_empty():
		_tabela_brilhos.resize(256)
		for id: int in _blocos:
			_tabela_brilhos[id] = (_blocos[id] as BlockDef).brilho
	return _tabela_brilhos


static func tabela_oclusao() -> PackedByteArray:
	## 256 entradas: 1 = esconde a face dos vizinhos. Separada de tabela_solidos:
	## cruz (Ciclo 8) não oclui nem colide; formas parciais futuras podem
	## colidir sem ocluir.
	if _tabela_oclusao.is_empty():
		_tabela_oclusao.resize(256)
		for id: int in _blocos:
			var bloco: BlockDef = _blocos[id]
			_tabela_oclusao[id] = 1 if bloco.solido and bloco.oclui else 0
	return _tabela_oclusao


static func tabela_cruz() -> PackedByteArray:
	## 256 entradas: 1 = bloco de forma "cruz" (sai em construir_detalhes).
	if _tabela_cruz.is_empty():
		_tabela_cruz.resize(256)
		for id: int in _blocos:
			_tabela_cruz[id] = 1 if (_blocos[id] as BlockDef).forma == "cruz" else 0
	return _tabela_cruz


static func e_cruz(id: int) -> bool:
	var bloco := get_block(id)
	return bloco != null and bloco.forma == "cruz"


static func tabela_formas() -> PackedByteArray:
	## 256 entradas: código FORMA_* de cada id (8C). Só FORMA_CUBO oclui vizinhos;
	## FORMA_VIDRO esconde a face entre vidros, o resto vira caixas no mesher.
	if _tabela_formas.is_empty():
		_tabela_formas.resize(256)
		for id: int in _blocos:
			_tabela_formas[id] = maxi(0, _NOMES_DE_FORMA.find((_blocos[id] as BlockDef).forma))
	return _tabela_formas


static func e_oclusor(id: int) -> bool:
	## Esconde as faces dos vizinhos: sólido e cubo cheio (vidro, laje, escada,
	## porta e cerca não ocluem).
	var bloco := get_block(id)
	return e_solido(id) and tabela_formas()[id] == FORMA_CUBO and bloco != null and bloco.oclui


static func e_solido(id: int) -> bool:
	if id == AR_ID:
		return false
	var bloco := get_block(id)
	return bloco != null and bloco.solido
