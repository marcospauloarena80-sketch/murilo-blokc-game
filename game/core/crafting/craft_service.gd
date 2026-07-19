class_name CraftService
extends RefCounted
## Verifica e executa receitas sobre um InventoryModel. Puro, testável.
## Ver docs/02-ARQUITETURA.md §4.5.


func pode_craftar(
	inventario: InventoryModel,
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
		if inventario.contar(item_id) < necessario:
			return false
	return true


func craftar(
	inventario: InventoryModel,
	receita: RecipeDef,
	tem_bancada: bool,
	tem_fornalha: bool = false,
	receita_desbloqueada: bool = true
) -> bool:
	if not pode_craftar(inventario, receita, tem_bancada, tem_fornalha, receita_desbloqueada):
		return false
	for item_id: String in receita.ingredientes:
		inventario.remover(item_id, int(receita.ingredientes[item_id]))
	inventario.adicionar(receita.resultado_id, receita.resultado_quantidade)
	return true
