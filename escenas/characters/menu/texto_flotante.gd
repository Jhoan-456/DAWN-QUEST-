extends Marker2D

@onready var label: Label = $Label

func mostrar(texto: String, color: Color) -> void:
	label.text = texto
	label.modulate = color
	
	# Le damos una pequeña aleatoriedad horizontal para que si salen varios, no se tapen
	var desvio_x = randf_range(-15.0, 15.0)
	
	# Creamos el Tween para animar movimiento y desvanecimiento
	var tween = create_tween().set_parallel(true)
	
	# 1. Sube 40 píxeles y se mueve un poco hacia los lados durante 0.6 segundos
	tween.tween_property(self, "position", position + Vector2(desvio_x, -40), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 2. Hace un efecto de escala (empieza un poco grande y vuelve a tamaño normal)
	scale = Vector2(1.3, 1.3)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 3. Se desvanece hasta hacerse transparente (alpha = 0)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	
	# Cuando termina la animación, eliminamos el nodo para no gastar memoria
	tween.chain().tween_callback(queue_free)
