extends Node
## Toca música, SFX e ambiente por nome. Não conhece gameplay além dos sinais
## do EventBus. Ver docs/02-ARQUITETURA.md §4.12, ADR-024 e ADR-028 (Ciclo 5):
## todo som é AudioStreamWAV gerado em código pelo Sintetizador (core/audio) —
## na Web o gerador em tempo real não toca no modo de amostras ("trying to play
## a sample from a stream that cannot be sampled") e asset de terceiros é
## proibido. tocar_musica() prefere um .ogg do dono em
## assets/audio/music/<nome>.ogg se existir; senão usa o loop gerado das
## Partituras. Volume por bus continua pelos buses "Música" e "SFX".

const DB_MUSICA: float = -12.0
const DB_VENTO: float = -18.0
const DB_PASSAROS_GRILOS: float = -14.0
const DB_MUDO: float = -60.0
const FADE_AMBIENTE_SEG: float = 2.0
const DURACAO_LOOP_AMBIENTE_SEG: float = 6.0

## Nomes públicos dos SFX (API estável: quem chama usa tocar_sfx(nome)).
const SFX: Array[String] = [
	"quebrar", "colocar", "craft", "captura", "vitoria", "missao", "morte", "ui_clique"
]

var sfx_tocados: int = 0  ## contador pra sonda (muriloAudio)

var _sfx_cache: Dictionary = {}  ## nome -> AudioStreamWAV, gerados uma vez
var _musica_cache: Dictionary = {}  ## nome -> AudioStreamWAV em loop
var _music_player: AudioStreamPlayer
var _ambiente: Dictionary = {}  ## "vento" | "passaros" | "grilos" -> AudioStreamPlayer
var _fades: Dictionary = {}  ## nome do ambiente -> Tween em andamento
var _musica_atual: String = ""
var _musica_periodo: String = "dia"  ## música a retomar quando a batalha acaba
var _em_batalha: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  ## som continua dentro das telas (PAUSED)
	_configurar_buses()
	for nome: String in SFX:
		_sfx_cache[nome] = _gerar_sfx(nome)
	EventBus.block_broken.connect(func(_pos: Vector3i, _id: int) -> void: tocar_sfx("quebrar"))
	EventBus.block_placed.connect(func(_pos: Vector3i, _id: int) -> void: tocar_sfx("colocar"))
	EventBus.recipe_crafted.connect(func(_id: String) -> void: tocar_sfx("craft"))
	EventBus.creature_captured.connect(func(_id: String) -> void: tocar_sfx("captura"))
	EventBus.creature_defeated.connect(func(_id: String) -> void: tocar_sfx("vitoria"))
	EventBus.quest_completed.connect(func(_id: String) -> void: tocar_sfx("missao"))
	EventBus.player_died.connect(tocar_sfx.bind("morte"))
	EventBus.day_started.connect(_ao_mudar_periodo.bind("dia"))
	EventBus.night_started.connect(_ao_mudar_periodo.bind("noite"))
	EventBus.battle_started.connect(_ao_comecar_batalha)
	EventBus.battle_ended.connect(_ao_terminar_batalha)


func _process(_delta: float) -> void:
	## main.gd só emite day/night_started nas transições; ao entrar no mundo a
	## música e o ambiente do período atual precisam começar por conta própria.
	if _musica_atual.is_empty() and GameState.current_state == GameState.State.PLAYING:
		_ao_mudar_periodo("noite" if GameState.eh_noite() else "dia")


func _configurar_buses() -> void:
	## Master já existe por padrão (índice 0). Música/SFX criados uma vez só.
	for nome_bus: String in ["Música", "SFX"]:
		if AudioServer.get_bus_index(nome_bus) == -1:
			AudioServer.add_bus()
			var indice := AudioServer.bus_count - 1
			AudioServer.set_bus_name(indice, nome_bus)
			AudioServer.set_bus_send(indice, "Master")


func tocar_sfx(nome: String) -> void:
	if nome not in SFX:
		return
	if not _sfx_cache.has(nome):
		_sfx_cache[nome] = _gerar_sfx(nome)
	var stream: AudioStreamWAV = _sfx_cache[nome]
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = stream
	add_child(player)
	player.play()
	sfx_tocados += 1
	## Timer, não o sinal `finished` — sob driver de áudio nulo/dummy (ex.:
	## `--headless`) o playback pode nunca "terminar", e o player vazaria pra
	## sempre como filho deste autoload.
	get_tree().create_timer(stream.get_length() + 0.15).timeout.connect(player.queue_free)


func tocar_musica(nome: String) -> void:
	var stream: AudioStream = _carregar_musica(nome)
	if stream == null:
		return  ## nem arquivo do dono nem partitura com esse nome: silêncio, sem erro
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.bus = "Música"
		_music_player.volume_db = DB_MUSICA
		add_child(_music_player)
	if _musica_atual == nome and _music_player.playing:
		return  ## já é essa: não recomeça o loop
	_music_player.stream = stream
	_music_player.play()
	_musica_atual = nome


func players_ativos() -> int:
	## Quantos AudioStreamPlayer (SFX, música e ambiente) estão tocando agora.
	var total := 0
	for filho: Node in get_children():
		var player := filho as AudioStreamPlayer
		if player != null and player.playing:
			total += 1
	return total


func _carregar_musica(nome: String) -> AudioStream:
	var caminho := "res://assets/audio/music/%s.ogg" % nome
	if ResourceLoader.exists(caminho):
		return load(caminho)  ## arquivo do dono tem prioridade (ADR-024)
	if not _musica_cache.has(nome):
		var gerada := _gerar_musica(nome)
		if gerada == null:
			return null
		_musica_cache[nome] = gerada
	return _musica_cache[nome]


func _gerar_musica(nome: String) -> AudioStreamWAV:
	var stream: AudioStreamWAV = null
	match nome:
		"dia":
			stream = Sintetizador.sequencia(Partituras.DIA, Partituras.BPM_DIA, "triangulo")
		"noite":
			stream = Sintetizador.sequencia(Partituras.NOITE, Partituras.BPM_NOITE, "seno")
		"batalha":
			stream = Sintetizador.sequencia(Partituras.BATALHA, Partituras.BPM_BATALHA, "quadrada")
	return Sintetizador.em_loop(stream) if stream != null else null


func _gerar_sfx(nome: String) -> AudioStreamWAV:
	## Timbres distintos pra criança reconhecer de ouvido o que aconteceu.
	var stream: AudioStreamWAV = null
	match nome:
		"quebrar":  ## ruído curto com queda de volume
			stream = Sintetizador.ruido(0.12, "queda")
		"colocar":  ## tom grave curto
			stream = Sintetizador.tom(150.0, 0.09, "triangulo", "queda")
		"craft":  ## dois tons subindo
			stream = Sintetizador.sequencia([[Partituras.DO5, 1.0], [Partituras.SOL5, 1.0]], 600.0)
		"captura":  ## arpejo
			stream = (
				Sintetizador
				. sequencia(
					[
						[Partituras.DO5, 1.0],
						[Partituras.MI5, 1.0],
						[Partituras.SOL5, 1.0],
						[Partituras.DO6, 2.0],
					],
					480.0,
					"triangulo"
				)
			)
		"vitoria":  ## fanfarra das Partituras, por cima da música
			stream = Sintetizador.sequencia(Partituras.VITORIA, Partituras.BPM_VITORIA, "triangulo")
		"missao":  ## acorde
			stream = Sintetizador.acorde(
				[Partituras.DO5, Partituras.MI5, Partituras.SOL5], 0.45, "seno", "queda"
			)
		"morte":  ## tom descendo
			stream = Sintetizador.varredura(220.0, 55.0, 0.6, "serra", "queda")
		"ui_clique":  ## clique curto
			stream = Sintetizador.tom(1200.0, 0.03, "quadrada", "queda")
	return stream


func _ao_mudar_periodo(nome: String) -> void:
	_musica_periodo = nome
	if not _em_batalha:
		tocar_musica(nome)
	_atualizar_ambiente(nome == "noite")


func _ao_comecar_batalha(_criatura: Creature) -> void:
	_em_batalha = true
	tocar_musica("batalha")


func _ao_terminar_batalha() -> void:
	_em_batalha = false
	tocar_musica(_musica_periodo)


func _atualizar_ambiente(eh_noite: bool) -> void:
	## Vento sempre; pássaros só de dia e grilos só de noite, com fade de 2 s.
	if _ambiente.is_empty():
		_criar_ambiente()
	_fade("passaros", DB_MUDO if eh_noite else DB_PASSAROS_GRILOS)
	_fade("grilos", DB_PASSAROS_GRILOS if eh_noite else DB_MUDO)


func _criar_ambiente() -> void:
	var dur := DURACAO_LOOP_AMBIENTE_SEG
	_ambiente["vento"] = _novo_player_ambiente(Sintetizador.vento(dur), DB_VENTO)
	_ambiente["passaros"] = _novo_player_ambiente(Sintetizador.passaros(dur), DB_MUDO)
	_ambiente["grilos"] = _novo_player_ambiente(Sintetizador.grilos(dur), DB_MUDO)
	var vento: AudioStreamPlayer = _ambiente["vento"]
	vento.play()


func _novo_player_ambiente(stream: AudioStreamWAV, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player


func _fade(nome: String, alvo_db: float) -> void:
	var player: AudioStreamPlayer = _ambiente[nome]
	if _fades.has(nome):
		var anterior: Tween = _fades[nome]
		if anterior.is_valid():
			anterior.kill()
	var vai_tocar := alvo_db > DB_MUDO
	if vai_tocar and not player.playing:
		player.volume_db = DB_MUDO
		player.play()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", alvo_db, FADE_AMBIENTE_SEG)
	if not vai_tocar:
		tween.tween_callback(player.stop)
	_fades[nome] = tween
