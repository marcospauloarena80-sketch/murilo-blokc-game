class_name SubstituicaoQuest
extends RefCounted
## Regra de quando aceitar uma missão nova descarta progresso da atual e por isso
## pede confirmação (ADR-034). Usa só dados da QuestDef e o progresso corrente:
## missão repetível pode ser trocada direto (é o que o jogo já fazia, a cadeia
## principal termina numa repetível), e sem progresso não há o que perder.


static func exige_confirmacao(atual: QuestDef, progresso: int) -> bool:
	return atual != null and not atual.repetivel and progresso > 0


static func texto_confirmacao(atual: QuestDef, progresso: int, nova: QuestDef) -> String:
	var nome_nova: String = nova.nome if nova != null else "a nova missão"
	var modelo := 'Você já está na missão "%s" (%d/%d).\n'
	modelo += 'Aceitar "%s" vai substituí-la e o progresso será perdido.\nSubstituir?'
	return modelo % [atual.nome, progresso, atual.quantidade_alvo, nome_nova]
