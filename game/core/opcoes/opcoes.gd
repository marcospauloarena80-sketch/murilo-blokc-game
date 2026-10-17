class_name Opcoes
extends RefCounted
## Opções do jogador: sensibilidade do mouse e volumes dos buses "Música" e
## "SFX" em dB. Estático, não é autoload (máximo 5): o menu carrega e aplica
## na entrada, a OptionsScreen grava a cada mudança. Persistência em
## user://opcoes.cfg via ConfigFile; arquivo faltando ou chave ausente usa o
## padrão. Ver docs/superpowers/plans/2026-10-17-ciclos-5-a-9.md Frente 6D.

const CAMINHO_PADRAO: String = "user://opcoes.cfg"
const SECAO: String = "opcoes"
const SENSIBILIDADE_PADRAO: float = 0.003
const VOLUME_PADRAO_DB: float = 0.0

static var sensibilidade: float = SENSIBILIDADE_PADRAO
static var volume_musica_db: float = VOLUME_PADRAO_DB
static var volume_sfx_db: float = VOLUME_PADRAO_DB


static func carregar(caminho: String = CAMINHO_PADRAO) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(caminho) != OK:
		## Primeira vez (sem arquivo) ou arquivo quebrado: tudo volta ao padrão.
		cfg = ConfigFile.new()
	sensibilidade = float(cfg.get_value(SECAO, "sensibilidade", SENSIBILIDADE_PADRAO))
	volume_musica_db = float(cfg.get_value(SECAO, "volume_musica_db", VOLUME_PADRAO_DB))
	volume_sfx_db = float(cfg.get_value(SECAO, "volume_sfx_db", VOLUME_PADRAO_DB))


static func salvar(caminho: String = CAMINHO_PADRAO) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECAO, "sensibilidade", sensibilidade)
	cfg.set_value(SECAO, "volume_musica_db", volume_musica_db)
	cfg.set_value(SECAO, "volume_sfx_db", volume_sfx_db)
	cfg.save(caminho)


static func aplicar() -> void:
	_definir_volume_do_bus("Música", volume_musica_db)
	_definir_volume_do_bus("SFX", volume_sfx_db)


static func _definir_volume_do_bus(nome_bus: String, db: float) -> void:
	## Os buses são criados pelo AudioManager no _ready dele; sem bus, nada a ajustar.
	var indice := AudioServer.get_bus_index(nome_bus)
	if indice != -1:
		AudioServer.set_bus_volume_db(indice, db)
