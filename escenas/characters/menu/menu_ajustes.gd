extends CanvasLayer

@onready var menu_despleguable = $VBoxContainer/ScrollContainer/ListaOpciones/ListaOpciones/CONTROLS/volumen/OptionButtonMenu
@onready var mundos_despleguable = $VBoxContainer/ScrollContainer/ListaOpciones/ListaOpciones/CONTROLS/volumen/volumen/OptionButtonMundos
func _ready():
	#Limpiar al principio por si hay listas antiguas :v
	menu_despleguable.clear()
	mundos_despleguable.clear()
	
	#----------------------------------------------------
	mundos_despleguable.add_item("Columnas
	que Caen") # 0
	mundos_despleguable.add_item("Escaleras") # 1
	mundos_despleguable.add_item("Iris") # 2
	
	menu_despleguable.add_item("Columnas
	que Caen") # 0
	menu_despleguable.add_item("Escaleras") # 1
	menu_despleguable.add_item("Iris") # 2
	
	menu_despleguable.select(TransicionGlobal.transicion_actual)
	mundos_despleguable.select(TransicionGlobal.transicion_actual)
	var panel = $Panel # Ajusta la ruta a tu panel
	
	# Empezamos el panel pequeñito (escala 0)
	panel.scale = Vector2.ZERO
	panel.pivot_offset = panel.size / 2 # Centramos el pivote
	
	# Animación de aparición
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pass
	
func _on_button_pressed() -> void:
	queue_free()
func _on_option_button_mundos_item_selected(index: int) -> void:
	TransicionGlobal.transicion_actual = index
	print("Transición cambiada a la opción número: ", index)
func _on_option_button_menu_item_selected(index: int) -> void:
	TransicionGlobal.transicion_actual = index
	print("Transición cambiada a la opción número: ", index)
	pass # Replace with function body.
