extends GutTest
## Ver docs/01-GDD.md §12 e docs/07-DECISOES.md ADR-022.


func test_4_npcs_existem() -> void:
	for id: String in ["lina", "refugio", "comerciante", "construtor"]:
		assert_not_null(NpcRegistry.get_npc(id), "NPC '%s' deveria existir" % id)
	assert_eq(NpcRegistry.todos_os_ids().size(), 4)


func test_lina_abre_laboratorio_e_oferece_missao() -> void:
	var lina := NpcRegistry.get_npc("lina")
	assert_true(lina.abre_laboratorio)
	assert_ne(lina.oferece_quest_id, "")


func test_refugio_cura_ao_interagir() -> void:
	var refugio := NpcRegistry.get_npc("refugio")
	assert_true(refugio.cura_ao_interagir)


func test_comerciante_tem_troca_configurada() -> void:
	var comerciante := NpcRegistry.get_npc("comerciante")
	assert_ne(comerciante.troca_pede_item, "")
	assert_gt(comerciante.troca_pede_quantidade, 0)
	assert_ne(comerciante.troca_oferece_item, "")
	assert_gt(comerciante.troca_oferece_quantidade, 0)


func test_construtor_oferece_missao() -> void:
	var construtor := NpcRegistry.get_npc("construtor")
	assert_ne(construtor.oferece_quest_id, "")


func test_npc_inexistente_retorna_null() -> void:
	assert_null(NpcRegistry.get_npc("nao_existe"))
