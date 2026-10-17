class_name ValidadorSave
extends RefCounted
## Validação semântica mínima do save (ADR-038). Pura: recebe o que o JSON
## devolveu e diz se o jogo consegue carregar. Cada regra vem do que
## `scenes/menu.gd::_ao_continuar` e os desserializadores realmente exigem:
## parâmetros tipados (Array/Dictionary/String) travariam com o tipo errado.
##
## Política de campos: só `seed` é obrigatório (todo save desde a F5 a tem e o
## mundo não existe sem ela). Os demais podem faltar, porque saves de versões
## anteriores não tinham todos (ex.: `treinadores_vencidos` veio no Ciclo 9) e o
## menu usa o valor padrão. Quando presentes, precisam ter o tipo que o
## carregamento espera. Nada é corrigido nem preenchido aqui: só se classifica.
## `schema_version` ausente conta como v1 (a versão em que o campo nasceu).

enum Resultado { VALIDO, VAZIO, ESTRUTURA_INVALIDA, VERSAO_FUTURA }

const CAMPO_OBRIGATORIO: String = "seed"
## Declarados `int` no GameState e lidos com `int(...)` no menu: semente do mundo,
## índice da hotbar, vida/fome/energia e contador de missão. O JSON devolve todo
## número como float, então "inteiro" aqui é "valor inteiro e finito dentro do
## intervalo de int64", não o tipo do Variant.
const INTEIROS: Array[String] = [
	"seed",
	"vida_atual",
	"fome_atual",
	"energia_atual",
	"hotbar_selecionado",
	"progresso_quest_atual",
]
## Tempos em segundos, `float` no GameState: aceitam fração.
const NUMEROS: Array[String] = ["tempo_de_jogo_seg", "ciclo_dia_noite_seg"]
const LIMITE_INT64: float = 9.2e18
const TEXTOS: Array[String] = ["quest_atual_id"]
const OBJETOS: Array[String] = ["aparencia", "delta_blocos", "baus", "treinadores_vencidos"]
const LISTAS_DE_OBJETOS: Array[String] = [
	"hotbar", "mochila", "equipe_cubelins", "deposito_cubelins"
]
const LISTAS_DE_TEXTOS: Array[String] = [
	"quests_concluidas", "insignias_conquistadas", "especies_vistas", "especies_capturadas"
]
const LISTAS_DE_NUMEROS: Array[String] = ["jogador_posicao", "ponto_respawn"]


static func avaliar(dados: Variant, versao_suportada: int) -> Resultado:
	if not (dados is Dictionary):
		return Resultado.ESTRUTURA_INVALIDA
	var save: Dictionary = dados
	if save.is_empty():
		return Resultado.VAZIO
	if save.has("schema_version"):
		if not _e_inteiro(save["schema_version"]):
			return Resultado.ESTRUTURA_INVALIDA
		var versao: int = int(save["schema_version"])
		if versao < 1:
			return Resultado.ESTRUTURA_INVALIDA
		if versao > versao_suportada:
			return Resultado.VERSAO_FUTURA  ## estrutura de versão futura não é julgada aqui
	if not save.has(CAMPO_OBRIGATORIO):
		return Resultado.ESTRUTURA_INVALIDA
	return Resultado.VALIDO if _tipos_conferem(save) else Resultado.ESTRUTURA_INVALIDA


static func _tipos_conferem(save: Dictionary) -> bool:
	for chave: String in INTEIROS:
		if save.has(chave) and not _e_inteiro(save[chave]):
			return false
	for chave: String in NUMEROS:
		if save.has(chave) and not _e_numero(save[chave]):
			return false
	for chave: String in TEXTOS:
		if save.has(chave) and not (save[chave] is String):
			return false
	for chave: String in OBJETOS:
		if save.has(chave) and not (save[chave] is Dictionary):
			return false
	for chave: String in LISTAS_DE_OBJETOS:
		if save.has(chave) and not _lista_de(save[chave], TYPE_DICTIONARY):
			return false
	for chave: String in LISTAS_DE_TEXTOS:
		if save.has(chave) and not _lista_de(save[chave], TYPE_STRING):
			return false
	for chave: String in LISTAS_DE_NUMEROS:
		if save.has(chave) and not _lista_de_numeros(save[chave]):
			return false
	return _baus_conferem(save.get("baus", {}))


## Cada baú é um inventário serializado (lista de slots-objeto).
static func _baus_conferem(baus: Variant) -> bool:
	if not (baus is Dictionary):
		return false
	for chave: Variant in baus as Dictionary:
		if not _lista_de((baus as Dictionary)[chave], TYPE_DICTIONARY):
			return false
	return true


static func _lista_de(valor: Variant, tipo: int) -> bool:
	if not (valor is Array):
		return false
	for item: Variant in valor as Array:
		if typeof(item) != tipo:
			return false
	return true


## Posição: o menu usa valores padrão se tiver menos de 3 números, então qualquer
## tamanho serve; os elementos presentes é que precisam ser números.
static func _lista_de_numeros(valor: Variant) -> bool:
	if not (valor is Array):
		return false
	for item: Variant in valor as Array:
		if not _e_numero(item):
			return false
	return true


static func _e_numero(valor: Variant) -> bool:
	if typeof(valor) == TYPE_INT:
		return true
	return typeof(valor) == TYPE_FLOAT and is_finite(valor)


## Número de valor inteiro (1.0 conta, 1.5 não), finito e que cabe num int64.
## Booleano, texto, null, lista e objeto nunca contam.
static func _e_inteiro(valor: Variant) -> bool:
	if typeof(valor) == TYPE_INT:
		return true
	if typeof(valor) != TYPE_FLOAT or not is_finite(valor):
		return false
	var numero: float = valor
	return absf(numero) < LIMITE_INT64 and numero == floorf(numero)
