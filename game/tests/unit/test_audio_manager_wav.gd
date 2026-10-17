extends GutTest
## Frente 5D (ADR-028): o AudioManager só toca AudioStreamWAV gerados em código,
## troca a música com dia/noite/batalha e mantém os loops de ambiente (vento
## sempre, pássaros de dia, grilos de noite) com fade.


func before_each() -> void:
	GameState.mudar_estado(GameState.State.BOOT)  ## sem o autostart do _process
	AudioManager._em_batalha = false
	AudioManager._musica_atual = ""
	AudioManager._musica_periodo = "dia"


func after_all() -> void:
	GameState.mudar_estado(GameState.State.BOOT)


func _ultimo_player() -> AudioStreamPlayer:
	return AudioManager.get_child(AudioManager.get_child_count() - 1) as AudioStreamPlayer


func test_tocar_sfx_cria_player_com_wav_no_bus_sfx_e_conta() -> void:
	var filhos_antes := AudioManager.get_child_count()
	var contados_antes := AudioManager.sfx_tocados
	AudioManager.tocar_sfx("quebrar")
	assert_eq(AudioManager.get_child_count(), filhos_antes + 1)
	var player := _ultimo_player()
	assert_not_null(player)
	assert_is(player.stream, AudioStreamWAV)
	assert_eq(player.bus, "SFX")
	assert_true(player.playing)
	assert_eq(AudioManager.sfx_tocados, contados_antes + 1)


func test_todos_os_sfx_sao_wav_gerados_uma_vez_em_cache() -> void:
	for nome: String in AudioManager.SFX:
		assert_true(AudioManager._sfx_cache.has(nome), nome)
		var stream: AudioStreamWAV = AudioManager._sfx_cache[nome]
		assert_not_null(stream, nome)
		assert_gt(stream.get_length(), 0.0, nome)
	AudioManager.tocar_sfx("craft")
	var player := _ultimo_player()
	assert_same(player.stream, AudioManager._sfx_cache["craft"], "reaproveita o stream do cache")


func test_player_de_sfx_e_liberado_depois_de_tocar() -> void:
	AudioManager.tocar_sfx("ui_clique")
	var player := _ultimo_player()
	await wait_seconds(0.5)
	assert_false(is_instance_valid(player), "player curto deveria ter sido liberado")


func test_noite_registra_a_faixa_mas_nao_toca_musica() -> void:
	## Decisão do dono (17/out/2026): só som ambiente e efeitos, sem música.
	assert_false(AudioManager.MUSICA_LIGADA)
	EventBus.night_started.emit()
	assert_eq(AudioManager._musica_atual, "noite")
	assert_null(AudioManager._music_player, "nenhum player de música é criado")


func test_dia_toca_musica_dia() -> void:
	EventBus.day_started.emit()
	assert_eq(AudioManager._musica_atual, "dia")


func test_batalha_troca_a_musica_e_volta_ao_periodo_no_fim() -> void:
	EventBus.day_started.emit()
	EventBus.battle_started.emit(null)
	assert_eq(AudioManager._musica_atual, "batalha")
	EventBus.battle_ended.emit()
	assert_eq(AudioManager._musica_atual, "dia")


func test_noite_durante_a_batalha_nao_interrompe_e_vale_depois() -> void:
	EventBus.day_started.emit()
	EventBus.battle_started.emit(null)
	EventBus.night_started.emit()
	assert_eq(AudioManager._musica_atual, "batalha")
	EventBus.battle_ended.emit()
	assert_eq(AudioManager._musica_atual, "noite")


func test_musica_desconhecida_sem_arquivo_fica_em_silencio() -> void:
	AudioManager.tocar_musica("bioma_que_nao_existe")
	assert_eq(AudioManager._musica_atual, "")


func test_entrar_no_jogo_comeca_a_musica_do_periodo() -> void:
	GameState.ciclo_dia_noite_seg = 0.0
	GameState.mudar_estado(GameState.State.PLAYING)
	await wait_process_frames(2)
	assert_eq(AudioManager._musica_atual, "dia")


func test_ambiente_vento_sempre_passaros_de_dia_grilos_de_noite() -> void:
	EventBus.day_started.emit()
	var vento: AudioStreamPlayer = AudioManager._ambiente["vento"]
	var passaros: AudioStreamPlayer = AudioManager._ambiente["passaros"]
	var grilos: AudioStreamPlayer = AudioManager._ambiente["grilos"]
	assert_true(vento.playing, "vento toca sempre")
	assert_true(passaros.playing, "pássaros começam de dia")
	assert_is(passaros.stream, AudioStreamWAV)
	await wait_seconds(AudioManager.FADE_AMBIENTE_SEG + 0.3)
	assert_false(grilos.playing, "grilos calados de dia")
	assert_almost_eq(passaros.volume_db, AudioManager.DB_PASSAROS_GRILOS, 0.1)
	EventBus.night_started.emit()
	assert_true(grilos.playing, "grilos começam de noite")
	await wait_seconds(AudioManager.FADE_AMBIENTE_SEG + 0.3)
	assert_false(passaros.playing, "pássaros calados de noite")
	assert_true(vento.playing)
	assert_almost_eq(vento.volume_db, AudioManager.DB_VENTO, 0.1)


func test_audio_continua_com_a_arvore_pausada() -> void:
	assert_eq(AudioManager.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_players_ativos_conta_quem_esta_tocando() -> void:
	EventBus.day_started.emit()
	assert_gt(AudioManager.players_ativos(), 0)
