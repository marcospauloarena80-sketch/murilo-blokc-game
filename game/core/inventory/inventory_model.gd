class_name InventoryModel
extends RefCounted
## Inventário genérico de slots fixos — usado pra hotbar, mochila e (F6) baús.
## Puro, sem Node, 100% testável. Ver docs/02-ARQUITETURA.md §4.4.

var tamanho: int
var _slots: Array


func _init(tamanho_inventario: int) -> void:
	tamanho = tamanho_inventario
	_slots = []
	_slots.resize(tamanho)
	for i in range(tamanho):
		_slots[i] = {}


func slot_vazio(indice: int) -> bool:
	return _slots[indice].is_empty()


func get_item_id(indice: int) -> String:
	return _slots[indice].get("item_id", "")


func get_quantidade(indice: int) -> int:
	return _slots[indice].get("quantidade", 0)


func contar(item_id: String) -> int:
	var total: int = 0
	for i in range(tamanho):
		if not _slots[i].is_empty() and _slots[i]["item_id"] == item_id:
			total += int(_slots[i]["quantidade"])
	return total


func adicionar(item_id: String, quantidade: int) -> int:
	## Retorna quanto NÃO coube (0 = tudo coube).
	var def := ItemRegistry.get_item(item_id)
	if def == null:
		return quantidade

	var restante: int = quantidade

	for i in range(tamanho):
		if restante <= 0:
			break
		if not _slots[i].is_empty() and _slots[i]["item_id"] == item_id:
			var espaco: int = def.stack_maximo - int(_slots[i]["quantidade"])
			if espaco > 0:
				var adicionado: int = min(espaco, restante)
				_slots[i]["quantidade"] = int(_slots[i]["quantidade"]) + adicionado
				restante -= adicionado

	for i in range(tamanho):
		if restante <= 0:
			break
		if _slots[i].is_empty():
			var adicionado: int = min(def.stack_maximo, restante)
			_slots[i] = {"item_id": item_id, "quantidade": adicionado}
			restante -= adicionado

	return restante


func remover(item_id: String, quantidade: int) -> bool:
	## Remove só se tiver o suficiente (tudo ou nada). Retorna se removeu.
	if contar(item_id) < quantidade:
		return false

	var restante: int = quantidade
	for i in range(tamanho):
		if restante <= 0:
			break
		if not _slots[i].is_empty() and _slots[i]["item_id"] == item_id:
			var removido: int = min(int(_slots[i]["quantidade"]), restante)
			_slots[i]["quantidade"] = int(_slots[i]["quantidade"]) - removido
			restante -= removido
			if int(_slots[i]["quantidade"]) <= 0:
				_slots[i] = {}
	return true


func mover(origem: int, destino: int) -> void:
	if origem == destino:
		return
	if _slots[destino].is_empty():
		_slots[destino] = _slots[origem]
		_slots[origem] = {}
		return

	if _slots[origem].is_empty():
		return

	if _slots[destino]["item_id"] == _slots[origem]["item_id"]:
		var def := ItemRegistry.get_item(_slots[destino]["item_id"])
		var espaco: int = def.stack_maximo - int(_slots[destino]["quantidade"])
		var mover_qtd: int = min(espaco, int(_slots[origem]["quantidade"]))
		_slots[destino]["quantidade"] = int(_slots[destino]["quantidade"]) + mover_qtd
		_slots[origem]["quantidade"] = int(_slots[origem]["quantidade"]) - mover_qtd
		if int(_slots[origem]["quantidade"]) <= 0:
			_slots[origem] = {}
	else:
		var temporario: Dictionary = _slots[origem]
		_slots[origem] = _slots[destino]
		_slots[destino] = temporario
