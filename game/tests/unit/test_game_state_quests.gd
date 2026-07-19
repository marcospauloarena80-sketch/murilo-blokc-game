extends GutTest
## Ver docs/01-GDD.md §12 e docs/07-DECISOES.md ADR-022.

var _quest_teste: QuestDef


func before_each() -> void:
	_quest_teste = QuestDef.new()
	_quest_teste.quest_id = "teste_coletar_pedra"
	_quest_teste.tipo = "coletar"
	_quest_teste.alvo_id = "pedra"
	_quest_teste.quantidade_alvo = 3
	QuestRegistry._quests[_quest_teste.quest_id] = _quest_teste

	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []


func after_each() -> void:
	QuestRegistry._quests.erase(_quest_teste.quest_id)
	GameState.quest_atual_id = ""
	GameState.progresso_quest_atual = 0
	GameState.quests_concluidas = []


func test_sem_quest_ativa_quest_atual_e_null() -> void:
	assert_null(GameState.quest_atual())


func test_iniciar_quest_define_atual_e_zera_progresso() -> void:
	GameState.progresso_quest_atual = 5
	GameState.iniciar_quest("teste_coletar_pedra")
	assert_eq(GameState.quest_atual_id, "teste_coletar_pedra")
	assert_eq(GameState.progresso_quest_atual, 0)
	assert_eq(GameState.quest_atual(), _quest_teste)


func test_quest_atual_completa_falso_sem_quest_ativa() -> void:
	assert_false(GameState.quest_atual_completa())


func test_quest_atual_completa_falso_com_progresso_insuficiente() -> void:
	GameState.iniciar_quest("teste_coletar_pedra")
	GameState.progresso_quest_atual = 2
	assert_false(GameState.quest_atual_completa())


func test_quest_atual_completa_verdadeiro_no_alvo_exato() -> void:
	GameState.iniciar_quest("teste_coletar_pedra")
	GameState.progresso_quest_atual = 3
	assert_true(GameState.quest_atual_completa())


func test_quest_atual_completa_verdadeiro_acima_do_alvo() -> void:
	GameState.iniciar_quest("teste_coletar_pedra")
	GameState.progresso_quest_atual = 10
	assert_true(GameState.quest_atual_completa())
