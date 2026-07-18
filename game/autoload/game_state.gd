extends Node
## Máquina de estados global do jogo. Não conhece UI, não conhece nós de cena.
## Ver docs/02-ARQUITETURA.md §3.

enum State { BOOT, MENU, CHARACTER_CREATION, PLAYING, PAUSED, BATTLE }

var current_state: State = State.BOOT
var seed_atual: int = 0
var tempo_de_jogo_seg: float = 0.0
var aparencia_atual: CharacterAppearance = CharacterAppearance.new()


func mudar_estado(novo_estado: State) -> void:
	current_state = novo_estado
