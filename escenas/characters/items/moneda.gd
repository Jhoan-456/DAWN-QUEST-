extends Area2D

@export var texto_flotante_scene: PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

#-------------------------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	# Verificamos si el cuerpo que entró es el Player
	if body.name == "Player" or body.has_method("recibir_daño"):
		# 1. Le sumamos 1 a la variable del jugador
		if "Moneda" in body:
			body.Moneda += 1
			crear_texto_flotante("+"+str(body.Moneda),Color(0.867, 0.824, 0.0, 1.0))
			print("Monedas totales: ", body.Moneda)
			# 2. Desaparecemos la moneda
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
