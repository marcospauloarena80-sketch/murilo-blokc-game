class_name Poderes
extends RefCounted
## Poderes temporários do jogador no toque (voar e acelerar), pagos por uma
## mesma barra de carga que esvazia usando e recarrega descansando. Puro e
## testável: o Player só pergunta `voando`, `turbo` e `subindo` e chama
## `atualizar(delta)` a cada quadro. Só aparece no toque (tablet e celular).

const CARGA_MAXIMA: float = 1.0
const CARGA_MINIMA_PARA_ATIVAR: float = 0.25  ## depois de zerar, só liga de novo acima disso
const CONSUMO_VOO_POR_SEG: float = 0.10  ## ~10 s de voo
const CONSUMO_TURBO_POR_SEG: float = 0.14  ## ~7 s de turbo
const RECARGA_POR_SEG: float = 0.12
const JANELA_DUPLO_TOQUE_SEG: float = 0.35
const MULTIPLICADOR_TURBO: float = 1.8
const VELOCIDADE_SUBIDA: float = 4.5

var carga: float = CARGA_MAXIMA
var voando: bool = false
var turbo: bool = false
var subindo: bool = false  ## seta pra cima segurada
var bloqueado: bool = false  ## carga zerou: espera recarregar até o mínimo

var _ultimo_toque_cima_seg: float = -100.0


func tocar_cima(agora_seg: float) -> String:
	## Devolve "pulo" no primeiro toque e "voo" no segundo, se ainda der.
	subindo = true
	if voando:
		return "subir"
	var duplo := agora_seg - _ultimo_toque_cima_seg <= JANELA_DUPLO_TOQUE_SEG
	_ultimo_toque_cima_seg = agora_seg
	if duplo and _pode_ativar():
		voando = true
		return "voo"
	return "pulo"


func soltar_cima() -> void:
	subindo = false


func tocar_baixo() -> String:
	## Voando: pousa (cai no cenário). No chão devolve "agachar".
	if voando:
		voando = false
		return "cair"
	return "agachar"


func alternar_turbo() -> void:
	if turbo:
		turbo = false
	elif _pode_ativar():
		turbo = true


func atualizar(delta: float) -> void:
	var gasto: float = 0.0
	if voando:
		gasto += CONSUMO_VOO_POR_SEG
	if turbo:
		gasto += CONSUMO_TURBO_POR_SEG
	if gasto > 0.0:
		carga = maxf(0.0, carga - gasto * delta)
		if carga <= 0.0:
			voando = false
			turbo = false
			bloqueado = true
	else:
		carga = minf(CARGA_MAXIMA, carga + RECARGA_POR_SEG * delta)
		if bloqueado and carga >= CARGA_MINIMA_PARA_ATIVAR:
			bloqueado = false


func fracao() -> float:
	return carga / CARGA_MAXIMA


func ativo() -> bool:
	return voando or turbo


func _pode_ativar() -> bool:
	return not bloqueado and carga >= CARGA_MINIMA_PARA_ATIVAR
