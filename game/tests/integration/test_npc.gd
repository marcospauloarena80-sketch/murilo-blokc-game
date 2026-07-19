extends GutTest
## Ver docs/01-GDD.md §12 e docs/07-DECISOES.md ADR-022.

const NpcScene := preload("res://entities/npcs/npc.tscn")


func test_configurar_aplica_a_definicao() -> void:
	var def := NpcDef.new()
	def.npc_id = "teste_npc"
	def.nome = "Fulano"
	def.cor = Color(1, 0, 0, 1)

	var npc := NpcScene.instantiate() as Npc
	add_child_autofree(npc)
	npc.configurar(def)

	assert_eq(npc.def, def)
	assert_eq(npc.def.nome, "Fulano")


func test_npc_entra_no_grupo_npc() -> void:
	var npc := NpcScene.instantiate() as Npc
	add_child_autofree(npc)

	assert_true(npc.is_in_group("npc"))
