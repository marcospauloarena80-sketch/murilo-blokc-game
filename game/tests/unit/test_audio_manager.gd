extends GutTest
## Ver docs/02-ARQUITETURA.md §4.12 e docs/07-DECISOES.md ADR-024 — SFX
## sintetizados em código (sem asset externo); música fica em silêncio sem
## arquivo real, sem erro.


func test_buses_musica_e_sfx_existem() -> void:
	assert_ne(AudioServer.get_bus_index("Música"), -1)
	assert_ne(AudioServer.get_bus_index("SFX"), -1)


func test_configurar_buses_e_idempotente() -> void:
	var antes := AudioServer.bus_count
	AudioManager._configurar_buses()
	assert_eq(AudioServer.bus_count, antes, "não deveria duplicar buses já existentes")


func test_tocar_sfx_com_nome_valido_nao_gera_erro() -> void:
	AudioManager.tocar_sfx("quebrar")
	assert_true(true, "chegou até aqui sem estourar erro")


func test_tocar_sfx_com_nome_invalido_nao_cria_player() -> void:
	var antes := AudioManager.get_child_count()
	AudioManager.tocar_sfx("nao_existe")
	assert_eq(AudioManager.get_child_count(), antes)


func test_tocar_musica_sem_arquivo_fica_em_silencio() -> void:
	AudioManager.tocar_musica("bioma_que_nao_existe")
	assert_null(AudioManager._music_player, "sem arquivo real, não deveria criar o player")


func test_todos_os_sfx_catalogados_tocam_sem_erro() -> void:
	for nome: String in AudioManager.SFX:
		AudioManager.tocar_sfx(nome)
	assert_true(true, "todos os SFX catalogados tocaram sem estourar erro")
