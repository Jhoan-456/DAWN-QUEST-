extends Area2D
class_name Joystick

var distan: float = 0.0
var direc: Vector2 = Vector2.ZERO
var index: int = -1

@onready var rango = $SpriteRango
@onready var palanca = $SpritePalanca
@onready var radio = $CollisionShape2D.shape.radius


func _input(event):
	if event is InputEventScreenTouch:
		# Convertimos la posición del toque al espacio local del Joystick
		var pos_local = make_input_local(event).position
		
		if event.is_pressed() and index == -1:
			distan = Vector2.ZERO.distance_to(pos_local)
			if distan <= radio:
				index = event.index
				palanca.position = pos_local
				direc = pos_local.normalized() * (distan / radio)
				
		elif event.index == index and not event.is_pressed():
			index = -1
			palanca.position = Vector2.ZERO
			direc = Vector2.ZERO

	elif event is InputEventScreenDrag and event.index == index:
		var pos_local = make_input_local(event).position
		distan = Vector2.ZERO.distance_to(pos_local)
		
		if distan <= radio:
			palanca.position = pos_local
			direc = pos_local.normalized() * (distan / radio)
		else:
			direc = pos_local.normalized()
			palanca.position = direc * radio
