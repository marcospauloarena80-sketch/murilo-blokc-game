extends GutTest
## Ver docs/04-ROADMAP.md F7 (FSM Idle/Wander/Flee/Aggro) e docs/07-DECISOES.md ADR-020.


func _def_passivo() -> CreatureDef:
	var def := CreatureDef.new()
	def.eh_agressivo = false
	def.raio_deteccao = 5.0
	return def


func _def_agressivo() -> CreatureDef:
	var def := CreatureDef.new()
	def.eh_agressivo = true
	def.raio_deteccao = 5.0
	return def


func test_comeca_em_idle() -> void:
	var comportamento := CreatureBehavior.new(_def_passivo())
	assert_eq(comportamento.estado, CreatureBehavior.Estado.IDLE)


func test_passivo_com_jogador_perto_foge() -> void:
	var comportamento := CreatureBehavior.new(_def_passivo())
	var direcao := comportamento.atualizar(0.1, Vector3(0, 0, 0), Vector3(2, 0, 0))
	assert_eq(comportamento.estado, CreatureBehavior.Estado.FLEE)
	assert_almost_eq(direcao.x, -1.0, 0.01, "deveria fugir pro lado oposto ao jogador")


func test_agressivo_com_jogador_perto_persegue() -> void:
	var comportamento := CreatureBehavior.new(_def_agressivo())
	var direcao := comportamento.atualizar(0.1, Vector3(0, 0, 0), Vector3(2, 0, 0))
	assert_eq(comportamento.estado, CreatureBehavior.Estado.AGGRO)
	assert_almost_eq(direcao.x, 1.0, 0.01, "deveria perseguir na direção do jogador")


func test_passivo_com_jogador_longe_fica_parado_ou_idle() -> void:
	var comportamento := CreatureBehavior.new(_def_passivo())
	var direcao := comportamento.atualizar(0.1, Vector3(0, 0, 0), Vector3(100, 0, 100))
	assert_eq(comportamento.estado, CreatureBehavior.Estado.IDLE)
	assert_eq(direcao, Vector3.ZERO)


func test_idle_vira_wander_apos_tempo_sem_jogador_por_perto() -> void:
	var comportamento := CreatureBehavior.new(_def_passivo())
	var longe := Vector3(100, 0, 100)
	comportamento.atualizar(CreatureBehavior.TEMPO_MAX_IDLE + 0.1, Vector3.ZERO, longe)
	assert_eq(comportamento.estado, CreatureBehavior.Estado.WANDER)


func test_wander_tem_direcao_normalizada() -> void:
	var comportamento := CreatureBehavior.new(_def_passivo())
	var longe := Vector3(100, 0, 100)
	var direcao := comportamento.atualizar(
		CreatureBehavior.TEMPO_MAX_IDLE + 0.1, Vector3.ZERO, longe
	)
	assert_almost_eq(direcao.length(), 1.0, 0.01)


func test_wander_volta_a_idle_apos_tempo() -> void:
	var comportamento := CreatureBehavior.new(_def_passivo())
	var longe := Vector3(100, 0, 100)
	comportamento.atualizar(CreatureBehavior.TEMPO_MAX_IDLE + 0.1, Vector3.ZERO, longe)
	assert_eq(comportamento.estado, CreatureBehavior.Estado.WANDER)
	comportamento.atualizar(CreatureBehavior.TEMPO_MAX_WANDER + 0.1, Vector3.ZERO, longe)
	assert_eq(comportamento.estado, CreatureBehavior.Estado.IDLE)


func test_jogador_se_afasta_depois_de_fuga_volta_pra_idle() -> void:
	var comportamento := CreatureBehavior.new(_def_passivo())
	comportamento.atualizar(0.1, Vector3.ZERO, Vector3(2, 0, 0))
	assert_eq(comportamento.estado, CreatureBehavior.Estado.FLEE)
	comportamento.atualizar(0.1, Vector3.ZERO, Vector3(100, 0, 100))
	assert_eq(comportamento.estado, CreatureBehavior.Estado.IDLE)


func test_distancia_exatamente_no_raio_conta_como_perto() -> void:
	var comportamento := CreatureBehavior.new(_def_agressivo())
	comportamento.atualizar(0.1, Vector3.ZERO, Vector3(5, 0, 0))
	assert_eq(comportamento.estado, CreatureBehavior.Estado.AGGRO)
