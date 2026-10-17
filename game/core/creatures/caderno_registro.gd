class_name CadernoRegistro
extends RefCounted
## Registro das espécies vistas/capturadas do Caderno (Ciclo 9, 9D). Fica fora
## do GameState (já no limite de métodos públicos) e mexe nas listas dele.


static func registrar_vista(especie_id: String) -> void:
	if especie_id != "" and not GameState.especies_vistas.has(especie_id):
		GameState.especies_vistas.append(especie_id)


static func registrar_capturada(especie_id: String) -> void:
	## Capturar também conta como ter visto.
	registrar_vista(especie_id)
	if especie_id != "" and not GameState.especies_capturadas.has(especie_id):
		GameState.especies_capturadas.append(especie_id)
