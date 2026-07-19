class_name TorchLightManager
extends Node3D
## Escuta EventBus.block_placed/block_broken e spawna/remove um OmniLight3D
## pra blocos com BlockDef.emite_luz (tocha, F6). Ver docs/02-ARQUITETURA.md §4.4.
## Bloqueio de spawn de criaturas perto de tochas fica pra F7 (sem Cubelins ainda).

const RAIO_LUZ: float = 6.0
const ENERGIA_LUZ: float = 1.2
const COR_LUZ: Color = Color(1.0, 0.75, 0.4)

var _luzes: Dictionary = {}  ## "x,y,z" -> OmniLight3D


func _ready() -> void:
	EventBus.block_placed.connect(_ao_colocar_bloco)
	EventBus.block_broken.connect(_ao_quebrar_bloco)


func _ao_colocar_bloco(pos: Vector3i, block_id: int) -> void:
	var bloco := BlockRegistry.get_block(block_id)
	if bloco == null or not bloco.emite_luz:
		return
	var chave := GameState.chave_posicao(pos)
	if _luzes.has(chave):
		return
	var luz := OmniLight3D.new()
	luz.light_color = COR_LUZ
	luz.omni_range = RAIO_LUZ
	luz.light_energy = ENERGIA_LUZ
	luz.position = Vector3(pos) + Vector3(0.5, 0.5, 0.5)
	add_child(luz)
	_luzes[chave] = luz


func _ao_quebrar_bloco(pos: Vector3i, _id_anterior: int) -> void:
	var chave := GameState.chave_posicao(pos)
	if not _luzes.has(chave):
		return
	_luzes[chave].queue_free()
	_luzes.erase(chave)
