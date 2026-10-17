class_name Partituras
extends RefCounted
## Melodias das músicas geradas (Ciclo 5, ADR-028), todas na pentatônica de dó
## (dó, ré, mi, sol, lá): qualquer sequência soa agradável e sem dissonância,
## bom pra criança ouvir em loop. Cada nota é [frequência em Hz, batidas];
## frequência 0 é pausa. Compasso 4/4 (4 batidas por compasso). O Sintetizador
## transforma uma partitura em AudioStreamWAV com `sequencia(notas, bpm)`.

const SOL3: float = 196.00
const LA3: float = 220.00
const DO4: float = 261.63
const RE4: float = 293.66
const MI4: float = 329.63
const SOL4: float = 392.00
const LA4: float = 440.00
const DO5: float = 523.25
const RE5: float = 587.33
const MI5: float = 659.25
const SOL5: float = 783.99
const LA5: float = 880.00
const DO6: float = 1046.50
const RE6: float = 1174.66
const PAUSA: float = 0.0

const ESCALA: Array = [SOL3, LA3, DO4, RE4, MI4, SOL4, LA4, DO5, RE5, MI5, SOL5, LA5, DO6, RE6]

const BPM_DIA: float = 100.0
const BPM_NOITE: float = 70.0
const BPM_BATALHA: float = 140.0
const BPM_VITORIA: float = 120.0

## Dia: 16 compassos, alegre e saltitante.
const DIA: Array = [
	[DO5, 1.0],
	[RE5, 1.0],
	[MI5, 1.0],
	[SOL5, 1.0],
	[MI5, 1.5],
	[RE5, 0.5],
	[DO5, 2.0],
	[LA4, 1.0],
	[DO5, 1.0],
	[RE5, 1.0],
	[MI5, 1.0],
	[RE5, 2.0],
	[DO5, 2.0],
	[MI5, 1.0],
	[SOL5, 1.0],
	[LA5, 1.0],
	[SOL5, 1.0],
	[MI5, 1.5],
	[RE5, 0.5],
	[MI5, 2.0],
	[SOL5, 1.0],
	[MI5, 1.0],
	[RE5, 1.0],
	[DO5, 1.0],
	[RE5, 3.0],
	[PAUSA, 1.0],
	[DO5, 1.0],
	[RE5, 1.0],
	[MI5, 1.0],
	[SOL5, 1.0],
	[LA5, 1.5],
	[SOL5, 0.5],
	[MI5, 2.0],
	[RE5, 1.0],
	[MI5, 1.0],
	[RE5, 1.0],
	[DO5, 1.0],
	[LA4, 2.0],
	[DO5, 2.0],
	[SOL4, 1.0],
	[LA4, 1.0],
	[DO5, 1.0],
	[RE5, 1.0],
	[MI5, 1.5],
	[RE5, 0.5],
	[DO5, 2.0],
	[RE5, 1.0],
	[DO5, 1.0],
	[LA4, 1.0],
	[SOL4, 1.0],
	[DO5, 3.0],
	[PAUSA, 1.0],
]

## Noite: 16 compassos, grave, lento e espaçado.
const NOITE: Array = [
	[LA3, 2.0],
	[DO4, 2.0],
	[MI4, 3.0],
	[RE4, 1.0],
	[DO4, 2.0],
	[LA3, 2.0],
	[SOL3, 4.0],
	[LA3, 2.0],
	[DO4, 1.0],
	[RE4, 1.0],
	[MI4, 2.0],
	[SOL4, 2.0],
	[MI4, 2.0],
	[RE4, 2.0],
	[DO4, 4.0],
	[PAUSA, 1.0],
	[MI4, 1.0],
	[SOL4, 2.0],
	[LA4, 2.0],
	[SOL4, 2.0],
	[MI4, 2.0],
	[RE4, 1.0],
	[DO4, 1.0],
	[RE4, 4.0],
	[DO4, 2.0],
	[LA3, 2.0],
	[SOL3, 2.0],
	[LA3, 2.0],
	[DO4, 2.0],
	[LA3, 2.0],
	[LA3, 3.0],
	[PAUSA, 1.0],
]

## Batalha: 8 compassos, rápido, em colcheias.
const BATALHA: Array = [
	[MI4, 0.5],
	[MI4, 0.5],
	[SOL4, 0.5],
	[MI4, 0.5],
	[LA4, 0.5],
	[SOL4, 0.5],
	[MI4, 0.5],
	[RE4, 0.5],
	[MI4, 0.5],
	[MI4, 0.5],
	[SOL4, 0.5],
	[LA4, 0.5],
	[DO5, 1.0],
	[LA4, 1.0],
	[RE5, 0.5],
	[DO5, 0.5],
	[LA4, 0.5],
	[SOL4, 0.5],
	[MI4, 0.5],
	[SOL4, 0.5],
	[LA4, 0.5],
	[DO5, 0.5],
	[RE5, 1.0],
	[MI5, 1.0],
	[RE5, 0.5],
	[DO5, 0.5],
	[LA4, 1.0],
	[MI4, 0.5],
	[MI4, 0.5],
	[SOL4, 0.5],
	[MI4, 0.5],
	[LA4, 0.5],
	[SOL4, 0.5],
	[MI4, 0.5],
	[RE4, 0.5],
	[DO5, 0.5],
	[DO5, 0.5],
	[RE5, 0.5],
	[MI5, 0.5],
	[SOL5, 1.0],
	[MI5, 1.0],
	[RE5, 0.5],
	[MI5, 0.5],
	[RE5, 0.5],
	[DO5, 0.5],
	[LA4, 0.5],
	[DO5, 0.5],
	[RE5, 0.5],
	[MI5, 0.5],
	[SOL5, 1.0],
	[MI5, 1.0],
	[RE5, 1.0],
	[DO5, 1.0],
]

## Vitória: 2 compassos, fanfarra curta que toca por cima da música.
const VITORIA: Array = [
	[DO5, 0.5],
	[MI5, 0.5],
	[SOL5, 0.5],
	[DO6, 1.0],
	[PAUSA, 0.5],
	[LA5, 0.5],
	[DO6, 0.5],
	[RE6, 1.0],
	[DO6, 3.0],
]


static func batidas(partitura: Array) -> float:
	var total: float = 0.0
	for nota: Array in partitura:
		total += float(nota[1])
	return total


static func duracao_seg(partitura: Array, bpm: float) -> float:
	return batidas(partitura) * 60.0 / bpm
