class_name BattleService
extends RefCounted
## Batalha por turnos 1x1 (F8). Lógica pura, sem Node — testável direto.
## Ver docs/01-GDD.md §11 e docs/07-DECISOES.md ADR-007 (turnos, não tempo
## real) e ADR-021. Aleatoriedade (variação de dano, fuga) sempre injetada
## por parâmetro — nunca chamada internamente — pra ficar 100% testável.

enum Resultado { EM_ANDAMENTO, VITORIA, DERROTA, FUGIU, CAPTUROU }

const VANTAGEM: Dictionary = {
	"brasa": "mato",
	"mato": "gota",
	"gota": "brasa",
	"pedra": "faisca",
	"faisca": "vento",
	"vento": "pedra",
}

var equipe: Array[CreatureInstance]
var indice_ativo: int
var selvagem: CreatureInstance
var resultado: Resultado = Resultado.EM_ANDAMENTO


func _init(equipe_jogador: Array[CreatureInstance], oponente: CreatureInstance) -> void:
	equipe = equipe_jogador
	selvagem = oponente
	indice_ativo = _primeiro_index_capaz(equipe)


static func _primeiro_index_capaz(lista: Array[CreatureInstance]) -> int:
	for i in range(lista.size()):
		if not lista[i].esta_desmaiado():
			return i
	return -1


func jogador_ativo() -> CreatureInstance:
	if indice_ativo < 0:
		return null
	return equipe[indice_ativo]


func trocar_ativo(indice: int) -> bool:
	if resultado != Resultado.EM_ANDAMENTO:
		return false
	if indice < 0 or indice >= equipe.size():
		return false
	if equipe[indice].esta_desmaiado():
		return false
	indice_ativo = indice
	return true


static func multiplicador_elemental(elemento_ataque: String, elemento_alvo: String) -> float:
	if VANTAGEM.get(elemento_ataque, "") == elemento_alvo:
		return 1.5
	if VANTAGEM.get(elemento_alvo, "") == elemento_ataque:
		return 0.75
	return 1.0


static func calcular_dano(
	atacante: CreatureInstance, alvo: CreatureInstance, ataque: AttackDef, variacao: float
) -> int:
	var multiplicador := multiplicador_elemental(ataque.elemento, alvo.especie_def().elemento)
	var razao: float = float(atacante.forca_efetiva()) / float(max(1, alvo.guarda_efetiva()))
	var dano: float = ataque.poder * razao * multiplicador * variacao
	return max(1, int(round(dano)))


func quem_age_primeiro() -> String:
	if jogador_ativo().agilidade_efetiva() >= selvagem.agilidade_efetiva():
		return "jogador"
	return "selvagem"


func jogador_ataca(ataque_id: String, variacao: float) -> int:
	if resultado != Resultado.EM_ANDAMENTO:
		return 0
	var atacante := jogador_ativo()
	if not atacante.ataques_conhecidos.has(ataque_id):
		return 0
	var ataque := AttackRegistry.get_ataque(ataque_id)
	var dano := calcular_dano(atacante, selvagem, ataque, variacao)
	selvagem.vida_atual = max(0, selvagem.vida_atual - dano)
	atacante.energia_atual = max(0, atacante.energia_atual - ataque.custo_energia)
	_atualizar_resultado()
	return dano


func selvagem_ataca(ataque_id: String, variacao: float) -> int:
	if resultado != Resultado.EM_ANDAMENTO:
		return 0
	if not selvagem.ataques_conhecidos.has(ataque_id):
		return 0
	var alvo := jogador_ativo()
	var ataque := AttackRegistry.get_ataque(ataque_id)
	var dano := calcular_dano(selvagem, alvo, ataque, variacao)
	alvo.vida_atual = max(0, alvo.vida_atual - dano)
	_atualizar_resultado()
	return dano


func chance_de_fuga() -> float:
	var agilidade_jogador := jogador_ativo().agilidade_efetiva()
	var agilidade_selvagem := selvagem.agilidade_efetiva()
	return clamp(0.5 + float(agilidade_jogador - agilidade_selvagem) * 0.05, 0.1, 0.95)


func tentar_fugir(sorteio: float) -> bool:
	if resultado != Resultado.EM_ANDAMENTO:
		return false
	if sorteio < chance_de_fuga():
		resultado = Resultado.FUGIU
		return true
	return false


func usar_pocao(alvo: CreatureInstance, cura: int) -> void:
	alvo.vida_atual = min(alvo.vida_maxima_efetiva(), alvo.vida_atual + cura)


func capturar() -> void:
	resultado = Resultado.CAPTUROU


static func calcular_recompensa_xp(derrotado: CreatureInstance) -> int:
	return derrotado.nivel * 15


func _atualizar_resultado() -> void:
	if selvagem.esta_desmaiado():
		resultado = Resultado.VITORIA
		jogador_ativo().ganhar_xp(calcular_recompensa_xp(selvagem))
		return
	if _primeiro_index_capaz(equipe) == -1:
		resultado = Resultado.DERROTA
