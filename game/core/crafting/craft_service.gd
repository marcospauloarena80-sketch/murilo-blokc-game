class_name CraftService
extends RefCounted
## Verifica e executa receitas sobre um InventoryModel. Puro, testável.
## Ver docs/02-ARQUITETURA.md §4.5.
##
## As versões *_em aceitam um segundo inventário opcional (Ciclo 6): os
## ingredientes são somados nos dois, consumidos do principal primeiro e o
## resultado entra no principal (a sobra vai pro extra). O GameState usa
## mochila como principal e hotbar como extra.


func pode_craftar(
	inventario: InventoryModel,
	receita: RecipeDef,
	tem_bancada: bool,
	tem_fornalha: bool = false,
	receita_desbloqueada: bool = true
) -> bool:
	return pode_craftar_em(
		inventario, null, receita, tem_bancada, tem_fornalha, receita_desbloqueada
	)


func craftar(
	inventario: InventoryModel,
	receita: RecipeDef,
	tem_bancada: bool,
	tem_fornalha: bool = false,
	receita_desbloqueada: bool = true
) -> bool:
	return craftar_em(inventario, null, receita, tem_bancada, tem_fornalha, receita_desbloqueada)


func pode_craftar_em(
	principal: InventoryModel,
	extra: InventoryModel,
	receita: RecipeDef,
	tem_bancada: bool,
	tem_fornalha: bool = false,
	receita_desbloqueada: bool = true
) -> bool:
	if not receita_desbloqueada:
		return false
	if receita.exige_bancada and not tem_bancada:
		return false
	if receita.exige_fornalha and not tem_fornalha:
		return false
	for item_id: String in receita.ingredientes:
		var necessario: int = int(receita.ingredientes[item_id])
		if _contar_em(principal, extra, item_id) < necessario:
			return false
	return true


func craftar_em(
	principal: InventoryModel,
	extra: InventoryModel,
	receita: RecipeDef,
	tem_bancada: bool,
	tem_fornalha: bool = false,
	receita_desbloqueada: bool = true
) -> bool:
	if not pode_craftar_em(
		principal, extra, receita, tem_bancada, tem_fornalha, receita_desbloqueada
	):
		return false
	for item_id: String in receita.ingredientes:
		var necessario: int = int(receita.ingredientes[item_id])
		var do_principal: int = mini(necessario, principal.contar(item_id))
		if do_principal > 0:
			principal.remover(item_id, do_principal)
		if necessario > do_principal:
			extra.remover(item_id, necessario - do_principal)
	var sobra: int = principal.adicionar(receita.resultado_id, receita.resultado_quantidade)
	if sobra > 0 and extra != null:
		extra.adicionar(receita.resultado_id, sobra)
	return true


static func _contar_em(principal: InventoryModel, extra: InventoryModel, item_id: String) -> int:
	var total: int = principal.contar(item_id)
	if extra != null:
		total += extra.contar(item_id)
	return total
