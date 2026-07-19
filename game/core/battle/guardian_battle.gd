class_name GuardianBattle
extends RefCounted
## Sequencia batalhas 1x1 (`BattleService`) contra a equipe de um Guardião de
## Arena (F10). Não altera `BattleService`/`CreatureInstance`/`CaptureService`
## — só orquestra por cima: ao vencer o adversário atual, troca pro próximo
## membro do Guardião mantendo a MESMA equipe do jogador (vida/XP acumulados
## continuam, cada `CreatureInstance` é referência, não cópia).
## Ver docs/01-GDD.md §13 e docs/07-DECISOES.md ADR-023.

var equipe_jogador: Array[CreatureInstance]
var equipe_guardiao: Array[CreatureInstance]
var indice_guardiao: int = 0
var batalha_atual: BattleService


func _init(equipe: Array[CreatureInstance], guardiao: Array[CreatureInstance]) -> void:
	equipe_jogador = equipe
	equipe_guardiao = guardiao
	batalha_atual = BattleService.new(equipe_jogador, equipe_guardiao[0])


func tem_proximo_adversario() -> bool:
	return indice_guardiao + 1 < equipe_guardiao.size()


func avancar_para_proximo() -> void:
	indice_guardiao += 1
	batalha_atual = BattleService.new(equipe_jogador, equipe_guardiao[indice_guardiao])


func guardiao_totalmente_derrotado() -> bool:
	return (
		batalha_atual.resultado == BattleService.Resultado.VITORIA and not tem_proximo_adversario()
	)
