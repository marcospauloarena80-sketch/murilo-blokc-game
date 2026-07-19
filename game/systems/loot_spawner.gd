class_name LootSpawner
extends Node3D
## Escuta EventBus.block_broken e spawna o item-drop correspondente
## (BlockDef.drop_id). Ver docs/02-ARQUITETURA.md §4.4.

const ItemDropScene := preload("res://entities/props/item_drop.tscn")


func _ready() -> void:
	EventBus.block_broken.connect(_ao_quebrar_bloco)


func _ao_quebrar_bloco(pos: Vector3i, block_id: int) -> void:
	var bloco := BlockRegistry.get_block(block_id)
	if bloco == null:
		return
	if bloco.tipo_especial == "bau":
		_dropar_conteudo_do_bau(pos)
	if bloco.drop_id == "":
		return
	var drop: ItemDrop = ItemDropScene.instantiate()
	drop.item_id = bloco.drop_id
	drop.quantidade = 1
	drop.position = Vector3(pos) + Vector3(0.5, 0.5, 0.5)
	add_child(drop)


func _dropar_conteudo_do_bau(pos: Vector3i) -> void:
	var chave := GameState.chave_posicao(pos)
	if not GameState.baus.has(chave):
		return
	var inventario: InventoryModel = GameState.baus[chave]
	for i in range(inventario.tamanho):
		var item_id := inventario.get_item_id(i)
		if item_id == "":
			continue
		var drop: ItemDrop = ItemDropScene.instantiate()
		drop.item_id = item_id
		drop.quantidade = inventario.get_quantidade(i)
		drop.position = Vector3(pos) + Vector3(0.5, 0.5, 0.5)
		add_child(drop)
	GameState.baus.erase(chave)
