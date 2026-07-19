extends GutTest
## Ver docs/04-ROADMAP.md F7 (spawn por horário) e docs/07-DECISOES.md ADR-020.


func _jogador_falso(pos: Vector3) -> Node3D:
	var jogador := Node3D.new()
	jogador.add_to_group("player")
	add_child_autofree(jogador)
	jogador.global_position = pos
	return jogador


func test_altura_da_superficie_encontra_chao_dentro_do_mundo() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 50
	add_child_autofree(cm)
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)
	spawner._chunk_manager = cm

	assert_gt(spawner._altura_da_superficie(64, 64), -1)


func test_altura_da_superficie_fora_do_mundo_retorna_menos_1() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 51
	add_child_autofree(cm)
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)
	spawner._chunk_manager = cm

	assert_eq(spawner._altura_da_superficie(99999, 99999), -1)


func test_nao_spawna_alem_do_limite_de_populacao() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 52
	add_child_autofree(cm)
	_jogador_falso(Vector3(64, 45, 64))
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)

	for i in range(CreatureSpawner.MAX_CRIATURAS):
		var falsa := Node3D.new()
		falsa.add_to_group("creature")
		add_child_autofree(falsa)

	spawner._tentar_spawnar()

	assert_eq(spawner.get_child_count(), 0, "não deveria spawnar acima do limite")


func test_spawn_de_dia_so_gera_especies_passivas() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 53
	add_child_autofree(cm)
	_jogador_falso(Vector3(64, 45, 64))
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)

	GameState.ciclo_dia_noite_seg = GameState.DURACAO_CICLO_SEG * 0.1  # meio do dia

	spawner._tentar_spawnar()

	if spawner.get_child_count() > 0:
		var criatura: Creature = spawner.get_child(0)
		assert_eq(criatura.especie.periodo_spawn, "dia")


func test_spawn_de_noite_so_gera_especies_agressivas() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 54
	add_child_autofree(cm)
	_jogador_falso(Vector3(64, 45, 64))
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)

	GameState.ciclo_dia_noite_seg = GameState.DURACAO_CICLO_SEG * 0.9  # meio da noite

	spawner._tentar_spawnar()

	if spawner.get_child_count() > 0:
		var criatura: Creature = spawner.get_child(0)
		assert_eq(criatura.especie.periodo_spawn, "noite")


func test_despawna_criatura_muito_distante() -> void:
	var jogador := _jogador_falso(Vector3.ZERO)
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)
	spawner._jogador = jogador

	var criatura_longe := Node3D.new()
	criatura_longe.add_to_group("creature")
	add_child_autofree(criatura_longe)
	criatura_longe.global_position = Vector3(200, 0, 200)

	spawner._despawnar_distantes()

	assert_true(criatura_longe.is_queued_for_deletion())


func test_nao_despawna_criatura_perto() -> void:
	var jogador := _jogador_falso(Vector3.ZERO)
	var spawner := CreatureSpawner.new()
	add_child_autofree(spawner)
	spawner._jogador = jogador

	var criatura_perto := Node3D.new()
	criatura_perto.add_to_group("creature")
	add_child_autofree(criatura_perto)
	criatura_perto.global_position = Vector3(5, 0, 5)

	spawner._despawnar_distantes()

	assert_false(criatura_perto.is_queued_for_deletion())
