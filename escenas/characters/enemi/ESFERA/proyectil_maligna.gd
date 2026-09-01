extends CharacterBody2D

var en_orbita: bool = true
var angulo_actual: float = 0.0
var distancia_al_padre: float = 45.0 # Qué tan separados están de la esfera
var velocidad_giro: float = 3.0

var direccion_disparo: Vector2 = Vector2.ZERO
var velocidad_disparo: float = 250.0

func _physics_process(delta: float) -> void:
	if en_orbita:
		# 1. ESTADO ÓRBITA: Calculamos su posición en círculo
		angulo_actual += velocidad_giro * delta
		
		# Si tenemos a nuestro padre (el ContenedorProyectiles), giramos exactamente alrededor de él
		if get_parent():
			var offset = Vector2(cos(angulo_actual), sin(angulo_actual)) * distancia_al_padre
			position = offset
	else:
		# 2. ESTADO DISPARO: Vuela en línea recta hacia el jugador
		velocity = direccion_disparo * velocidad_disparo
		move_and_slide()

func disparar_hacia(posicion_objetivo: Vector2) -> void:
	en_orbita = false
	var pos_global_temporal = global_position
	direccion_disparo = (posicion_objetivo - pos_global_temporal).normalized()
	
	# Lo sacamos del enemigo y lo pasamos al mapa para que vuele independiente
	var raiz_mapa = get_tree().current_scene
	get_parent().remove_child(self)
	raiz_mapa.add_child(self)
	
	global_position = pos_global_temporal
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_daño"):
		body.recibir_daño(2)
		print("se le quito 2 de vida")
		queue_free() # La bala desaparece al cho
	pass # Replace with function body.
