extends Area2D

@export var velocidad = 200
var direccion_vector: Vector2 = Vector2.RIGHT

func _process(delta):
	position += direccion_vector * velocidad * delta
	global_position += Vector2.RIGHT.rotated(rotation) * velocidad * delta
func _on_body_entered(body):
	if body.has_method("recibir_daño"): # Función que crearemos en el enemigo
		body.recibir_daño(2)
		print("se le quito 2 de vida")
		queue_free() # La bala desaparece al chocar
