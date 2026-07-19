extends GutTest
## Ver docs/01-GDD.md §9/§13 e docs/07-DECISOES.md ADR-023 (roster 12/6 sem
## bioma ainda — só usadas em batalhas de Guardião até a F11).

const ELEMENTOS := ["pedra", "mato", "brasa", "gota", "vento", "faisca"]
const ESPECIES_SEM_BIOMA := [
	"brasita",
	"gotelo",
	"rochedo",
	"centelha",
	"folhaz",
	"folharaiz",
	"brisim",
	"brisura",
	"chamote",
	"chamarao",
	"maruja",
	"marejao"
]
const EVOLUCOES_F10 := {
	"folhaz": "folharaiz",
	"brisim": "brisura",
	"chamote": "chamarao",
	"maruja": "marejao",
}


func test_12_especies_base_existem() -> void:
	for id: String in ESPECIES_SEM_BIOMA:
		assert_not_null(CreatureRegistry.get_creature(id), "espécie '%s' deveria existir" % id)


func test_2_especies_por_elemento() -> void:
	for elemento: String in ELEMENTOS:
		var contagem := 0
		for id: String in CreatureRegistry.todos_os_ids():
			if CreatureRegistry.get_creature(id).elemento == elemento:
				contagem += 1
		assert_eq(
			contagem, 3, "elemento '%s' deveria ter 3 formas (2 espécies, 1 evolui)" % elemento
		)


func test_especies_novas_nao_spawnam_selvagens_ainda() -> void:
	for id: String in ESPECIES_SEM_BIOMA:
		var def := CreatureRegistry.get_creature(id)
		assert_false(
			def.pode_ser_selvagem, "%s ainda não tem bioma (F11) — não deveria spawnar" % id
		)


func test_6_especies_evoluem_no_total() -> void:
	var evolutivas := 0
	for id: String in CreatureRegistry.todos_os_ids():
		if CreatureRegistry.get_creature(id).nivel_evolucao > 0:
			evolutivas += 1
	assert_eq(evolutivas, 6)


func test_evolucoes_f10_apontam_pra_especie_existente() -> void:
	for base_id: String in EVOLUCOES_F10:
		var def := CreatureRegistry.get_creature(base_id)
		assert_eq(def.especie_evolucao, EVOLUCOES_F10[base_id])
		assert_not_null(CreatureRegistry.get_creature(def.especie_evolucao))


func test_formas_evoluidas_f10_nao_evoluem_de_novo() -> void:
	for evoluida_id: String in EVOLUCOES_F10.values():
		var def := CreatureRegistry.get_creature(evoluida_id)
		assert_eq(def.nivel_evolucao, 0)
		assert_eq(def.especie_evolucao, "")


func test_todas_as_novas_especies_referenciam_ataques_validos() -> void:
	for id: String in ESPECIES_SEM_BIOMA:
		var def := CreatureRegistry.get_creature(id)
		for nivel: int in def.aprendizado_ataques:
			var ataque_id: String = def.aprendizado_ataques[nivel]
			assert_not_null(
				AttackRegistry.get_ataque(ataque_id), "%s referencia ataque inexistente" % id
			)
