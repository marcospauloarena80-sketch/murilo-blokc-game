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


## Devolve true só se o arquivo foi gravado por inteiro; quem precisa garantir
## persistência (ex.: conclusão do jogo) confere o retorno. O save anterior vai
## pro backup antes de sobrescrever, então uma gravação interrompida ainda deixa
## `carregar()` voltar ao estado anterior.
func salvar(dados: Dictionary) -> bool:
	dados["schema_version"] = SCHEMA_VERSION
	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
	if FileAccess.file_exists(SAVE_PATH):
		dir.copy(SAVE_PATH, BACKUP_PATH)
	var arquivo := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if arquivo == null:
		return false
	var gravou: bool = arquivo.store_string(JSON.stringify(dados))
	arquivo.close()
	return gravou


## Pede à cena para salvar e devolve se gravou. Cena sem `salvar_jogo` (testes,
## menu) conta como "não gravou". É a única lógica de "salvar pela cena" do jogo.
func salvar_pela_cena(cena: Node) -> bool:
	if cena == null or not cena.has_method("salvar_jogo"):
		return false
	return bool(cena.call("salvar_jogo"))


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
