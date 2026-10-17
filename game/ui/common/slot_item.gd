class_name SlotItem
extends RefCounted
## Decora um Button de slot de inventário com o ícone do item (TextureRect) e a
## quantidade (Label no canto inferior direito) — Ciclo 6, 6B. O botão continua
## sendo o botão (clique, estilos de seleção na hotbar) e os filhos ignoram o
## mouse. Usado pela hotbar do HUD, pela mochila e pelo baú.

## Margem do ícone dentro do slot: slot de 44 px mostra o ícone de 32 px em 1:1.
const MARGEM_ICONE: int = 6
const TAMANHO_FONTE: int = 13

var botao: Button
var icone: TextureRect
var quantidade: Label
var _ultimo_item_id: String = ""


static func decorar(botao_alvo: Button) -> SlotItem:
	var slot := SlotItem.new()
	slot.botao = botao_alvo
	botao_alvo.text = ""

	slot.icone = TextureRect.new()
	slot.icone.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, MARGEM_ICONE
	)
	slot.icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slot.icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	botao_alvo.add_child(slot.icone)

	slot.quantidade = Label.new()
	slot.quantidade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.quantidade.offset_right = -3
	slot.quantidade.offset_bottom = -1
	slot.quantidade.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slot.quantidade.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	slot.quantidade.add_theme_font_size_override("font_size", TAMANHO_FONTE)
	slot.quantidade.add_theme_color_override("font_color", Color.WHITE)
	slot.quantidade.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	slot.quantidade.add_theme_constant_override("outline_size", 4)
	slot.quantidade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	botao_alvo.add_child(slot.quantidade)
	return slot


static func icone_solto(item_id: String, lado: int) -> TextureRect:
	## Ícone pequeno fora de slot (linhas de receita), com o nome no tooltip.
	var icone := TextureRect.new()
	icone.custom_minimum_size = Vector2(lado, lado)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icone.texture = IconesItens.textura(item_id)
	var def := ItemRegistry.get_item(item_id)
	icone.tooltip_text = def.nome if def != null else item_id
	return icone


func mostrar(item_id: String, qtd: int) -> void:
	## item_id "" limpa o slot. Textura e tooltip só mudam quando o item muda
	## (chamado todo quadro pelo HUD).
	if item_id != _ultimo_item_id:
		var def := ItemRegistry.get_item(item_id)
		icone.texture = IconesItens.textura(item_id)
		botao.tooltip_text = def.nome if def != null else ""
		_ultimo_item_id = item_id
	quantidade.text = str(qtd) if qtd > 0 else ""
