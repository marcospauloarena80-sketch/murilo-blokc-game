extends GutTest
## Ciclo 8, Frente 8B: animais (Lanugo, Saltitão) não lutam, dropam comida.

const CreatureScene := preload("res://entities/creatures/creature.tscn")

var _batalhas: int = 0


func _contar_batalha(_criatura: Creature) -> void:
	_batalhas += 1


func _animal(especie_id: String) -> Creature:
	var animal := CreatureScene.instantiate() as Creature
	animal.configurar(CreatureRegistry.get_creature(especie_id))
	add_child_autofree(animal)
	return animal


func test_animais_existem_fora_da_lista_de_cubelins() -> void:
	for id: String in ["lanugo", "saltitao"]:
		var def := CreatureRegistry.get_creature(id)
		assert_not_null(def, id)
		assert_true(def.eh_animal)
		assert_false(CreatureRegistry.todos_os_ids().has(id))
		assert_false(def.drops.is_empty())
		for item_id: String in def.drops:
			assert_not_null(ItemRegistry.get_item(item_id), "drop %s sem item" % item_id)


func test_animal_entra_no_grupo_animal_e_nao_tem_faixa() -> void:
	var animal := _animal("lanugo")
	assert_true(animal.is_in_group("animal"))
	assert_null(animal.get_node_or_null("MeshInstance3D/Faixa"))
	assert_not_null(animal.get_node_or_null("MeshInstance3D/OlhoEsquerdo"))


func test_cubelin_continua_com_faixa_e_fora_do_grupo_animal() -> void:
	var cubelin := CreatureScene.instantiate() as Creature
	cubelin.configurar(CreatureRegistry.get_creature("brotinho"))
	add_child_autofree(cubelin)
	assert_false(cubelin.is_in_group("animal"))
	assert_not_null(cubelin.get_node_or_null("MeshInstance3D/Faixa"))


func test_animal_morto_dropa_carne_pelo_loot_spawner() -> void:
	var loot := LootSpawner.new()
	add_child_autofree(loot)
	var animal := _animal("lanugo")
	animal.receber_dano(999)
	assert_eq(loot.get_child_count(), 1)
	var drop := loot.get_child(0) as ItemDrop
	assert_eq(drop.item_id, "carne_crua")
	assert_between(drop.quantidade, 1, 2)


func test_saltitao_dropa_carne_e_la() -> void:
	var loot := LootSpawner.new()
	add_child_autofree(loot)
	var animal := _animal("saltitao")
	animal.receber_dano(999)
	var ids: Array[String] = []
	for filho in loot.get_children():
		ids.append((filho as ItemDrop).item_id)
	ids.sort()
	assert_eq(ids, ["carne_crua", "la"])


func test_animal_nao_emite_derrota_de_cubelin() -> void:
	var loot := LootSpawner.new()
	add_child_autofree(loot)
	var animal := _animal("lanugo")
	watch_signals(EventBus)
	animal.receber_dano(999)
	assert_signal_not_emitted(EventBus, "creature_defeated")


func test_carne_assada_exige_fornalha_e_restaura_mais_que_a_crua() -> void:
	var receita := RecipeRegistry.get_receita("carne_assada")
	assert_not_null(receita)
	assert_true(receita.exige_fornalha)
	assert_eq(receita.ingredientes, {"carne_crua": 1})
	var crua := ItemRegistry.get_item("carne_crua")
	var assada := ItemRegistry.get_item("carne_assada")
	assert_true(crua.eh_comida and assada.eh_comida)
	assert_eq(assada.restaura_fome, 8)
	assert_gt(assada.restaura_fome, crua.restaura_fome)


func test_interagir_em_animal_nao_abre_batalha_e_mostra_o_nome() -> void:
	var player := preload("res://entities/player/player.tscn").instantiate()
	add_child_autofree(player)
	var animal := _animal("lanugo")
	EventBus.battle_started.connect(_contar_batalha)
	watch_signals(EventBus)
	player.interagir_com_criatura(animal)
	EventBus.battle_started.disconnect(_contar_batalha)
	assert_eq(_batalhas, 0)
	assert_signal_emitted_with_parameters(EventBus, "aviso", ["Lanugo"])


func test_spawner_limita_animais_separado_dos_cubelins() -> void:
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)
	for i in range(CreatureSpawner.MAX_ANIMAIS):
		var falso := Node3D.new()
		falso.add_to_group("creature")
		falso.add_to_group("animal")
		add_child_autofree(falso)
	spawner._tentar_spawnar()
	assert_ne(spawner.ultimo_motivo_sem_spawn, "limite de criaturas", "cubelins ainda cabem")
