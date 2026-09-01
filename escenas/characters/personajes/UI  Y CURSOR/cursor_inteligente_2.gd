extends Sprite2D

func _ready() -> void:
	# Ocultamos el cursor aburrido del sistema operativo
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(delta: float) -> void:
	# Hacemos que nuestro Sprite siga la posición del mouse en la pantalla
	global_position = get_viewport().get_mouse_position()
