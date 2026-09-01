extends Node2D

@export_group("Escenas de Salas")
@export var escena_inicio: PackedScene
@export var escena_enemigos: PackedScene
@export var escena_cofre: PackedScene
@export var escena_boss : PackedScene

@export_group("Escenas de Pasillos")
@export var escena_pasillo_h: PackedScene # Pasillo Horizontal (Izquierda <-> Derecha)
@export var escena_pasillo_v: PackedScene # Pasillo Vertical (Arriba <-> Abajo)

@export_group("Jugador")
@export var escena_jugador: PackedScene # Arrastra la escena de tu personaje aquí

@export_group("Configuración")
@export var total_salas: int = 6
# Distancia entre el CENTRO de una sala y el CENTRO de la siguiente en píxeles:
@export var distancia_entre_salas: Vector2 = Vector2(800, 500)

# Diccionario interno para la cuadrícula: { Vector2i(x,y) : "tipo_de_sala" }
var grid_salas: Dictionary = {}

func _ready() -> void:
	randomize() # Cambia la semilla aleatoria en cada partida
	generar_logica_mapa()
	construir_mapa()

# ----------------------------------------------------
# 1. CREA LA ESTRUCTURA EN LA CUADRÍCULA
# ----------------------------------------------------
func generar_logica_mapa() -> void:
	var pos_actual = Vector2i.ZERO
	grid_salas[pos_actual] = "inicio"
	
	var direcciones = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	# 1. Generamos el camino de salas
	while grid_salas.size() < total_salas:
		var dir_aleatoria = direcciones.pick_random()
		pos_actual += dir_aleatoria
		
		if not grid_salas.has(pos_actual):
			grid_salas[pos_actual] = "enemigos"
	
	# 2. La última sala (la más lejana) se convierte en la del BOSS
	grid_salas[pos_actual] = "boss"
	
	# 3. Buscamos las salas de enemigos para convertir una en COFRE
	var salas_enemigos = []
	for coord in grid_salas.keys():
		if grid_salas[coord] == "enemigos":
			salas_enemigos.append(coord)
			
	# Asignamos la sala de cofre a una posición aleatoria del camino
	if salas_enemigos.size() > 0:
		var coord_cofre = salas_enemigos.pick_random()
		grid_salas[coord_cofre] = "cofre"
	

# ----------------------------------------------------
# 2. INSTANCIA LAS SALAS, PASILLOS Y AL JUGADOR
# ----------------------------------------------------
func construir_mapa() -> void:
	# --- A) INSTANCIAR SALAS Y JUGADOR ---
	for coord in grid_salas.keys():
		var tipo = grid_salas[coord]
		var nueva_sala: Node2D
		
		match tipo:
			"inicio":
				nueva_sala = escena_inicio.instantiate()
			"cofre":
				nueva_sala = escena_cofre.instantiate()
			"enemigos":
				nueva_sala = escena_enemigos.instantiate()
			"boss":
				nueva_sala = escena_boss.instantiate()
				
		add_child(nueva_sala)
		
		# Posición en el juego según la casilla en la cuadrícula
		var pos_mundo = Vector2(coord.x * distancia_entre_salas.x, coord.y * distancia_entre_salas.y)
		nueva_sala.global_position = pos_mundo
		
		# Si es la sala de inicio, spawneamos al personaje en su centro
		if tipo == "inicio" and escena_jugador:
			var jugador = escena_jugador.instantiate()
			add_child(jugador)
			jugador.global_position = pos_mundo

	# --- B) INSTANCIAR PASILLOS AUTOMÁTICOS ---
	for coord in grid_salas.keys():
		var pos_actual_mundo = Vector2(coord.x * distancia_entre_salas.x, coord.y * distancia_entre_salas.y)
		
		# ¿Hay una sala a la DERECHA? -> Ponemos un pasillo Horizontal
		var coord_derecha = coord + Vector2i.RIGHT
		if grid_salas.has(coord_derecha) and escena_pasillo_h:
			var pasillo = escena_pasillo_h.instantiate()
			add_child(pasillo)
			# Lo ubicamos justo a la mitad del camino entre ambas salas
			pasillo.global_position = pos_actual_mundo + Vector2(distancia_entre_salas.x / 2.0, 0)

		# ¿Hay una sala ABAJO? -> Ponemos un pasillo Vertical
		var coord_abajo = coord + Vector2i.DOWN
		if grid_salas.has(coord_abajo) and escena_pasillo_v:
			var pasillo = escena_pasillo_v.instantiate()
			add_child(pasillo)
			# Lo ubicamos justo a la mitad del camino hacia abajo
			pasillo.global_position = pos_actual_mundo + Vector2(0, distancia_entre_salas.y / 2.0)
