extends GutTest
## ADR-034: quando aceitar uma missão nova exige confirmação. Usa só QuestDef
## (repetível, nome, alvo) e o progresso; nada de deduzir pelo nome da missão.


func _quest(repetivel: bool, alvo: int = 5, nome: String = "Atual") -> QuestDef:
	var quest := QuestDef.new()
	quest.quest_id = "q_" + nome
	quest.nome = nome
	quest.repetivel = repetivel
	quest.quantidade_alvo = alvo
	return quest


func test_sem_missao_ativa_nao_pede_confirmacao() -> void:
	assert_false(SubstituicaoQuest.exige_confirmacao(null, 0))
	assert_false(SubstituicaoQuest.exige_confirmacao(null, 3))


func test_missao_repetivel_troca_direto_mesmo_com_progresso() -> void:
	assert_false(SubstituicaoQuest.exige_confirmacao(_quest(true), 3))


func test_missao_nao_repetivel_sem_progresso_troca_direto() -> void:
	assert_false(SubstituicaoQuest.exige_confirmacao(_quest(false), 0))


func test_missao_nao_repetivel_com_progresso_exige_confirmacao() -> void:
	assert_true(SubstituicaoQuest.exige_confirmacao(_quest(false), 1))


func test_texto_informa_a_missao_atual_o_progresso_e_a_nova() -> void:
	var texto := SubstituicaoQuest.texto_confirmacao(
		_quest(false, 5, "Lenhador"), 2, _quest(true, 1, "Colecionador")
	)

	assert_string_contains(texto, "Lenhador")
	assert_string_contains(texto, "2/5")
	assert_string_contains(texto, "Colecionador")
	assert_string_contains(texto, "perdido")
