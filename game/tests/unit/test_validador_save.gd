extends GutTest
## ADR-038: validação semântica do save. Cada regra espelha o que
## scenes/menu.gd::_ao_continuar e os desserializadores exigem do formato real.

const V := 1


func _completo() -> Dictionary:
	## Mesmas chaves e tipos de scenes/main.gd::salvar_jogo, via JSON (números viram float).
	return (
		JSON
		. parse_string(
			(
				JSON
				. stringify(
					{
						"seed": 555,
						"tempo_de_jogo_seg": 12.5,
						"ciclo_dia_noite_seg": 30.0,
						"vida_atual": 20,
						"fome_atual": 18,
						"energia_atual": 10,
						"hotbar_selecionado": 2,
						"aparencia": {"cor_pele": [1, 0.8, 0.6, 1]},
						"hotbar": [{"item_id": "pedra", "quantidade": 3}, {}],
						"mochila": [{}, {}],
						"delta_blocos": {"3,40,3": 3},
						"jogador_posicao": [64.5, 33.0, 64.5],
						"ponto_respawn": [64, 33, 64],
						"baus": {"1,2,3": [{}, {"item_id": "tocha", "quantidade": 1}]},
						"equipe_cubelins": [{"especie_id": "brasita", "nivel": 4}],
						"deposito_cubelins": [],
						"quest_atual_id": "quest_01_boas_vindas",
						"progresso_quest_atual": 2,
						"quests_concluidas": ["quest_a"],
						"insignias_conquistadas": ["pedra"],
						"especies_vistas": ["brotinho"],
						"especies_capturadas": [],
						"treinadores_vencidos": {"treinador_tico": 0},
						"schema_version": 1,
					}
				)
			)
		)
	)


func _r(dados: Variant) -> ValidadorSave.Resultado:
	return ValidadorSave.avaliar(dados, V)


func test_save_completo_com_todos_os_campos_e_valido() -> void:
	assert_eq(_r(_completo()), ValidadorSave.Resultado.VALIDO)


func test_save_minimo_so_com_seed_e_valido_porque_saves_antigos_nao_tinham_o_resto() -> void:
	assert_eq(_r({"seed": 1}), ValidadorSave.Resultado.VALIDO)


func test_save_antigo_sem_campos_do_ciclo_9_continua_valido() -> void:
	var antigo := _completo()
	for chave: String in ["treinadores_vencidos", "especies_vistas", "especies_capturadas"]:
		antigo.erase(chave)

	assert_eq(_r(antigo), ValidadorSave.Resultado.VALIDO)


func test_sem_schema_version_conta_como_versao_1() -> void:
	var s := _completo()
	s.erase("schema_version")

	assert_eq(_r(s), ValidadorSave.Resultado.VALIDO)


func test_vazio_e_distinto_de_estrutura_invalida() -> void:
	assert_eq(_r({}), ValidadorSave.Resultado.VAZIO)


func test_nao_objeto_e_estrutura_invalida() -> void:
	assert_eq(_r([1, 2]), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)
	assert_eq(_r("texto"), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)
	assert_eq(_r(null), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)
	assert_eq(_r(7), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)


func test_sem_o_campo_obrigatorio_e_invalido() -> void:
	var s := _completo()
	s.erase("seed")

	assert_eq(_r(s), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)
	assert_eq(_r({"hotbar": []}), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)


func test_campo_obrigatorio_com_tipo_errado_e_invalido() -> void:
	for ruim: Variant in ["abc", [1], {"a": 1}, null, true]:
		var s := _completo()
		s["seed"] = ruim
		assert_eq(_r(s), ValidadorSave.Resultado.ESTRUTURA_INVALIDA, "seed=%s" % str(ruim))


func test_tipo_errado_em_cada_familia_de_campo_presente_e_invalido() -> void:
	var casos := {
		"vida_atual": "20",  ## número esperado
		"quest_atual_id": 5,  ## texto esperado
		"aparencia": [1, 2],  ## objeto esperado
		"baus": [1],  ## objeto esperado
		"hotbar": "x",  ## lista esperada
	}
	for chave: String in casos:
		var s := _completo()
		s[chave] = casos[chave]
		assert_eq(_r(s), ValidadorSave.Resultado.ESTRUTURA_INVALIDA, chave)


func test_elementos_com_tipo_errado_dentro_das_listas_sao_invalidos() -> void:
	var casos := {
		"hotbar": [1, 2],  ## slots são objetos
		"equipe_cubelins": ["brasita"],  ## cubelins são objetos
		"insignias_conquistadas": [1],  ## textos
		"quests_concluidas": [{"a": 1}],
		"jogador_posicao": [1, "x", 3],  ## números
	}
	for chave: String in casos:
		var s := _completo()
		s[chave] = casos[chave]
		assert_eq(_r(s), ValidadorSave.Resultado.ESTRUTURA_INVALIDA, chave)


func test_bau_com_conteudo_que_nao_e_lista_de_slots_e_invalido() -> void:
	var s := _completo()
	s["baus"] = {"1,2,3": "vazio"}

	assert_eq(_r(s), ValidadorSave.Resultado.ESTRUTURA_INVALIDA)


func test_versao_de_esquema_futura_e_classificada_sem_julgar_a_estrutura() -> void:
	assert_eq(_r({"seed": 1, "schema_version": 2}), ValidadorSave.Resultado.VERSAO_FUTURA)
	assert_eq(_r({"outra_coisa": 1, "schema_version": 99}), ValidadorSave.Resultado.VERSAO_FUTURA)


func test_versao_de_esquema_malformada_e_invalida() -> void:
	for ruim: Variant in [0, -1, 1.5, "1", [1], null]:
		assert_eq(
			_r({"seed": 1, "schema_version": ruim}),
			ValidadorSave.Resultado.ESTRUTURA_INVALIDA,
			"schema_version=%s" % str(ruim)
		)


func test_validador_nao_altera_nem_completa_os_dados() -> void:
	var s := {"seed": 1}
	var copia := s.duplicate(true)

	_r(s)

	assert_eq(s, copia, "nada é preenchido com valores padrão")
