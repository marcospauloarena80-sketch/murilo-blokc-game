extends GutTest
## Ver docs/07-DECISOES.md ADR-015. Testa a lógica de seleção/preview/confirmação
## direto (sem depender de clique simulado em navegador — automação de clique em
## canvas WebGL não é confiável nesta ferramenta, mesmo problema já visto no F1/F2).

const PlayerScene := preload("res://entities/player/player.tscn")
const CharacterCreatorScene := preload("res://ui/character_creator/character_creator.tscn")


func test_escolher_cor_atualiza_estado_e_preview_do_player() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 1
	add_child_autofree(cm)

	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	var criador := CharacterCreatorScene.instantiate()
	add_child_autofree(criador)

	criador._ao_escolher_camisa(Color.RED)

	assert_eq(GameState.aparencia_atual.cor_camisa, Color.RED)
	assert_eq(player._mat_camisa.albedo_color, Color.RED, "preview ao vivo deveria tingir o tronco")


func test_confirmar_muda_estado_para_playing_e_remove_a_tela() -> void:
	var cm := ChunkManager.new()
	cm.world_seed = 2
	add_child_autofree(cm)

	var criador := CharacterCreatorScene.instantiate()
	add_child_autofree(criador)

	assert_eq(GameState.current_state, GameState.State.CHARACTER_CREATION)
	criador._ao_confirmar()
	assert_eq(GameState.current_state, GameState.State.PLAYING)


func test_movimento_do_player_fica_mudo_fora_do_estado_playing() -> void:
	GameState.mudar_estado(GameState.State.CHARACTER_CREATION)
	var cm := ChunkManager.new()
	cm.world_seed = 3
	add_child_autofree(cm)

	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)

	while cm.tem_chunks_pendentes():
		cm._process(0.0)

	var pos_antes := player.global_position
	Input.action_press("mover_frente")
	player._physics_process(1.0 / 60.0)
	Input.action_release("mover_frente")

	assert_eq(
		player.global_position.x,
		pos_antes.x,
		"sem estar em PLAYING, input de movimento não deve mover o player no plano XZ"
	)
