extends Area2D

@export var velocidad = 200
var direccion_vector: Vector2 = Vector2.RIGHT
var daño: float = 0.0
var dano: float = 0.0

func _process(delta):
	position += direccion_vector * velocidad * delta
	global_position += Vector2.RIGHT.rotated(rotation) * velocidad * delta
func _on_body_entered(body):
	if body.has_method("recibir_daño"):
		# Determinamos cuál variable tiene el valor asignado
		var dano_a_aplicar = daño if daño > 0 else dano
		
		# 👈 Pasamos 'dano_a_aplicar' como parámetro para que no sea 0
		body.recibir_daño(int(dano_a_aplicar))
		print("Se le quitó ", dano_a_aplicar, " de vida")
		queue_free()
