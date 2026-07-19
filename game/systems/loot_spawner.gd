class_name LootSpawner
extends Node3D
## Escuta EventBus.block_broken e spawna o item-drop correspondente
## (BlockDef.drop_id). Ver docs/02-ARQUITETURA.md §4.4.

const ItemDropScene := preload("res://entities/props/item_drop.tscn")


func _ready() -> void:
	EventBus.block_broken.connect(_ao_quebrar_bloco)


func _ao_quebrar_bloco(pos: Vector3i, block_id: int) -> void:
	var bloco := BlockRegistry.get_block(block_id)
	if bloco == null or bloco.drop_id == "":
		return
	var drop: ItemDrop = ItemDropScene.instantiate()
	drop.item_id = bloco.drop_id
	drop.quantidade = 1
	drop.position = Vector3(pos) + Vector3(0.5, 0.5, 0.5)
	add_child(drop)
