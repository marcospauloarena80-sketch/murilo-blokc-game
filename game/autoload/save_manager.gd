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


## Devolve true só com evidência de que o arquivo novo está em disco, inteiro e
## legível; quem precisa garantir persistência (ex.: conclusão do jogo) confere o
## retorno. Veja `_gravar` para a ordem das etapas e o que cada falha preserva.
func salvar(dados: Dictionary) -> bool:
	return _gravar(dados, SAVE_PATH, BACKUP_PATH)


## Etapas, cada uma com falha explícita (devolve false e deixa o save anterior
## como estava): 1) pasta de saves existe ou é criada; 2) o JSON novo é escrito num
## arquivo temporário, que é fechado e relido para conferir; 3) o save atual vai
## pro backup (cópia conferida); 4) o temporário substitui o save atual; 5) o
## resultado é relido. Como o save atual só é trocado depois de o novo já estar
## conferido, uma falha no meio nunca corrompe o que já existia, e `carregar`
## ainda cai no backup se o principal estiver ilegível.
func _gravar(dados: Dictionary, caminho: String, caminho_backup: String) -> bool:
	dados["schema_version"] = SCHEMA_VERSION
	var pasta := caminho.get_base_dir()
	if not DirAccess.dir_exists_absolute(pasta):
		if DirAccess.make_dir_recursive_absolute(pasta) != OK:
			return false
	var texto := JSON.stringify(dados)
	var temporario := caminho + ".tmp"
	if not _escrever_e_conferir(temporario, texto):
		_remover(temporario)
		return false
	if FileAccess.file_exists(caminho):
		if DirAccess.copy_absolute(caminho, caminho_backup) != OK:
			_remover(temporario)
			return false
	if DirAccess.rename_absolute(temporario, caminho) != OK:
		_remover(temporario)
		return false
	return _conferir(caminho, texto)


func _escrever_e_conferir(caminho: String, texto: String) -> bool:
	var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo == null:
		return false
	var escreveu: bool = arquivo.store_string(texto)
	arquivo.flush()
	var erro: Error = arquivo.get_error()
	arquivo.close()
	if not escreveu or erro != OK:
		return false
	return _conferir(caminho, texto)


## Relê o arquivo e só confirma se o texto é idêntico ao esperado e é um JSON de
## objeto válido (pega gravação truncada ou vazia).
func _conferir(caminho: String, esperado: String) -> bool:
	if not FileAccess.file_exists(caminho):
		return false
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return false
	var lido := arquivo.get_as_text()
	arquivo.close()
	if lido != esperado:
		return false
	return JSON.parse_string(lido) is Dictionary


func _remover(caminho: String) -> void:
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)


## Pede à cena para salvar e devolve se gravou. Cena sem `salvar_jogo` (testes,
## menu) conta como "não gravou". É a única lógica de "salvar pela cena" do jogo.
func salvar_pela_cena(cena: Node) -> bool:
	if cena == null or not cena.has_method("salvar_jogo"):
		return false
	return bool(cena.call("salvar_jogo"))


func carregar() -> Dictionary:
	return _carregar_de(SAVE_PATH, BACKUP_PATH)


func _carregar_de(caminho: String, caminho_backup: String) -> Dictionary:
	var dados := _ler_arquivo(caminho)
	if dados.is_empty():
		dados = _ler_arquivo(caminho_backup)
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
