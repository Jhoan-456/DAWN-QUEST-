extends Node2D

func _ready() -> void:
	aparecer_jugador()

func aparecer_jugador() -> void:
	if Datos.ruta_personaje_seleccionado != "":
		# 1. Cargamos e instanciamos la escena del personaje guardada en Global
		var escena_jugador = load(Datos.ruta_personaje_seleccionado)
		var jugador = escena_jugador.instantiate()
		
		# 2. Lo agregamos al nivel
		add_child(jugador)
		
		# 3. Le asignamos una posición de inicio (Ajusta estas coordenadas X e Y según tu mapa)
		jugador.global_position = Vector2(200, 200) 
		
		# 💡 NOTA: Si tienes un Marker2D llamado "PuntoAparicion" en tu mapa, puedes usar:
		if has_node("PuntoAparicion"):
			jugador.global_position = $PuntoAparicion.global_position
