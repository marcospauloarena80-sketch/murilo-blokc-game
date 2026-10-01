class_name AtlasBlocos
extends RefCounted
## Texturas dos blocos (Ciclo 4, ADR-027). O PNG é gerado por código em
## tools/gerar_atlas.gd (pixel art própria, sem asset de terceiros) numa grade
## de COLUNAS x linhas de tiles LADO x LADO, na ordem de NOMES. Em tempo de
## execução vira um Texture2DArray (uma camada por tile, mipmaps por camada,
## sem vazar cor de um tile pro vizinho como num atlas comum).

const CAMINHO_PNG: String = "res://assets/textures/atlas_blocos.png"
const LADO: int = 32
const COLUNAS: int = 8
const NOMES: Array[String] = [
	"grama_topo",
	"grama_lado",
	"terra",
	"pedra",
	"tronco_lado",
	"tronco_topo",
	"folhas",
	"areia",
	"gelo",
	"ambar",
	"carvao",
	"ferrite",
	"cristal_dourado",
	"bau_lado",
	"bau_topo",
	"cama_topo",
	"cama_lado",
	"tocha",
	"tronco_raro_lado",
	"tronco_raro_topo",
	"capim",
	"flor_amarela",
	"flor_rosa",
	"flor_lumen",
]

static var _textura: Texture2DArray


static func indice(nome: String) -> int:
	return NOMES.find(nome)


static func textura_array() -> Texture2DArray:
	if _textura != null:
		return _textura
	var atlas: Image = (load(CAMINHO_PNG) as Texture2D).get_image()
	if atlas.is_compressed():
		atlas.decompress()
	atlas.convert(Image.FORMAT_RGBA8)
	var camadas: Array[Image] = []
	for i: int in range(NOMES.size()):
		var tile := atlas.get_region(Rect2i((i % COLUNAS) * LADO, (i / COLUNAS) * LADO, LADO, LADO))
		tile.generate_mipmaps()
		camadas.append(tile)
	_textura = Texture2DArray.new()
	_textura.create_from_images(camadas)
	return _textura
