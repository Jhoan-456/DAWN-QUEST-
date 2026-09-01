extends CanvasLayer

# Arrastra aquí tu ventana/panel de pausa desde el árbol de nodos
@onready var menu_pausa: Control = $Control
@onready var boton_pausa_pantalla: Button = $pausa

func _ready() -> void:
	# El juego inicia normal, así que la ventana de pausa debe estar oculta
	menu_pausa.visible = false
	
	# Conectamos el botón físico de la pantalla
	boton_pausa_pantalla.pressed.connect(alternar_pausa)
	
	# OPCIONAL: Si tienes un botón de "Continuar" ADENTRO de tu ventana de pausa:
	# $MenuPausa/BotonContinuar.pressed.connect(alternar_pausa)

func _input(event: InputEvent) -> void:
	# "ui_cancel" es la acción que Godot trae por defecto asignada a la tecla ESCAPE
	if event.is_action_pressed("salir"):
		alternar_pausa()

func alternar_pausa() -> void:
	# 1. Invertimos el estado actual de la pausa del juego
	var nuevo_estado_pausa = !get_tree().paused
	get_tree().paused = nuevo_estado_pausa
	
	# 2. Mostramos u ocultamos la ventana dependiendo de si está pausado o no
	menu_pausa.visible = nuevo_estado_pausa
	
	# 3. Opcional: Ocultamos el botón de pausa flotante para que no estorbe
	boton_pausa_pantalla.visible = !nuevo_estado_pausa
