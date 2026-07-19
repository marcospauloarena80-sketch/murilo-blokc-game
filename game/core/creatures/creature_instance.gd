class_name CreatureInstance
extends RefCounted
## Um Cubelin capturado/possuído: dados mutáveis (nível, XP, vida/energia
## atuais, ataques conhecidos) — distinto de CreatureDef, que é o template
## imutável da espécie. Ver docs/01-GDD.md §9 e docs/07-DECISOES.md ADR-021.

const FATOR_CRESCIMENTO: float = 0.1
const NIVEL_MAXIMO: int = 30  ## docs/01-GDD.md §9

var especie_id: String
var nivel: int
var xp: int = 0
var vida_atual: int
var energia_atual: int
var ataques_conhecidos: Array[String] = []


func _init(especie: String, nivel_inicial: int = 1) -> void:
	especie_id = especie
	nivel = nivel_inicial
	vida_atual = vida_maxima_efetiva()
	energia_atual = energia_maxima_efetiva()
	_atualizar_ataques_conhecidos()


func especie_def() -> CreatureDef:
	return CreatureRegistry.get_creature(especie_id)


func _stat_no_nivel(base: int) -> int:
	return base + int(floor(base * FATOR_CRESCIMENTO * (nivel - 1)))


func vida_maxima_efetiva() -> int:
	return _stat_no_nivel(especie_def().vida_maxima)


func energia_maxima_efetiva() -> int:
	return _stat_no_nivel(especie_def().energia_maxima)


func forca_efetiva() -> int:
	return _stat_no_nivel(especie_def().forca)


func guarda_efetiva() -> int:
	return _stat_no_nivel(especie_def().guarda)


func agilidade_efetiva() -> int:
	return _stat_no_nivel(especie_def().agilidade)


func esta_desmaiado() -> bool:
	return vida_atual <= 0


func xp_para_proximo_nivel() -> int:
	return int(round(20.0 * pow(nivel, 1.5)))


func ganhar_xp(quantidade: int) -> void:
	if nivel >= NIVEL_MAXIMO:
		return
	xp += quantidade
	while nivel < NIVEL_MAXIMO and xp >= xp_para_proximo_nivel():
		xp -= xp_para_proximo_nivel()
		_subir_de_nivel()


func _subir_de_nivel() -> void:
	nivel += 1
	vida_atual = vida_maxima_efetiva()
	energia_atual = energia_maxima_efetiva()
	_atualizar_ataques_conhecidos()
	var nivel_evolucao: int = especie_def().nivel_evolucao
	if nivel_evolucao > 0 and nivel >= nivel_evolucao:
		_evoluir()


func _evoluir() -> void:
	var proxima_especie: String = especie_def().especie_evolucao
	if proxima_especie == "" or CreatureRegistry.get_creature(proxima_especie) == null:
		return
	especie_id = proxima_especie
	vida_atual = vida_maxima_efetiva()
	energia_atual = energia_maxima_efetiva()
	_atualizar_ataques_conhecidos()


func _atualizar_ataques_conhecidos() -> void:
	ataques_conhecidos.clear()
	var aprendizado: Dictionary = especie_def().aprendizado_ataques
	for nivel_aprendido: int in aprendizado:
		if nivel_aprendido <= nivel:
			ataques_conhecidos.append(aprendizado[nivel_aprendido])


func serializar() -> Dictionary:
	return {
		"especie_id": especie_id,
		"nivel": nivel,
		"xp": xp,
		"vida_atual": vida_atual,
		"energia_atual": energia_atual,
	}


static func carregar_serializado(dados: Dictionary) -> CreatureInstance:
	var instancia := CreatureInstance.new(
		String(dados.get("especie_id", "")), int(dados.get("nivel", 1))
	)
	instancia.xp = int(dados.get("xp", 0))
	instancia.vida_atual = int(dados.get("vida_atual", instancia.vida_atual))
	instancia.energia_atual = int(dados.get("energia_atual", instancia.energia_atual))
	return instancia
