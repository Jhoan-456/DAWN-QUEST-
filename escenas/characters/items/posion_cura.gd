extends Area2D

@export var texto_flotante_scene: PackedScene
var sumo_vida = 2
signal stats_cambiadas
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

#-------------------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	# Verificamos si el cuerpo que entró es el Player y si tiene la variable vida
	if (body.name == "Player" or body.has_method("recibir_daño")) and "vida" in body:
		
		# CONDICIÓN A: Si el jugador ya tiene la vida al máximo (4 o más)
		if body.vida >= 4:
			body.Moneda += 1
			# Mostramos el texto flotante amarillo de la moneda
			crear_texto_flotante("+2", Color(0.867, 0.824, 0.0, 1.0))
			print("Vida llena. Poción convertida en moneda. Total: ", body.Moneda)
			
		# CONDICIÓN B: Si le falta vida (es menor a 4), lo curamos normalmente
		else:
			body.vida += sumo_vida
			stats_cambiadas.emit()
			# Un candado de seguridad para que la cura no lo haga pasar de 100
			body.vida = clamp(body.vida, 0, 4) 
			
			# Mostramos el texto flotante verde de curación
			crear_texto_flotante("+" + str(sumo_vida), Color(0.237, 0.817, 0.0, 1.0))
			print("Subió: ", sumo_vida, " de vida. Vida actual: ", body.vida)
		
		# CRUCIAL: El queue_free() se llama al final de haber resuelto toda la lógica
		queue_free()
		
#-------------------------------------------------------------------------

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func crear_texto_flotante(valor: String, color: Color) -> void:
	if not texto_flotante_scene: return
	
	var texto = texto_flotante_scene.instantiate()
	# Lo colocamos en el mundo general para que no se mueva pegado al personaje
	get_parent().add_child(texto)
	# Lo posicionamos justo encima de la cabeza del personaje
	texto.global_position = global_position + Vector2(0, -20)
	texto.mostrar(valor, color)
