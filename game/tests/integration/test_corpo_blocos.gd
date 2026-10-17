extends GutTest
## Frente 5A (Ciclo 5): o corpo do jogador passa a vir de corpo_blocos.tscn.
## Os caminhos antigos ($Corpo/...) continuam válidos pra _animar_membros e pro
## criador de personagem, e o rosto (olhos e boca) nasce em código.

const PlayerScene := preload("res://entities/player/player.tscn")
const CorpoScene := preload("res://entities/characters/corpo_blocos.tscn")
const CAMINHOS_DO_CORPO: Array[String] = [
	"Corpo/Cabeca",
	"Corpo/Cabelo",
	"Corpo/Tronco",
	"Corpo/OmbroEsquerdo/BracoEsquerdo",
	"Corpo/OmbroDireito/BracoDireito",
	"Corpo/QuadrilEsquerdo/PernaEsquerda",
	"Corpo/QuadrilDireito/PernaDireita",
]


func _player() -> Player:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)  # sem ChunkManager a física fica desligada
	return player


func _corpo() -> CorpoBlocos:
	var corpo := CorpoScene.instantiate() as CorpoBlocos
	add_child_autofree(corpo)
	return corpo


func test_player_mantem_os_sete_nos_do_corpo_nos_caminhos_antigos() -> void:
	var player := _player()

	assert_is(player.get_node("Corpo"), CorpoBlocos)
	for caminho in CAMINHOS_DO_CORPO:
		assert_not_null(player.get_node_or_null(caminho) as MeshInstance3D, caminho)


func test_aplicar_aparencia_muda_a_cor_da_cabeca_do_player() -> void:
	var player := _player()
	var aparencia := CharacterAppearance.new()
	aparencia.cor_pele = Color(0.1, 0.2, 0.3)
	aparencia.cor_camisa = Color(0.4, 0.5, 0.6)

	player.aplicar_aparencia(aparencia)

	var cabeca := player.get_node("Corpo/Cabeca") as MeshInstance3D
	var tronco := player.get_node("Corpo/Tronco") as MeshInstance3D
	assert_eq((cabeca.material_override as StandardMaterial3D).albedo_color, Color(0.1, 0.2, 0.3))
	assert_eq((tronco.material_override as StandardMaterial3D).albedo_color, Color(0.4, 0.5, 0.6))
	assert_eq(player._mat_camisa.albedo_color, Color(0.4, 0.5, 0.6), "atalho do criador")


func test_player_tem_rosto_na_frente_da_cabeca() -> void:
	var player := _player()

	var olho_esquerdo := player.get_node_or_null("Corpo/Cabeca/OlhoEsquerdo") as MeshInstance3D
	var olho_direito := player.get_node_or_null("Corpo/Cabeca/OlhoDireito") as MeshInstance3D
	var boca := player.get_node_or_null("Corpo/Cabeca/Boca") as MeshInstance3D

	assert_not_null(olho_esquerdo)
	assert_not_null(olho_direito)
	assert_not_null(boca)
	assert_lt(olho_esquerdo.position.z, -0.22, "rosto no lado -Z (frente) da cabeça de 0,45")
	assert_lt(olho_esquerdo.position.x, olho_direito.position.x, "esquerdo do personagem é -X")
	assert_eq((olho_esquerdo.mesh as QuadMesh).size, Vector2(0.08, 0.08))
	assert_eq((boca.mesh as QuadMesh).size, Vector2(0.14, 0.03))
	assert_not_null(olho_esquerdo.get_node_or_null("Pupila"), "pupila escura dentro do olho")


func test_rosto_usa_materiais_unshaded() -> void:
	var corpo := _corpo()

	for nome: String in ["OlhoEsquerdo", "OlhoDireito", "Boca", "OlhoEsquerdo/Pupila"]:
		var parte := corpo.get_node("Cabeca/" + nome) as MeshInstance3D
		var material := parte.material_override as StandardMaterial3D
		assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, nome)


func test_definir_expressao_muda_so_a_boca() -> void:
	var corpo := _corpo()
	var boca := corpo.get_node("Cabeca/Boca") as MeshInstance3D
	var olho := corpo.get_node("Cabeca/OlhoEsquerdo") as MeshInstance3D
	var boca_neutra: Vector2 = (boca.mesh as QuadMesh).size
	var olho_antes: Vector2 = (olho.mesh as QuadMesh).size

	corpo.definir_expressao("feliz")

	assert_eq(corpo.expressao, "feliz")
	assert_ne((boca.mesh as QuadMesh).size, boca_neutra)
	assert_eq((olho.mesh as QuadMesh).size, olho_antes)

	corpo.definir_expressao("neutro")

	assert_eq((boca.mesh as QuadMesh).size, boca_neutra)


func test_boca_fica_na_cor_da_pele_escurecida() -> void:
	var corpo := _corpo()
	var aparencia := CharacterAppearance.new()
	aparencia.cor_pele = Color(0.8, 0.6, 0.4)

	corpo.aplicar_aparencia(aparencia)

	var boca := corpo.get_node("Cabeca/Boca") as MeshInstance3D
	var cor_boca := (boca.material_override as StandardMaterial3D).albedo_color
	assert_lt(cor_boca.r, 0.8)
	assert_lt(cor_boca.g, 0.6)
	assert_lt(cor_boca.b, 0.4)


func test_aplicar_aparencia_antes_de_entrar_na_arvore_vale_depois() -> void:
	## O spawner/NPC pode configurar antes do add_child (mesmo caso do Creature).
	var corpo := CorpoScene.instantiate() as CorpoBlocos
	var aparencia := CharacterAppearance.new()
	aparencia.cor_cabelo = Color(0.9, 0.1, 0.1)
	corpo.aplicar_aparencia(aparencia)

	add_child_autofree(corpo)

	var cabelo := corpo.get_node("Cabelo") as MeshInstance3D
	assert_eq((cabelo.material_override as StandardMaterial3D).albedo_color, Color(0.9, 0.1, 0.1))
