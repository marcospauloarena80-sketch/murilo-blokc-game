extends Node
## Máquina de estados global do jogo. Não conhece UI, não conhece nós de cena.
## Ver docs/02-ARQUITETURA.md §3.

enum State { BOOT, MENU, CHARACTER_CREATION, PLAYING, PAUSED, BATTLE }

var current_state: State = State.BOOT
var seed_atual: int = 0
var tempo_de_jogo_seg: float = 0.0
var aparencia_atual: CharacterAppearance = CharacterAppearance.new()
var inventario_hotbar: InventoryModel = InventoryModel.new(8)
var inventario_mochila: InventoryModel = InventoryModel.new(24)
var hotbar_selecionado: int = 0
var vida_atual: int = 20
var vida_maxima: int = 20

## Preenchidos pelo menu antes de trocar pra scenes/main.tscn (F5).
var veio_de_continuar: bool = false
var delta_blocos_carregado: Dictionary = {}
var posicao_salva: Vector3 = Vector3(64, 45, 64)


func mudar_estado(novo_estado: State) -> void:
	current_state = novo_estado


func reiniciar_para_novo_jogo() -> void:
	seed_atual = randi()
	tempo_de_jogo_seg = 0.0
	aparencia_atual = CharacterAppearance.new()
	inventario_hotbar = InventoryModel.new(8)
	inventario_mochila = InventoryModel.new(24)
	hotbar_selecionado = 0
	vida_atual = vida_maxima
	veio_de_continuar = false
	delta_blocos_carregado = {}


func adicionar_item(item_id: String, quantidade: int) -> int:
	## Coleta vai pra mochila primeiro (é onde o craft busca ingredientes);
	## hotbar só recebe por transferência manual do jogador na tela de inventário.
	var sobra: int = inventario_mochila.adicionar(item_id, quantidade)
	if sobra > 0:
		sobra = inventario_hotbar.adicionar(item_id, sobra)
	return sobra


func mover_para_hotbar(indice_mochila: int) -> void:
	var item_id: String = inventario_mochila.get_item_id(indice_mochila)
	if item_id == "":
		return
	var quantidade: int = inventario_mochila.get_quantidade(indice_mochila)
	var sobra: int = inventario_hotbar.adicionar(item_id, quantidade)
	var movido: int = quantidade - sobra
	if movido > 0:
		inventario_mochila.remover(item_id, movido)


func tem_bancada() -> bool:
	return inventario_hotbar.contar("bancada") > 0 or inventario_mochila.contar("bancada") > 0
