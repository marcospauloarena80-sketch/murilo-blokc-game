extends GutTest
## Ver docs/07-DECISOES.md ADR-006 (save) — serialização de cada peça antes
## de chegar no SaveManager (que só persiste, não decide o quê).


func test_inventory_model_serializar_e_carregar_ida_e_volta() -> void:
	var inv := InventoryModel.new(8)
	inv.adicionar("pedra", 10)
	inv.adicionar("tronco", 3)

	var dados := inv.serializar()
	var inv2 := InventoryModel.new(8)
	inv2.carregar_serializado(dados)

	assert_eq(inv2.contar("pedra"), 10)
	assert_eq(inv2.contar("tronco"), 3)


func test_inventory_model_serializar_e_json_safe() -> void:
	var inv := InventoryModel.new(4)
	inv.adicionar("pedra", 5)
	var dados := inv.serializar()
	var texto := JSON.stringify(dados)
	var de_volta: Variant = JSON.parse_string(texto)
	assert_not_null(de_volta, "deveria sobreviver a um round-trip JSON de verdade")


func test_inventory_model_carregar_normaliza_quantidade_apos_json() -> void:
	# Simula o que acontece de verdade: JSON vira float, precisa voltar a int.
	var inv := InventoryModel.new(4)
	inv.carregar_serializado([{"item_id": "pedra", "quantidade": 5.0}, {}, {}, {}])
	assert_eq(inv.get_quantidade(0), 5)
	assert_typeof(inv.get_quantidade(0), TYPE_INT)


func test_character_appearance_serializar_e_carregar_ida_e_volta() -> void:
	var aparencia := CharacterAppearance.new()
	aparencia.cor_pele = CharacterAppearance.PALETA_PELE[3]
	aparencia.cor_camisa = Color(0.1, 0.2, 0.3, 1.0)

	var dados := aparencia.serializar()
	var aparencia2 := CharacterAppearance.new()
	aparencia2.carregar_serializado(dados)

	assert_eq(aparencia2.cor_pele, CharacterAppearance.PALETA_PELE[3])
	assert_eq(aparencia2.cor_camisa, Color(0.1, 0.2, 0.3, 1.0))


func test_character_appearance_serializar_e_json_safe() -> void:
	var aparencia := CharacterAppearance.new()
	var texto := JSON.stringify(aparencia.serializar())
	var de_volta: Variant = JSON.parse_string(texto)
	assert_not_null(de_volta)
