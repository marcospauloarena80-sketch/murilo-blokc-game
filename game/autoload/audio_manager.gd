extends Node
## Toca música/SFX por nome. Não conhece gameplay. Ver docs/02-ARQUITETURA.md
## §4.12 e docs/07-DECISOES.md ADR-024: SFX são tons curtos sintetizados em
## código (AudioStreamGenerator) — sem baixar asset externo (regra de
## segurança: download exige permissão explícita do usuário no chat, não é
## decisão de implementação). tocar_musica() já tem a assinatura certa (por
## bioma/contexto) mas fica em silêncio até o dono trazer arquivos .ogg reais
## em assets/audio/music/ — zero erro, zero mudança de código no futuro.

const MIX_RATE: float = 22050.0

## nome do SFX -> [frequência em Hz, duração em segundos]
const SFX: Dictionary = {
	"quebrar": [180.0, 0.08],
	"colocar": [260.0, 0.06],
	"craft": [520.0, 0.12],
	"captura": [700.0, 0.25],
	"vitoria": [880.0, 0.3],
	"missao": [600.0, 0.2],
	"morte": [110.0, 0.4],
	"ui_clique": [340.0, 0.05],
}

var _music_player: AudioStreamPlayer


func _ready() -> void:
	_configurar_buses()
	EventBus.block_broken.connect(func(_pos: Vector3i, _id: int) -> void: tocar_sfx("quebrar"))
	EventBus.block_placed.connect(func(_pos: Vector3i, _id: int) -> void: tocar_sfx("colocar"))
	EventBus.recipe_crafted.connect(func(_id: String) -> void: tocar_sfx("craft"))
	EventBus.creature_captured.connect(func(_id: String) -> void: tocar_sfx("captura"))
	EventBus.creature_defeated.connect(func(_id: String) -> void: tocar_sfx("vitoria"))
	EventBus.quest_completed.connect(func(_id: String) -> void: tocar_sfx("missao"))
	EventBus.player_died.connect(tocar_sfx.bind("morte"))
	EventBus.day_started.connect(tocar_musica.bind("dia"))
	EventBus.night_started.connect(tocar_musica.bind("noite"))


func _configurar_buses() -> void:
	## Master já existe por padrão (índice 0). Música/SFX criados uma vez só.
	for nome_bus: String in ["Música", "SFX"]:
		if AudioServer.get_bus_index(nome_bus) == -1:
			AudioServer.add_bus()
			var indice := AudioServer.bus_count - 1
			AudioServer.set_bus_name(indice, nome_bus)
			AudioServer.set_bus_send(indice, "Master")


func tocar_sfx(nome: String) -> void:
	if not SFX.has(nome):
		return
	var config: Array = SFX[nome]
	_tocar_tom(config[0], config[1])


func _tocar_tom(frequencia: float, duracao: float) -> void:
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	var gerador := AudioStreamGenerator.new()
	gerador.mix_rate = MIX_RATE
	gerador.buffer_length = duracao + 0.1
	player.stream = gerador
	add_child(player)
	player.play()

	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var total_frames := int(MIX_RATE * duracao)
	for i in range(total_frames):
		var t: float = float(i) / MIX_RATE
		var amplitude: float = 0.25 * (1.0 - t / duracao)  # fade-out simples
		var valor: float = sin(TAU * frequencia * t) * amplitude
		playback.push_frame(Vector2(valor, valor))

	## Timer, não o sinal `finished` — sob driver de áudio nulo/dummy (ex.:
	## `--headless`) o playback nunca "termina" de verdade, e o player
	## vazaria pra sempre como filho deste autoload.
	get_tree().create_timer(duracao + 0.15).timeout.connect(player.queue_free)


func tocar_musica(nome: String) -> void:
	var caminho := "res://assets/audio/music/%s.ogg" % nome
	if not ResourceLoader.exists(caminho):
		return  # dono ainda não trouxe os arquivos CC0 (ADR-024) — silêncio, sem erro
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.bus = "Música"
		add_child(_music_player)
	var stream: AudioStream = load(caminho)
	_music_player.stream = stream
	_music_player.play()
