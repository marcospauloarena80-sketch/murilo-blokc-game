class_name ArenaDef
extends Resource
## Definição data-driven de uma Arena Elemental (F10). Ver docs/01-GDD.md §13
## e docs/07-DECISOES.md ADR-023.

@export var arena_id: String = ""
@export var elemento: String = ""
@export var guardiao_nome: String = ""
@export var equipe: Array[Dictionary] = []  ## [{"especie_id": String, "nivel": int}, ...]
@export var recompensa_receita: String = ""  ## "" = nenhuma receita exclusiva; desbloqueio real
## acontece via GameState.tem_insignia() checado em RecipeDef.requer_insignia — este campo aqui
## só documenta/valida o par arena↔receita (ver test_arena_registry.gd)
@export var requer_todas_insignias: bool = false  ## só o desafio final (Coração Dourado)


func construir_equipe() -> Array[CreatureInstance]:
	var resultado: Array[CreatureInstance] = []
	for membro: Dictionary in equipe:
		resultado.append(CreatureInstance.new(membro["especie_id"], membro["nivel"]))
	return resultado
