extends Node3D
## Orquestra save/load/autosave da sessão (F5). Cada sistema fornece seu
## próprio snapshot; este script só monta o Dictionary final e delega ao
## SaveManager. Ver docs/02-ARQUITETURA.md §4.6 e ADR-006.

const INTERVALO_AUTOSAVE: float = 60.0

var _tempo_desde_autosave: float = 0.0

@onready var _chunk_manager: ChunkManager = $ChunkManager
@onready var _player: Player = $Player


func _ready() -> void:
	if GameState.veio_de_continuar:
		_chunk_manager.aplicar_delta(GameState.delta_blocos_carregado)


func _process(delta: float) -> void:
	if GameState.current_state != GameState.State.PLAYING:
		return
	GameState.tempo_de_jogo_seg += delta
	_tempo_desde_autosave += delta
	if _tempo_desde_autosave >= INTERVALO_AUTOSAVE:
		_tempo_desde_autosave = 0.0
		salvar_jogo()


func salvar_jogo() -> void:
	var dados: Dictionary = {
		"seed": GameState.seed_atual,
		"tempo_de_jogo_seg": GameState.tempo_de_jogo_seg,
		"vida_atual": GameState.vida_atual,
		"hotbar_selecionado": GameState.hotbar_selecionado,
		"aparencia": GameState.aparencia_atual.serializar(),
		"hotbar": GameState.inventario_hotbar.serializar(),
		"mochila": GameState.inventario_mochila.serializar(),
		"delta_blocos": _chunk_manager.exportar_delta(),
		"jogador_posicao": _vector3_para_array(_player.global_position),
	}
	SaveManager.salvar(dados)
	EventBus.game_saved.emit()


static func _vector3_para_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]
