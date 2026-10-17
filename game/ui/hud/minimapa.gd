class_name Minimapa
extends TextureRect
## Minimapa no canto superior direito (Ciclo 8, 8D). Textura 64 x 64 em que
## 1 pixel = 2 blocos, centrada no jogador, norte para cima. Cor = cor do bloco
## de topo da coluna; água azul, fora do mundo preto, chunk não carregado cinza.
## Recalculada a cada 0,5 s em fatias de poucas linhas por quadro (nunca os
## 4096 get_block de uma vez). Tecla M alterna entre 160 e 320 px.

const LADO_TEXTURA: int = 64
const BLOCOS_POR_PIXEL: int = 2
const LINHAS_POR_QUADRO: int = 16
const INTERVALO_SEG: float = 0.5
const TAMANHO_PEQUENO: float = 160.0
const TAMANHO_GRANDE: float = 320.0
const MARGEM: float = 16.0
const COR_AGUA := Color8(51, 102, 217)
const COR_FORA := Color.BLACK
const COR_NAO_CARREGADO := Color8(90, 90, 90)
const COR_JOGADOR := Color.WHITE
const COR_CAMA := Color8(230, 25, 25)
const COR_VILAREJO := Color(1.0, 0.8, 0.2)
const COR_BORDA := Color8(230, 184, 51)
const CENTRO_VILAREJO := Vector2i(64, 64)

## Posição (x, z) em blocos do centro do mapa; Vector2i(-1, -1) = seguir o jogador.
var centro_forcado: Vector2i = Vector2i(-1, -1)
var direcao: Vector2 = Vector2(0, -1)

var _imagem: Image
var _textura: ImageTexture
var _tempo: float = 0.0
var _linha: int = LADO_TEXTURA  ## LADO_TEXTURA = passada concluída
var _centro: Vector2i = Vector2i.ZERO
var _grande: bool = false
var _chunk_manager: ChunkManager


func _init() -> void:
	name = "Minimapa"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	_imagem = Image.create(LADO_TEXTURA, LADO_TEXTURA, false, Image.FORMAT_RGBA8)
	_imagem.fill(COR_NAO_CARREGADO)
	_textura = ImageTexture.create_from_image(_imagem)
	texture = _textura
	var borda := Panel.new()
	borda.name = "Borda"
	borda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	borda.set_anchors_preset(Control.PRESET_FULL_RECT)
	var estilo := StyleBoxFlat.new()
	estilo.draw_center = false
	estilo.set_border_width_all(3)
	estilo.border_color = COR_BORDA
	borda.add_theme_stylebox_override("panel", estilo)
	add_child(borda)
	_aplicar_tamanho()


func _ready() -> void:
	_chunk_manager = get_tree().get_first_node_in_group("chunk_manager") as ChunkManager


func alternar_tamanho() -> void:
	_grande = not _grande
	_aplicar_tamanho()


func tamanho_atual() -> float:
	return TAMANHO_GRANDE if _grande else TAMANHO_PEQUENO


func _aplicar_tamanho() -> void:
	var lado := tamanho_atual()
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -(lado + MARGEM)
	offset_right = -MARGEM
	offset_top = MARGEM
	offset_bottom = MARGEM + lado


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mapa") and visible:
		alternar_tamanho()


func _process(delta: float) -> void:
	visible = GameState.current_state == GameState.State.PLAYING
	if not visible:
		return
	if _linha < LADO_TEXTURA:
		_calcular_linhas(LINHAS_POR_QUADRO)
		return
	_tempo += delta
	if _tempo >= INTERVALO_SEG:
		_tempo = 0.0
		iniciar_passada()


func iniciar_passada() -> void:
	_centro = _centro_do_mundo()
	_linha = 0


func atualizar_completo() -> void:
	## Passada inteira de uma vez (testes e primeiro desenho).
	iniciar_passada()
	_calcular_linhas(LADO_TEXTURA)


func _centro_do_mundo() -> Vector2i:
	if centro_forcado != Vector2i(-1, -1):
		return centro_forcado
	var jogador := (
		get_tree().get_first_node_in_group("player") as Node3D if is_inside_tree() else null
	)
	if jogador == null:
		return CENTRO_VILAREJO
	var frente := -jogador.global_basis.z
	direcao = Vector2(frente.x, frente.z).normalized() if frente.length() > 0.01 else direcao
	return Vector2i(floori(jogador.global_position.x), floori(jogador.global_position.z))


func _calcular_linhas(quantas: int) -> void:
	var metade := LADO_TEXTURA / 2
	var fim := mini(_linha + quantas, LADO_TEXTURA)
	for py in range(_linha, fim):
		for px in range(LADO_TEXTURA):
			var x := _centro.x + (px - metade) * BLOCOS_POR_PIXEL
			var z := _centro.y + (py - metade) * BLOCOS_POR_PIXEL
			_imagem.set_pixel(px, py, _cor_da_coluna(x, z))
	_linha = fim
	if _linha >= LADO_TEXTURA:
		_desenhar_marcadores()
		_textura.update(_imagem)


func _cor_da_coluna(x: int, z: int) -> Color:
	var limite_x := ChunkManager.WORLD_CHUNKS_X * ChunkData.SIZE_H
	var limite_z := ChunkManager.WORLD_CHUNKS_Z * ChunkData.SIZE_H
	if x < 0 or z < 0 or x >= limite_x or z >= limite_z:
		return COR_FORA
	if _chunk_manager == null or not _chunk_manager.chunk_pronto_em(Vector3(x, 0, z)):
		return COR_NAO_CARREGADO
	var altura := _chunk_manager.altura_da_superficie(x, z)
	if altura < WorldGenerator.NIVEL_AGUA:
		if (
			_chunk_manager.get_block(Vector3i(x, WorldGenerator.NIVEL_AGUA, z))
			== BlockRegistry.AGUA_ID
		):
			return COR_AGUA
	if altura < 0:
		return COR_FORA
	return BlockRegistry.tabela_cores()[_chunk_manager.get_block(Vector3i(x, altura, z))]


func pixel_do_mundo(x: float, z: float) -> Vector2i:
	## Pixel do mapa (fora da textura possível) para uma posição do mundo.
	var metade := LADO_TEXTURA / 2
	return Vector2i(
		metade + floori((x - _centro.x) / BLOCOS_POR_PIXEL),
		metade + floori((z - _centro.y) / BLOCOS_POR_PIXEL)
	)


func _desenhar_marcadores() -> void:
	_marcar(pixel_do_mundo(CENTRO_VILAREJO.x, CENTRO_VILAREJO.y), COR_VILAREJO)
	_marcar(pixel_do_mundo(GameState.ponto_respawn.x, GameState.ponto_respawn.z), COR_CAMA)
	var metade := LADO_TEXTURA / 2
	_marcar(Vector2i(metade, metade), COR_JOGADOR)
	## Ponto de direção 3 pixels à frente do jogador, em cinza escuro para se distinguir.
	var ponta := Vector2i(metade, metade) + Vector2i((direcao * 3.0).round())
	_pixel_seguro(ponta, Color(0.1, 0.1, 0.1))


func _marcar(centro: Vector2i, cor: Color) -> void:
	## Pixel "maior": quadrado 3 x 3.
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			_pixel_seguro(centro + Vector2i(dx, dy), cor)


func _pixel_seguro(p: Vector2i, cor: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < LADO_TEXTURA and p.y < LADO_TEXTURA:
		_imagem.set_pixel(p.x, p.y, cor)


func pixel(x: int, y: int) -> Color:
	return _imagem.get_pixel(x, y)
