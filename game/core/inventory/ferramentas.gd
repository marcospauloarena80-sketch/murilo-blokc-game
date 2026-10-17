class_name Ferramentas
extends RefCounted
## Regras puras de ferramenta x bloco (Ciclo 8, 8E): tier mínimo para quebrar e
## multiplicador de velocidade só com a ferramenta certa.


static func pode_quebrar(bloco: BlockDef, ferramenta: ItemDef) -> bool:
	## Bloco sem tier mínimo quebra na mão. Com tier mínimo, a ferramenta precisa
	## ser do tipo ideal do bloco e ter tier suficiente.
	if bloco == null or bloco.tier_minimo <= 0:
		return true
	if ferramenta == null or not ferramenta.eh_ferramenta:
		return false
	if ferramenta.tipo_ferramenta != bloco.ferramenta_ideal:
		return false
	return ferramenta.tier >= bloco.tier_minimo


static func multiplicador(bloco: BlockDef, ferramenta: ItemDef) -> float:
	## Ferramenta errada para um bloco que tem ferramenta ideal vale 1. Bloco sem
	## ferramenta ideal (terra, areia...) aceita qualquer ferramenta.
	if ferramenta == null or not ferramenta.eh_ferramenta:
		return 1.0
	if (
		bloco != null
		and bloco.ferramenta_ideal != ""
		and ferramenta.tipo_ferramenta != bloco.ferramenta_ideal
	):
		return 1.0
	return ferramenta.multiplicador_velocidade


static func aviso_tier(bloco: BlockDef) -> String:
	return "Precisa de %s melhor" % (bloco.ferramenta_ideal if bloco != null else "ferramenta")
