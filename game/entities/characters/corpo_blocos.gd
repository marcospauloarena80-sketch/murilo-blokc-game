class_name CorpoBlocos
extends Node3D
## Corpo humanoide de blocos compartilhado entre o jogador e os NPCs (Ciclo 5,
## Frente 5A). Cabeça (0,45³), cabelo, tronco (0,5 x 0,7 x 0,28), braços e
## pernas vêm de corpo_blocos.tscn, com os mesmos nomes de nó que o jogador já
## usava ($Corpo/Cabeca, $Corpo/OmbroEsquerdo/BracoEsquerdo...). O rosto (dois
## olhos e boca na face -Z da cabeça, a frente do personagem) e a faixa opcional
## do tronco são criados em código. Os materiais vivem aqui: quem usa o corpo só
## chama aplicar_aparencia(), antes ou depois de entrar na árvore.

const LADO_OLHO: float = 0.08
const LADO_PUPILA: float = 0.04
const TAMANHO_BOCA_NEUTRA := Vector2(0.14, 0.03)
const TAMANHO_BOCA_FELIZ := Vector2(0.16, 0.05)
const AFASTAMENTO_OLHOS: float = 0.1
const ALTURA_OLHOS: float = 0.05
const ALTURA_BOCA: float = -0.1
## Meia cabeça (0,225) mais uma folga pros quads não brigarem com a face.
const Z_ROSTO: float = -0.226
const FOLGA_PUPILA: float = 0.001
## Meio tronco em Z (0,14) mais a mesma folga.
const Z_FAIXA: float = -0.141
const TAMANHO_FAIXA := Vector2(0.5, 0.08)
const ALTURA_FAIXA: float = 0.12
const COR_OLHO := Color(0.97, 0.97, 0.95)
const COR_PUPILA := Color(0.1, 0.08, 0.08)
const ESCURECIMENTO_BOCA: float = 0.45

var mat_pele: StandardMaterial3D = StandardMaterial3D.new()
var mat_cabelo: StandardMaterial3D = StandardMaterial3D.new()
var mat_camisa: StandardMaterial3D = StandardMaterial3D.new()
var mat_calca: StandardMaterial3D = StandardMaterial3D.new()
var expressao: String = "neutro"

var _mat_boca: StandardMaterial3D = _material_unshaded(Color(0.5, 0.3, 0.2))
var _boca: MeshInstance3D


func _ready() -> void:
	($Cabeca as MeshInstance3D).material_override = mat_pele
	($OmbroEsquerdo/BracoEsquerdo as MeshInstance3D).material_override = mat_pele
	($OmbroDireito/BracoDireito as MeshInstance3D).material_override = mat_pele
	($Cabelo as MeshInstance3D).material_override = mat_cabelo
	($Tronco as MeshInstance3D).material_override = mat_camisa
	($QuadrilEsquerdo/PernaEsquerda as MeshInstance3D).material_override = mat_calca
	($QuadrilDireito/PernaDireita as MeshInstance3D).material_override = mat_calca
	_criar_rosto()
	definir_expressao(expressao)


func aplicar_aparencia(aparencia: CharacterAppearance) -> void:
	mat_pele.albedo_color = aparencia.cor_pele
	mat_cabelo.albedo_color = aparencia.cor_cabelo
	mat_camisa.albedo_color = aparencia.cor_camisa
	mat_calca.albedo_color = aparencia.cor_calca
	_mat_boca.albedo_color = aparencia.cor_pele.darkened(ESCURECIMENTO_BOCA)


func definir_expressao(nova: String) -> void:
	## Só a boca muda: "feliz" é um sorriso mais largo e baixo, "neutro" o traço fino.
	expressao = nova
	if _boca == null:
		return
	var quad := _boca.mesh as QuadMesh
	if nova == "feliz":
		quad.size = TAMANHO_BOCA_FELIZ
		_boca.position.y = ALTURA_BOCA - 0.01
	else:
		quad.size = TAMANHO_BOCA_NEUTRA
		_boca.position.y = ALTURA_BOCA


func definir_faixa(cor: Color) -> void:
	## Faixa fina na frente do tronco (guardiões: cor do elemento da arena).
	var tronco := $Tronco as MeshInstance3D
	var faixa := tronco.get_node_or_null("Faixa") as MeshInstance3D
	if faixa == null:
		faixa = _criar_quad("Faixa", TAMANHO_FAIXA, Vector3(0.0, ALTURA_FAIXA, Z_FAIXA), cor)
		tronco.add_child(faixa)
	else:
		(faixa.material_override as StandardMaterial3D).albedo_color = cor


func _criar_rosto() -> void:
	var cabeca := $Cabeca as MeshInstance3D
	## Esquerdo do personagem é -X (ele olha pra -Z), como o OmbroEsquerdo.
	cabeca.add_child(_criar_olho("OlhoEsquerdo", -AFASTAMENTO_OLHOS))
	cabeca.add_child(_criar_olho("OlhoDireito", AFASTAMENTO_OLHOS))
	_boca = _criar_quad(
		"Boca", TAMANHO_BOCA_NEUTRA, Vector3(0.0, ALTURA_BOCA, Z_ROSTO), Color.BLACK
	)
	_boca.material_override = _mat_boca
	cabeca.add_child(_boca)


func _criar_olho(nome: String, x: float) -> MeshInstance3D:
	var olho := _criar_quad(
		nome, Vector2(LADO_OLHO, LADO_OLHO), Vector3(x, ALTURA_OLHOS, Z_ROSTO), COR_OLHO
	)
	## Filha do olho: herda o giro de 180° e fica uma folga à frente dele.
	var pupila := _criar_quad(
		"Pupila", Vector2(LADO_PUPILA, LADO_PUPILA), Vector3(0.0, 0.0, FOLGA_PUPILA), COR_PUPILA
	)
	pupila.rotation.y = 0.0
	olho.add_child(pupila)
	return olho


func _criar_quad(nome: String, tamanho: Vector2, posicao: Vector3, cor: Color) -> MeshInstance3D:
	## QuadMesh nasce olhando pra +Z; o giro de 180° em Y o vira pra -Z, a frente.
	var no := MeshInstance3D.new()
	no.name = nome
	var quad := QuadMesh.new()
	quad.size = tamanho
	no.mesh = quad
	no.position = posicao
	no.rotation.y = PI
	no.material_override = _material_unshaded(cor)
	no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return no


static func _material_unshaded(cor: Color) -> StandardMaterial3D:
	## Sem sombreamento o rosto não some quando a cabeça fica na sombra.
	var material := StandardMaterial3D.new()
	material.albedo_color = cor
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
