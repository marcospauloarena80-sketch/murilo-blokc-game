extends GutTest
## E0-4 (ADR-032): o botão Desafiar só aparece com um Cubelin em condições.
## Separado de test_dialogue_screen.gd pelo limite de métodos do gdlint.

const DialogueScreenScene := preload("res://ui/dialogue_screen/dialogue_screen.tscn")
const NpcScene := preload("res://entities/npcs/npc.tscn")


func before_each() -> void:
	GameState.equipe_cubelins = [CreatureInstance.new("pedrargo", 20)]
	GameState.insignias_conquistadas = []


func after_each() -> void:
	GameState.equipe_cubelins = []
	GameState.mudar_estado(GameState.State.PLAYING)


func _tela_do_guardiao(arena_id: String) -> DialogueScreen:
	var def := NpcDef.new()
	def.linhas_dialogo = []
	def.abre_arena = arena_id
	var npc := NpcScene.instantiate() as Npc
	add_child_autofree(npc)
	npc.configurar(def)
	var tela := DialogueScreenScene.instantiate() as DialogueScreen
	add_child_autofree(tela)
	tela._abrir(npc)
	return tela


func test_desafiar_escondido_sem_cubelin_disponivel() -> void:
	GameState.equipe_cubelins[0].vida_atual = 0

	var tela := _tela_do_guardiao("pedra")

	assert_false(tela._botao_desafiar.visible)
	assert_string_contains(tela._label_texto.text, "descansar")


func test_desafiar_escondido_sem_equipe() -> void:
	GameState.equipe_cubelins = []

	var tela := _tela_do_guardiao("pedra")

	assert_false(tela._botao_desafiar.visible)


func test_desafiar_volta_com_cubelin_em_condicoes() -> void:
	var tela := _tela_do_guardiao("pedra")

	assert_true(tela._botao_desafiar.visible)
