extends Node
## Máquina de estados global do jogo. Não conhece UI, não conhece nós de cena.
## Ver docs/02-ARQUITETURA.md §3.

enum State { BOOT, MENU, CHARACTER_CREATION, PLAYING, PAUSED, BATTLE }

const DURACAO_CICLO_SEG: float = 900.0  ## dia 10min + noite 5min (GDD F6)
const FRACAO_DIA: float = 600.0 / 900.0
const MAX_EQUIPE: int = 3  ## docs/01-GDD.md §10 (F8)

var current_state: State = State.BOOT
var seed_atual: int = 0
var tempo_de_jogo_seg: float = 0.0
var aparencia_atual: CharacterAppearance = CharacterAppearance.new()
var inventario_hotbar: InventoryModel = InventoryModel.new(8)
var inventario_mochila: InventoryModel = InventoryModel.new(24)
var hotbar_selecionado: int = 0
var vida_atual: int = 20
var vida_maxima: int = 20
var fome_atual: int = 20
var fome_maxima: int = 20
var energia_atual: int = 20
var energia_maxima: int = 20
var ciclo_dia_noite_seg: float = DURACAO_CICLO_SEG * 0.25  ## começa de manhã
var ponto_respawn: Vector3 = Vector3(64, 45, 64)
var baus: Dictionary = {}  ## "x,y,z" -> InventoryModel(24)
var equipe_cubelins: Array[CreatureInstance] = []  ## até MAX_EQUIPE (F8)
var deposito_cubelins: Array[CreatureInstance] = []  ## excedente — vira tela do Laboratório na F9

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
	fome_atual = fome_maxima
	energia_atual = energia_maxima
	ciclo_dia_noite_seg = DURACAO_CICLO_SEG * 0.25
	ponto_respawn = Vector3(64, 45, 64)
	baus = {}
	equipe_cubelins = []
	deposito_cubelins = []
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


func tem_fornalha() -> bool:
	return inventario_hotbar.contar("fornalha") > 0 or inventario_mochila.contar("fornalha") > 0


func eh_noite() -> bool:
	var fase: float = fmod(ciclo_dia_noite_seg, DURACAO_CICLO_SEG) / DURACAO_CICLO_SEG
	return fase >= FRACAO_DIA


func adicionar_cubelin(instancia: CreatureInstance) -> void:
	## Equipe até MAX_EQUIPE; excedente vai pro depósito (Laboratório na F9).
	if equipe_cubelins.size() < MAX_EQUIPE:
		equipe_cubelins.append(instancia)
	else:
		deposito_cubelins.append(instancia)


func tem_cubelin_disponivel() -> bool:
	for cubelin: CreatureInstance in equipe_cubelins:
		if not cubelin.esta_desmaiado():
			return true
	return false


func obter_bau(chave: String) -> InventoryModel:
	if not baus.has(chave):
		baus[chave] = InventoryModel.new(24)
	return baus[chave]


static func chave_posicao(pos: Vector3i) -> String:
	return "%d,%d,%d" % [pos.x, pos.y, pos.z]
