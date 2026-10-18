extends Node
## Serializa/desserializa o save. Não decide o QUE salvar — cada sistema
## fornece seu próprio snapshot; este autoload só persiste, versiona e
## faz backup do save anterior antes de sobrescrever (ADR-006, mitigação R5).
## Ver docs/02-ARQUITETURA.md §4.6.

## Estado de um arquivo de save, do mais ao menos saudável. Só VALIDO e
## VERSAO_FUTURA são lidos; só VALIDO é copiado para o backup.
enum EstadoArquivo {
	VALIDO,
	INEXISTENTE,
	ERRO_DE_LEITURA,  ## existe mas não foi possível abrir: não dá para julgar o conteúdo
	MALFORMADO,  ## não é JSON
	VAZIO,  ## JSON de objeto vazio
	ESTRUTURA_INVALIDA,  ## JSON, mas sem o campo obrigatório ou com tipo errado
	VERSAO_FUTURA,  ## schema_version maior que a suportada: lido, mas nunca regravado por cima
}

const SCHEMA_VERSION: int = 1
const SAVE_PATH: String = "user://saves/slot1.json"
const BACKUP_PATH: String = "user://saves/slot1.bak.json"

## Pontos de injeção de falha SÓ PARA TESTES; vazios em produção, onde nada muda.
## `renomear_para_teste(origem, destino) -> Error` substitui `rename_absolute`;
## `copiar_para_teste(origem, destino) -> Error` substitui `copy_absolute`.
var renomear_para_teste: Callable = Callable()
var copiar_para_teste: Callable = Callable()


func existe_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Devolve true só com evidência de que o arquivo novo está em disco, inteiro e
## legível; quem precisa garantir persistência (ex.: conclusão do jogo) confere o
## retorno. Veja `_gravar` para a ordem das etapas e o que cada falha preserva.
func salvar(dados: Dictionary) -> bool:
	return _gravar(dados, SAVE_PATH, BACKUP_PATH)


## Etapas, cada uma com falha explícita (devolve false e deixa o save anterior
## como estava):
## 0) os dados novos precisam passar na validação semântica (`ValidadorSave`);
## 1) a pasta de saves existe ou é criada;
## 2) o JSON novo é escrito num temporário, fechado e relido para conferir;
## 3) estado do principal atual: VERSAO_FUTURA ou ERRO_DE_LEITURA recusam a
##    gravação (nunca se sobrescreve o que não se entende nem se consegue ler);
##    VALIDO vai para o backup e a cópia é CONFERIDA (existe, é VALIDO e tem o
##    mesmo texto do principal); qualquer outro estado inválido NÃO toca no
##    backup, que pode ser a última cópia boa;
## 4) o temporário substitui o principal;
## 5) o resultado é relido e conferido.
## Garantia: o principal só é trocado depois de o novo estar conferido; se a troca
## ou a conferência final falharem, sobra uma cópia VALIDA recuperável (o próprio
## principal ou o backup). Limite conhecido: sem `rename` atômico garantido em
## todo sistema de arquivos, uma queda NO INSTANTE da troca pode deixar o principal
## ausente ou inválido; é por isso que o backup válido é preservado antes dela.
func _gravar(dados: Dictionary, caminho: String, caminho_backup: String) -> bool:
	dados["schema_version"] = SCHEMA_VERSION
	if ValidadorSave.avaliar(dados, SCHEMA_VERSION) != ValidadorSave.Resultado.VALIDO:
		return false
	if not _garantir_pasta(caminho.get_base_dir()):
		return false
	var estado_principal := _avaliar_arquivo(caminho)
	if not _pode_gravar_sobre(estado_principal, caminho_backup):
		return false
	var texto := JSON.stringify(dados)
	var temporario := caminho + ".tmp"
	var pronto := _escrever_e_conferir(temporario, texto)
	if pronto and estado_principal == EstadoArquivo.VALIDO:
		pronto = _copiar_e_conferir(caminho, caminho_backup)
	if pronto:
		pronto = _renomear(temporario, caminho) == OK
	_remover(temporario)  ## depois do rename já não existe; em falha, não deixa órfão
	return pronto and _conferir(caminho, texto)


func _garantir_pasta(pasta: String) -> bool:
	return (
		DirAccess.dir_exists_absolute(pasta) or (DirAccess.make_dir_recursive_absolute(pasta) == OK)
	)


## Nunca se sobrescreve o que não se entende (versão futura) nem o que não se
## consegue ler (erro de leitura): o conteúdo poderia ser progresso irrecuperável.
func _pode_gravar_sobre(estado_principal: EstadoArquivo, caminho_backup: String) -> bool:
	if estado_principal == EstadoArquivo.VERSAO_FUTURA:
		return false
	if estado_principal == EstadoArquivo.ERRO_DE_LEITURA:
		return false
	return _avaliar_arquivo(caminho_backup) != EstadoArquivo.VERSAO_FUTURA


## Copia o principal válido para o backup e só confirma se o backup resultante
## existe, passa na mesma validação e tem exatamente o texto do principal.
func _copiar_e_conferir(origem: String, destino: String) -> bool:
	if _copiar(origem, destino) != OK:
		return false
	var texto_origem := _ler_texto(origem)
	return _avaliar_arquivo(destino) == EstadoArquivo.VALIDO and _ler_texto(destino) == texto_origem


func _copiar(origem: String, destino: String) -> Error:
	if copiar_para_teste.is_valid():
		return copiar_para_teste.call(origem, destino)
	return DirAccess.copy_absolute(origem, destino)


func _renomear(origem: String, destino: String) -> Error:
	if renomear_para_teste.is_valid():
		return renomear_para_teste.call(origem, destino)
	return DirAccess.rename_absolute(origem, destino)


## Classifica um arquivo de save pelo que dá para provar sobre ele (sem logar
## erro de parse). Diferencia erro de leitura de conteúdo inválido.
func _avaliar_arquivo(caminho: String) -> EstadoArquivo:
	if not FileAccess.file_exists(caminho):
		return EstadoArquivo.INEXISTENTE
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return EstadoArquivo.ERRO_DE_LEITURA
	var texto := arquivo.get_as_text()
	arquivo.close()
	return _avaliar_texto(texto)


func _avaliar_texto(texto: String) -> EstadoArquivo:
	var json := JSON.new()
	if json.parse(texto) != OK:
		return EstadoArquivo.MALFORMADO
	var resultado := ValidadorSave.avaliar(json.data, SCHEMA_VERSION)
	if resultado == ValidadorSave.Resultado.VALIDO:
		return EstadoArquivo.VALIDO
	if resultado == ValidadorSave.Resultado.VAZIO:
		return EstadoArquivo.VAZIO
	if resultado == ValidadorSave.Resultado.VERSAO_FUTURA:
		return EstadoArquivo.VERSAO_FUTURA
	return EstadoArquivo.ESTRUTURA_INVALIDA


func _e_valido(caminho: String) -> bool:
	return _avaliar_arquivo(caminho) == EstadoArquivo.VALIDO


func _ler_texto(caminho: String) -> String:
	var arquivo := FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		return ""
	var texto := arquivo.get_as_text()
	arquivo.close()
	return texto


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


## Relê o arquivo e só confirma se o texto é idêntico ao esperado e o conteúdo
## passa na validação semântica (pega gravação truncada, vazia ou inválida).
func _conferir(caminho: String, esperado: String) -> bool:
	if _ler_texto(caminho) != esperado:
		return false
	return _avaliar_arquivo(caminho) == EstadoArquivo.VALIDO


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


## Lê o principal se ele passar na validação; senão tenta o backup; senão "sem
## save". Versão futura é lida (política existente: avisa e tenta mesmo assim).
func _carregar_de(caminho: String, caminho_backup: String) -> Dictionary:
	var dados := _ler_aproveitavel(caminho)
	if dados.is_empty():
		dados = _ler_aproveitavel(caminho_backup)
	return migrar(dados)


func _ler_aproveitavel(caminho: String) -> Dictionary:
	var estado := _avaliar_arquivo(caminho)
	if estado != EstadoArquivo.VALIDO and estado != EstadoArquivo.VERSAO_FUTURA:
		return {}
	return _ler_arquivo(caminho)


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
