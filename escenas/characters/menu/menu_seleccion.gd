extends Control

@onready var pergamino: TextureRect = $CanvasLayer/Pergamino
@onready var texto_pergamino: Label = $CanvasLayer/Pergamino/Label

var personajes: Array = []
var tween_global: Tween
var posicion_pergamino_oculto: Vector2
var posicion_pergamino_visible: Vector2

func _ready() -> void:
	# Guardamos las posiciones del pergamino para el efecto slide
	posicion_pergamino_oculto = pergamino.position
	# Cambia este Vector2 según a dónde quieras que se desplace (ej: 60 píxeles a la izquierda)
	posicion_pergamino_visible = posicion_pergamino_oculto + Vector2(-250, 0) 
	
	# Buscamos automáticamente todos los personajes en la escena
	for hijo in get_children():
		if hijo.has_signal("personaje_enfocado"):
			personajes.append(hijo)
			# Conectamos las señales por código para ahorrar trabajo manual
			hijo.personaje_enfocado.connect(_on_personaje_enfocado)
			hijo.personaje_desenfocado.connect(_on_personaje_desenfocado)
			hijo.personaje_confirmed.connect(_on_personaje_seleccionado)

# CUANDO EL MOUSE SE PONE ENCIMA DE UNO
func _on_personaje_enfocado(personaje_actual) -> void:
	if tween_global: tween_global.kill()
	tween_global = create_tween().set_parallel(true)
	
	# EFECTO: Oscurecer a todos los demás, dejar al seleccionado brillante
	for p in personajes:
		if p == personaje_actual:
			tween_global.tween_property(p, "modulate", Color(1, 1, 1), 0.25)
		else:
			# Modulate a un tono grisáceo/oscuro
			tween_global.tween_property(p, "modulate", Color(0.3, 0.3, 0.3), 0.25)
	
	# Actualizar y mostrar el pergamino con efecto suave
	texto_pergamino.text = personaje_actual.datos_pergamino
	tween_global.tween_property(pergamino, "position", posicion_pergamino_visible, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# CUANDO EL MOUSE SE QUITA DE ENCIMA
func _on_personaje_desenfocado() -> void:
	if tween_global: tween_global.kill()
	tween_global = create_tween().set_parallel(true)
	
	# EFECTO: Todos vuelven a la normalidad (brillo completo)
	for p in personajes:
		tween_global.tween_property(p, "modulate", Color(1, 1, 1), 0.2)
		
	# Esconder el pergamino deslizándolo hacia afuera
	tween_global.tween_property(pergamino, "position", posicion_pergamino_oculto, 0.2).set_trans(Tween.TRANS_LINEAR)

# CUANDO EL JUGADOR HACE CLICK DIRECTO
func _on_personaje_seleccionado(nombre: String) -> void:
	print("¡El jugador eligió a: ", nombre, "!")
	# Aquí guardas la selección en un Autoload/Singleton y cambias a la escena del juego:
	# Global.personaje_elegido = nombre
	# get_tree().change_scene_to_file("res://Mundo.tscn")
