class_name IconesItens
extends RefCounted
## Ícones dos itens (Ciclo 6, 6B). O PNG é gerado por código em
## tools/gerar_icones.gd (pixel art própria, sem asset de terceiros) numa grade
## de COLUNAS x linhas de tiles LADO x LADO, na ordem de NOMES (a mesma do
## ItemRegistry). Em tempo de execução cada ícone é um AtlasTexture sobre a
## folha, carregada uma vez; HUD, mochila e baú compartilham as instâncias.

const CAMINHO_PNG: String = "res://assets/textures/icones_itens.png"
const LADO: int = 32
const COLUNAS: int = 8
const NOMES: Array[String] = [
	"terra",
	"pedra",
	"tronco",
	"areia",
	"tabua",
	"graveto",
	"bancada",
	"picareta_madeira",
	"machado_madeira",
	"picareta_pedra",
	"cama",
	"bau",
	"tocha",
	"carvao",
	"ferrite",
	"picareta_ferrite",
	"machado_ferrite",
	"maca",
	"maca_assada",
	"fornalha",
	"espada_pedra",
	"cubo_captura",
	"pocao_cura",
	"cristal_dourado",
	"madeira_rara",
	"gelo",
	"ambar",
	"picareta_cristal_dourado",
	"espada_cristal_dourado",
	"pocao_maior",
	"cubo_captura_avancado",
	"semente",
	"trigo",
	"pao",
	"enxada_madeira",
	"muda",
	"cogumelo",
	"carne_crua",
	"carne_assada",
	"la",
]

static var _folha: Texture2D
static var _texturas: Dictionary = {}


static func indice(item_id: String) -> int:
	return NOMES.find(item_id)


static func regiao(i: int) -> Rect2:
	## Retângulo do tile i na folha.
	return Rect2((i % COLUNAS) * LADO, (i / COLUNAS) * LADO, LADO, LADO)


static func textura(item_id: String) -> Texture2D:
	## null para id desconhecido (inclusive ""), senão o AtlasTexture do item,
	## sempre a mesma instância.
	var i: int = indice(item_id)
	if i < 0:
		return null
	if _texturas.has(item_id):
		return _texturas[item_id]
	if _folha == null:
		_folha = load(CAMINHO_PNG)
	var tex := AtlasTexture.new()
	tex.atlas = _folha
	tex.region = regiao(i)
	tex.filter_clip = true
	_texturas[item_id] = tex
	return tex


static func imagem(item_id: String) -> Image:
	## Pixels do ícone (testes, partículas): recorte da folha em RGBA8.
	var i: int = indice(item_id)
	if i < 0:
		return null
	var folha: Image = (load(CAMINHO_PNG) as Texture2D).get_image()
	if folha.is_compressed():
		folha.decompress()
	folha.convert(Image.FORMAT_RGBA8)
	return folha.get_region(Rect2i(regiao(i)))
