class_name CorpoCubelin
extends RefCounted
## Montagem visual do Cubelin sem física (Ciclo 9, Frente 9B): corpo em caixa
## colorida, olhos na frente (-Z) e faixa do elemento na base. Usado pela
## arena 3D da tela de batalha. A Creature do mundo (creature.gd) mantém a
## própria montagem, com o mesmo desenho, para não mexer em arquivo
## compartilhado com as outras frentes do Ciclo 9.

const COR_PUPILA: Color = Color(0.1, 0.1, 0.12)


static func tamanho_do_formato(formato: String) -> Vector3:
	match formato:
		"achatado":
			return Vector3(0.9, 0.45, 0.9)
		"alto":
			return Vector3(0.5, 0.9, 0.5)
		_:
			return Vector3(0.7, 0.7, 0.7)


static func criar_material(cor: Color, sem_sombra: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = cor
	if sem_sombra:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


## Devolve um Node3D com a base no y = 0 e a frente virada para -Z. A caixa
## colorida é o filho "Caixa" (é o que pisca ao levar dano).
static func montar(def: CreatureDef) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Corpo"
	var tamanho: Vector3 = tamanho_do_formato(def.formato)

	var caixa_no := MeshInstance3D.new()
	caixa_no.name = "Caixa"
	var caixa := BoxMesh.new()
	caixa.size = tamanho
	caixa_no.mesh = caixa
	caixa_no.material_override = criar_material(def.cor, false)
	caixa_no.position = Vector3(0.0, tamanho.y / 2.0, 0.0)
	raiz.add_child(caixa_no)

	var frente_z: float = -tamanho.z / 2.0 - 0.005
	var altura_olhos: float = tamanho.y * 0.15
	var afastamento_olhos: float = tamanho.x * 0.25
	_criar_olho(caixa_no, "OlhoEsquerdo", Vector3(-afastamento_olhos, altura_olhos, frente_z))
	_criar_olho(caixa_no, "OlhoDireito", Vector3(afastamento_olhos, altura_olhos, frente_z))

	if not def.eh_animal:
		var faixa := MeshInstance3D.new()
		faixa.name = "Faixa"
		var anel := BoxMesh.new()
		anel.size = Vector3(tamanho.x + 0.02, 0.06, tamanho.z + 0.02)
		faixa.mesh = anel
		faixa.material_override = criar_material(def.cor_secundaria, true)
		faixa.position = Vector3(0.0, -tamanho.y / 2.0 + 0.06, 0.0)
		caixa_no.add_child(faixa)
	return raiz


static func _criar_olho(pai: Node3D, nome: String, pos: Vector3) -> void:
	var olho := MeshInstance3D.new()
	olho.name = nome
	var branco := QuadMesh.new()
	branco.size = Vector2(0.14, 0.14)
	olho.mesh = branco
	olho.material_override = criar_material(Color.WHITE, true)
	olho.position = pos
	olho.rotation.y = PI  ## QuadMesh olha pra +Z; a frente do Cubelin é -Z.
	pai.add_child(olho)

	var pupila := MeshInstance3D.new()
	pupila.name = nome + "Pupila"
	var escura := QuadMesh.new()
	escura.size = Vector2(0.07, 0.07)
	pupila.mesh = escura
	pupila.material_override = criar_material(COR_PUPILA, true)
	pupila.position = Vector3(0.0, 0.0, 0.005)
	olho.add_child(pupila)
