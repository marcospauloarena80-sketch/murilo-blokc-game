extends Node
## Serializa/desserializa o save. Não decide o QUE salvar — cada sistema
## fornece seu próprio snapshot; este autoload só persiste, versiona e
## faz backup do save anterior antes de sobrescrever (ADR-006, mitigação R5).
## Ver docs/02-ARQUITETURA.md §4.6.

const SCHEMA_VERSION: int = 1
const SAVE_PATH: String = "user://saves/slot1.json"
const BACKUP_PATH: String = "user://saves/slot1.bak.json"

## Ponto de injeção de falha SÓ PARA TESTES: se válido, substitui `rename_absolute`
## (recebe origem e destino, devolve um Error). Em produção fica vazio e nada muda.
var renomear_para_teste: Callable = Callable()


func existe_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Devolve true só com evidência de que o arquivo novo está em disco, inteiro e
## legível; quem precisa garantir persistência (ex.: conclusão do jogo) confere o
## retorno. Veja `_gravar` para a ordem das etapas e o que cada falha preserva.
func salvar(dados: Dictionary) -> bool:
	return _gravar(dados, SAVE_PATH, BACKUP_PATH)


## Etapas, cada uma com falha explícita (devolve false e deixa o save anterior
## como estava): 1) pasta de saves existe ou é criada; 2) o JSON novo é escrito num
## arquivo temporário, que é fechado e relido para conferir; 3) se o save atual é
## VÁLIDO, ele vai pro backup (cópia conferida); se estiver corrompido, o backup
## existente NÃO é tocado, porque pode ser a última cópia boa; 4) o temporário
## substitui o save atual; 5) o resultado é relido. O save atual só é trocado
## depois de o novo já estar conferido; se a troca falhar, ou o save atual segue
## intacto, ou o backup guarda a última versão válida: sempre sobra uma cópia
## recuperável pelo `carregar`.
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
	if _e_valido(caminho):
		if DirAccess.copy_absolute(caminho, caminho_backup) != OK:
			_remover(temporario)
			return false
	if _renomear(temporario, caminho) != OK:
		_remover(temporario)
		return false
	return _conferir(caminho, texto)


func _renomear(origem: String, destino: String) -> Error:
	if renomear_para_teste.is_valid():
		return renomear_para_teste.call(origem, destino)
	return DirAccess.rename_absolute(origem, destino)


## Arquivo existe, lê e é um objeto JSON não vazio (sem logar erro de parse).
func _e_valido(caminho: String) -> bool:
	if not FileAccess.file_exists(caminho):
		return false
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return false
	var texto := arquivo.get_as_text()
	arquivo.close()
	var json := JSON.new()
	if json.parse(texto) != OK:
		return false
	return json.data is Dictionary and not (json.data as Dictionary).is_empty()


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
	if arquivo == null:
		return {}
	var texto := arquivo.get_as_text()
	arquivo.close()
	var json := JSON.new()
	if json.parse(texto) != OK or not (json.data is Dictionary):
		return {}  ## ilegível ou não é um objeto: tratado como "sem save"
	return json.data as Dictionary
