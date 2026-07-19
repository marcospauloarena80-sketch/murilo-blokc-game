extends GutTest
## Ver docs/01-GDD.md §12 (cadeia principal + repetíveis) e docs/07-DECISOES.md ADR-022.

const TIPOS_VALIDOS := ["coletar", "construir", "derrotar", "capturar", "craftar"]


func test_existem_12_missoes_no_total() -> void:
	assert_eq(QuestRegistry.todos_os_ids().size(), 12)


func test_todas_as_missoes_tem_tipo_valido() -> void:
	for id: String in QuestRegistry.todos_os_ids():
		var quest := QuestRegistry.get_quest(id)
		assert_true(TIPOS_VALIDOS.has(quest.tipo), "%s tem tipo inválido: %s" % [id, quest.tipo])


func test_cadeia_principal_sempre_aponta_pra_proxima_quest_existente() -> void:
	for id: String in QuestRegistry.todos_os_ids():
		var quest := QuestRegistry.get_quest(id)
		if quest.proxima_quest_id != "":
			assert_not_null(
				QuestRegistry.get_quest(quest.proxima_quest_id),
				"%s aponta pra uma missão inexistente: %s" % [id, quest.proxima_quest_id]
			)


func test_4_missoes_repetiveis_existem() -> void:
	var repetiveis := 0
	for id: String in QuestRegistry.todos_os_ids():
		if QuestRegistry.get_quest(id).repetivel:
			repetiveis += 1
	assert_eq(repetiveis, 4)


func test_lina_oferece_uma_missao_que_existe_de_verdade() -> void:
	var lina := NpcRegistry.get_npc("lina")
	assert_not_null(QuestRegistry.get_quest(lina.oferece_quest_id))


func test_construtor_oferece_uma_missao_que_existe_de_verdade() -> void:
	var construtor := NpcRegistry.get_npc("construtor")
	assert_not_null(QuestRegistry.get_quest(construtor.oferece_quest_id))


func test_guardiao_pedra_oferece_a_missao_repetivel_de_captura() -> void:
	var guardiao := NpcRegistry.get_npc("guardiao_pedra")
	assert_eq(guardiao.oferece_quest_id, "quest_r4_capturador")
	assert_not_null(QuestRegistry.get_quest(guardiao.oferece_quest_id))


func test_guardiao_faisca_oferece_a_missao_repetivel_de_caca() -> void:
	var guardiao := NpcRegistry.get_npc("guardiao_faisca")
	assert_eq(guardiao.oferece_quest_id, "quest_r3_cacador")
	assert_not_null(QuestRegistry.get_quest(guardiao.oferece_quest_id))


func test_cadeia_de_lina_termina_numa_repetivel() -> void:
	var atual := QuestRegistry.get_quest("quest_01_boas_vindas")
	var guarda := 0
	while atual.proxima_quest_id != "" and guarda < 20:
		atual = QuestRegistry.get_quest(atual.proxima_quest_id)
		guarda += 1
	assert_true(atual.repetivel, "cadeia da Lina deveria terminar numa missão repetível")


func test_cadeia_do_construtor_termina_numa_repetivel() -> void:
	var atual := QuestRegistry.get_quest("quest_07_abrigo")
	var guarda := 0
	while atual.proxima_quest_id != "" and guarda < 20:
		atual = QuestRegistry.get_quest(atual.proxima_quest_id)
		guarda += 1
	assert_true(atual.repetivel, "cadeia do Construtor deveria terminar numa missão repetível")
