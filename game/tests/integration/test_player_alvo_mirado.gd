extends GutTest
## Nome do alvo sob a mira (Ciclo 5, Frente 5E): o Player expõe alvo_mirado e
## alvo_tipo a partir do raio real da mira. Mesmo padrão de test_player_mira.gd:
## ChunkManager real, filas drenadas, física de verdade.

const PlayerScene := preload("res://entities/player/player.tscn")
const NpcScene := preload("res://entities/npcs/npc.tscn")
const CreatureScene := preload("res://entities/creatures/creature.tscn")
## O braço da câmera sobe 5° fixos e a câmera olha 5° pra baixo (player.tscn);
## com o pivô girado em +5° o raio sai exatamente horizontal, 1,2 acima do
## centro do jogador e 0,55 à direita (ombro): posição previsível pros alvos.
const INCLINACAO_BRACO: float = 0.0872665
const POSICAO_JOGADOR := Vector3(20.5, 58.0, 20.5)
## Onde o raio horizontal passa, 3 blocos à frente (o jogador olha pra -Z).
const POSICAO_ALVO := Vector3(21.05, 59.2, 17.5)

var _cm: ChunkManager


func _drenar() -> void:
	while _cm.tem_chunks_pendentes():
		_cm._process(0.0)


func _montar_jogador() -> Player:
	_cm = ChunkManager.new()
	_cm.world_seed = 1
	add_child_autofree(_cm)
	_drenar()
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	player.set_physics_process(false)
	player.global_position = POSICAO_JOGADOR
	player.camera_pivot.rotation.x = INCLINACAO_BRACO
	return player


func test_bloco_mirado_da_nome_e_tipo_bloco() -> void:
	var player := _montar_jogador()
	## Parede de pedra flutuando acima do terreno, 3 blocos à frente.
	for dx in range(-2, 3):
		for dy in range(-5, 3):
			_cm.set_block(Vector3i(20 + dx, 58 + dy, 17), 3)
	_drenar()
	await wait_physics_frames(3)

	player._processar_mira_e_interacao(0.0)

	assert_eq(player.alvo_tipo, "bloco")
	assert_eq(player.alvo_mirado, "Pedra")


func test_npc_mirado_da_nome_da_definicao() -> void:
	var player := _montar_jogador()
	var npc := NpcScene.instantiate() as Npc
	add_child_autofree(npc)
	npc.configurar(NpcRegistry.get_npc("lina"))
	## O NPC tem a origem nos pés (caixa deslocada 0,9 pra cima em npc.tscn).
	npc.global_position = POSICAO_ALVO - Vector3(0.0, 0.9, 0.0)
	await wait_physics_frames(3)

	player._processar_mira_e_interacao(0.0)

	assert_eq(player.alvo_tipo, "npc")
	assert_eq(player.alvo_mirado, "Professora Lina")


func test_criatura_mirada_da_nome_da_especie() -> void:
	var player := _montar_jogador()
	var criatura := CreatureScene.instantiate() as Creature
	add_child_autofree(criatura)
	criatura.configurar(CreatureRegistry.get_creature("brotinho"))
	criatura.set_physics_process(false)
	criatura.global_position = POSICAO_ALVO
	await wait_physics_frames(3)

	player._processar_mira_e_interacao(0.0)

	assert_eq(player.alvo_tipo, "criatura")
	assert_eq(player.alvo_mirado, "Brotinho")


func test_sem_nada_na_mira_o_alvo_e_zerado() -> void:
	var player := _montar_jogador()
	player.alvo_mirado = "Pedra"
	player.alvo_tipo = "bloco"
	## Olhando pro céu: nada ao alcance do raio.
	player.camera_pivot.rotation.x = 0.8
	await wait_physics_frames(3)

	player._processar_mira_e_interacao(0.0)

	assert_eq(player.alvo_mirado, "")
	assert_eq(player.alvo_tipo, "")
