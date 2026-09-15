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


func _on_area_2d_area_entered(area: Area2D) -> void:
	
	# Verificamos si el área con la que chocamos es el escudo
	if area.is_in_group("escudo_jugador"):
		
		# Verificamos que el jugador tenga la función para recibir daño al escudo
		if area.get_parent().has_method("recibir_dano_escudo"):
			
			# Le pasamos el daño de este enemigo/bala
			area.get_parent().recibir_dano_escudo(10) # Cambia el 10 por tu variable de daño
			
			# Si esto es una bala, hacemos que se destruya al chocar con el escudo
			queue_free()
	pass # Replace with function body.
	pass # Replace with function body.
