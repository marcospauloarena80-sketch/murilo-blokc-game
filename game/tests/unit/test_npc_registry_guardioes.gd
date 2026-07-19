extends GutTest
## Ver docs/01-GDD.md §13 e docs/07-DECISOES.md ADR-023.

const GUARDIOES_REGULARES := {
	"guardiao_pedra": "pedra",
	"guardiao_brasa": "brasa",
	"guardiao_gota": "gota",
	"guardiao_faisca": "faisca",
}


func test_4_guardioes_regulares_abrem_a_arena_certa() -> void:
	for npc_id: String in GUARDIOES_REGULARES:
		var npc := NpcRegistry.get_npc(npc_id)
		assert_not_null(npc, "NPC '%s' deveria existir" % npc_id)
		assert_eq(npc.abre_arena, GUARDIOES_REGULARES[npc_id])


func test_guardioes_referenciam_arena_existente() -> void:
	for npc_id: String in GUARDIOES_REGULARES:
		var npc := NpcRegistry.get_npc(npc_id)
		assert_not_null(ArenaRegistry.get_arena(npc.abre_arena))


func test_guardiao_final_abre_coracao_dourado() -> void:
	var npc := NpcRegistry.get_npc("guardiao_final")
	assert_not_null(npc)
	assert_eq(npc.abre_arena, "coracao_dourado")


func test_npcs_nao_guardioes_nao_abrem_arena() -> void:
	for id: String in ["lina", "refugio", "comerciante", "construtor"]:
		assert_eq(NpcRegistry.get_npc(id).abre_arena, "")
