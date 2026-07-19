extends GutTest
## Regressão: dono queria jogar só com teclado (mouse só pra câmera) — sem
## atalho de teclado, minerar/colocar exigia clique-e-segurar do mouse/
## trackpad, que falhava de forma intermitente em alguns navegadores
## (ver ADR-026). "quebrar"/"colocar" ganham tecla alternativa (Q/C) sem
## remover o clique do mouse (os dois continuam funcionando).


func test_quebrar_tem_tecla_q_alem_do_clique_esquerdo() -> void:
	var eventos := InputMap.action_get_events("quebrar")
	var tem_tecla_q := false
	for evento in eventos:
		if evento is InputEventKey and evento.physical_keycode == KEY_Q:
			tem_tecla_q = true
	assert_true(tem_tecla_q, "quebrar deveria responder à tecla Q")


func test_colocar_tem_tecla_c_alem_do_clique_direito() -> void:
	var eventos := InputMap.action_get_events("colocar")
	var tem_tecla_c := false
	for evento in eventos:
		if evento is InputEventKey and evento.physical_keycode == KEY_C:
			tem_tecla_c = true
	assert_true(tem_tecla_c, "colocar deveria responder à tecla C")
