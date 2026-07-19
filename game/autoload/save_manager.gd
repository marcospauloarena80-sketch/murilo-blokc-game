extends Node
## Serializa/desserializa o save. Não decide o QUE salvar — cada sistema
## fornece seu próprio snapshot; este autoload só persiste, versiona e
## faz backup do save anterior antes de sobrescrever (ADR-006, mitigação R5).
## Ver docs/02-ARQUITETURA.md §4.6.

const SCHEMA_VERSION: int = 1
const SAVE_PATH: String = "user://saves/slot1.json"
const BACKUP_PATH: String = "user://saves/slot1.bak.json"


func existe_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func salvar(dados: Dictionary) -> void:
	dados["schema_version"] = SCHEMA_VERSION
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	if FileAccess.file_exists(SAVE_PATH):
		dir.copy(SAVE_PATH, BACKUP_PATH)
	var arquivo := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(dados))


func carregar() -> Dictionary:
	var dados := _ler_arquivo(SAVE_PATH)
	if dados.is_empty():
		dados = _ler_arquivo(BACKUP_PATH)
	return migrar(dados)


func migrar(dados: Dictionary) -> Dictionary:
	## Cadeia de migração (ADR-006). Só existe a v1 até agora — quando surgir
	## a v2, encadear aqui: if versao == 1: dados = _migrar_v1_para_v2(dados).
	if dados.is_empty():
		return dados
	var versao: int = dados.get("schema_version", SCHEMA_VERSION)
	if versao > SCHEMA_VERSION:
		push_warning("Save de versão futura (%d); tentando ler mesmo assim." % versao)
	return dados


func _ler_arquivo(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	var texto := arquivo.get_as_text()
	var resultado: Variant = JSON.parse_string(texto)
	if resultado == null or not (resultado is Dictionary):
		return {}
	return resultado as Dictionary
