extends GutTest
## Ver docs/04-ROADMAP.md F7 e docs/07-DECISOES.md ADR-020.
## Testa lógica direto (padrão test_loot_system.gd/test_player_hotbar_tools.gd)
## em vez de simular física real entre frames.

const CreatureScene := preload("res://entities/creatures/creature.tscn")


func _def_passivo() -> CreatureDef:
	var def := CreatureDef.new()
	def.eh_agressivo = false
	def.dano_contato = 0
	def.vida_maxima = 5
	return def


func _def_agressivo() -> CreatureDef:
	var def := CreatureDef.new()
	def.eh_agressivo = true
	def.dano_contato = 3
	def.vida_maxima = 10
	return def


func test_configurar_define_vida_maxima() -> void:
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)

	criatura.configurar(_def_agressivo())

	assert_eq(criatura.vida_atual, 10)


func test_receber_dano_reduz_vida() -> void:
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	criatura.configurar(_def_passivo())

	criatura.receber_dano(2)

	assert_eq(criatura.vida_atual, 3)


func test_receber_dano_fatal_remove_a_criatura() -> void:
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	criatura.configurar(_def_passivo())

	criatura.receber_dano(999)

	assert_eq(criatura.vida_atual, 0)
	assert_true(criatura.is_queued_for_deletion())


func test_criatura_agressiva_causa_dano_de_contato() -> void:
	GameState.vida_atual = GameState.vida_maxima
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	criatura.configurar(_def_agressivo())

	var jogador_falso := Node3D.new()
	jogador_falso.add_to_group("player")
	add_child_autofree(jogador_falso)

	criatura._ao_tocar_jogador(jogador_falso)

	assert_eq(GameState.vida_atual, GameState.vida_maxima - 3)


func test_criatura_passiva_nao_causa_dano_de_contato() -> void:
	GameState.vida_atual = GameState.vida_maxima
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	criatura.configurar(_def_passivo())

	var jogador_falso := Node3D.new()
	jogador_falso.add_to_group("player")
	add_child_autofree(jogador_falso)

	criatura._ao_tocar_jogador(jogador_falso)

	assert_eq(GameState.vida_atual, GameState.vida_maxima)


func test_corpo_que_nao_e_player_nao_causa_dano() -> void:
	GameState.vida_atual = GameState.vida_maxima
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	criatura.configurar(_def_agressivo())

	var outro_corpo := Node3D.new()
	add_child_autofree(outro_corpo)

	criatura._ao_tocar_jogador(outro_corpo)

	assert_eq(GameState.vida_atual, GameState.vida_maxima)


func test_dano_de_contato_respeita_cooldown() -> void:
	GameState.vida_atual = GameState.vida_maxima
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	criatura.configurar(_def_agressivo())

	var jogador_falso := Node3D.new()
	jogador_falso.add_to_group("player")
	add_child_autofree(jogador_falso)

	criatura._ao_tocar_jogador(jogador_falso)
	criatura._ao_tocar_jogador(jogador_falso)

	assert_eq(
		GameState.vida_atual,
		GameState.vida_maxima - 3,
		"segundo toque dentro do cooldown não conta"
	)
