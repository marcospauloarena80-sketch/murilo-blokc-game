extends Node
## Serializa/desserializa o save. Não decide o QUE salvar — cada sistema
## fornece seu próprio snapshot; este autoload só persiste e versiona.
## Formato: JSON versionado em user://saves/slot1.json (ADR-006).
## Ver docs/02-ARQUITETURA.md §4.6.

const SCHEMA_VERSION: int = 1
const SAVE_PATH: String = "user://saves/slot1.json"


func salvar(dados: Dictionary) -> void:
	dados["schema_version"] = SCHEMA_VERSION
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	var arquivo := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(dados))


func carregar() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var arquivo := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var texto := arquivo.get_as_text()
	var resultado: Variant = JSON.parse_string(texto)
	if resultado == null:
		return {}
	return resultado as Dictionary
