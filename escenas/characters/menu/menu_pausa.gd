extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var panel = $Panel
	# Empezamos el panel pequeñito (escala 0)
	panel.scale = Vector2.ZERO
	panel.pivot_offset = panel.size / 2 # Centramos el pivote
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_atras_pressed() -> void:
	queue_free()
	
	get_tree().paused = false
	pass # Replace with function body.

func _on_volmenu_pressed() -> void:
	pass # Replace with function body.
