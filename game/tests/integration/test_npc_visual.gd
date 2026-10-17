extends GutTest
## Frente 5A (Ciclo 5): NPCs humanoides com o corpo de blocos compartilhado,
## rosto, placa de nome acima da cabeça, "!" quando há missão disponível, faixa
## do elemento nos guardiões e giro devagar pra olhar o jogador perto.
## Ver docs/01-GDD.md §12.

const NpcScene := preload("res://entities/npcs/npc.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")


func before_each() -> void:
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []


func after_each() -> void:
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []


func _npc(npc_id: String) -> Npc:
	var npc := NpcScene.instantiate() as Npc
	add_child_autofree(npc)
	npc.configurar(NpcRegistry.get_npc(npc_id))
	return npc


func test_configurar_cria_placa_com_o_nome_do_npc() -> void:
	var npc := _npc("lina")

	var placa := npc.get_node_or_null("Placa") as Label3D

	assert_not_null(placa, "a placa de nome deveria existir")
	assert_eq(placa.text, "Professora Lina")
	assert_eq(placa.billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	assert_false(placa.no_depth_test, "a placa some atrás de parede")
	assert_almost_eq(placa.visibility_range_end, 24.0, 0.01)
	assert_gt(placa.position.y, 1.9, "acima da cabeça (topo do cabelo em ~2,07)")


func test_marcador_visivel_com_missao_disponivel_e_some_ao_iniciar() -> void:
	var npc := _npc("lina")
	var marcador := npc.get_node_or_null("Marcador") as Label3D

	assert_not_null(marcador, "a Lina oferece a quest_01: precisa do marcador")
	assert_eq(marcador.text, "!")
	assert_true(marcador.visible, "missão nem ativa nem concluída: mostra o !")

	GameState.iniciar_quest("quest_01_boas_vindas")
	npc._process(0.5)

	assert_false(marcador.visible, "missão ativa: esconde o !")


func test_marcador_fica_oculto_com_a_missao_concluida() -> void:
	GameState.quests_concluidas = ["quest_01_boas_vindas"]

	var npc := _npc("lina")

	assert_false((npc.get_node("Marcador") as Label3D).visible)


func test_npc_sem_missao_nao_mostra_marcador() -> void:
	var npc := _npc("refugio")

	var marcador := npc.get_node_or_null("Marcador") as Label3D

	assert_true(marcador == null or not marcador.visible)


func test_npc_tem_corpo_de_blocos_com_rosto() -> void:
	var npc := _npc("lina")

	var corpo := npc.get_node_or_null("Corpo") as CorpoBlocos

	assert_not_null(corpo, "o nó Corpo deveria ser um CorpoBlocos")
	assert_not_null(corpo.get_node_or_null("Cabeca/OlhoEsquerdo"))
	assert_not_null(corpo.get_node_or_null("Cabeca/OlhoDireito"))
	assert_not_null(corpo.get_node_or_null("Cabeca/Boca"))


func test_configurar_pinta_o_corpo_com_as_cores_do_npc_def() -> void:
	var def := NpcRegistry.get_npc("lina")
	var npc := _npc("lina")

	var corpo := npc.get_node("Corpo") as CorpoBlocos

	assert_eq(corpo.mat_pele.albedo_color, def.cor_pele)
	assert_eq(corpo.mat_cabelo.albedo_color, def.cor_cabelo)
	assert_eq(corpo.mat_camisa.albedo_color, def.cor_camisa)
	assert_eq(corpo.mat_calca.albedo_color, def.cor_calca)


func test_colisao_do_npc_e_uma_caixa_de_0_6_por_1_8() -> void:
	var npc := _npc("lina")

	var forma := (npc.get_node("CollisionShape3D") as CollisionShape3D).shape as BoxShape3D

	assert_eq(forma.size, Vector3(0.6, 1.8, 0.6))


func test_guardiao_tem_faixa_na_cor_do_elemento_da_arena() -> void:
	var npc := _npc("guardiao_brasa")

	var faixa := npc.get_node_or_null("Corpo/Tronco/Faixa") as MeshInstance3D

	assert_not_null(faixa, "guardião ganha a faixa do elemento no tronco")
	var material := faixa.material_override as StandardMaterial3D
	assert_eq(material.albedo_color, Npc.CORES_ELEMENTO["brasa"])
	assert_eq(material.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)


func test_npc_comum_nao_tem_faixa() -> void:
	var npc := _npc("lina")

	assert_null(npc.get_node_or_null("Corpo/Tronco/Faixa"))


func test_todos_os_npcs_tem_papel_definido() -> void:
	var papeis_validos: Array[String] = [
		"professora", "refugio", "comerciante", "construtor", "guardiao", "treinador"
	]
	for npc_id: String in NpcRegistry.todos_os_ids():
		var def := NpcRegistry.get_npc(npc_id)
		assert_true(papeis_validos.has(def.papel), "%s tem papel '%s'" % [npc_id, def.papel])


func test_npc_vira_devagar_para_olhar_o_jogador_proximo() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)  # sem ChunkManager a física do jogador fica desligada
	player.global_position = Vector3(3.0, 0.0, 0.0)
	var npc := _npc("lina")
	npc.global_position = Vector3.ZERO

	npc._process(0.05)
	var depois_de_um_passo := npc.rotation.y
	for i in range(60):
		npc._process(0.05)

	assert_true(absf(depois_de_um_passo) < absf(-PI / 2.0), "gira aos poucos, não de uma vez")
	assert_almost_eq(npc.rotation.y, -PI / 2.0, 0.05, "frente (-Z) apontando pro jogador em +X")


func test_npc_nao_vira_para_jogador_longe() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	player.global_position = Vector3(10.0, 0.0, 0.0)
	var npc := _npc("lina")
	npc.global_position = Vector3.ZERO

	for i in range(60):
		npc._process(0.05)

	assert_almost_eq(npc.rotation.y, 0.0, 0.001, "a mais de 6 blocos o NPC fica como está")
