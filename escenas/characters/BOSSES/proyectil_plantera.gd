extends CharacterBody2D

@export var velocidad: float = 180.0
var direccion: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	# Mueve la esfera en la dirección indicada
	global_position += direccion * velocidad * delta
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_daño") and not body.is_in_group("bosses"):
		body.recibir_daño(2)
		queue_free()
	elif body is TileMapLayer:
			queue_free()
	pass # Replace with function body.


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
	pass # Replace with function body.
