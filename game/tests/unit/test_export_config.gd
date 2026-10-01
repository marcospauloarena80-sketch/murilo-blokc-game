extends GutTest
## No Godot 4.7.1 a conversão de .tres pra binário na exportação esvazia
## PackedStringArray (elementos_cubelin dos biomas, linhas_dialogo dos NPCs):
## no build publicado nenhuma criatura nascia de dia e os NPCs ficavam sem
## fala, enquanto no editor e nos testes tudo aparecia certo (ADR-027).


func test_exportacao_mantem_recursos_de_texto() -> void:
	assert_false(
		ProjectSettings.get_setting("editor/export/convert_text_resources_to_binary", true),
		"converter .tres pra binário apaga PackedStringArray no build exportado"
	)
