extends Area2D
class_name Joystick

var distan : float
var direc : Vector2
var index : int = -1
@onready var rango = $SpriteRango
@onready var palanca = $SpritePalanca
@onready var radio = $CollisionShape2D.shape.radius


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass 
# Replace with function body.
func _input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed() and index == -1:
			distan = global_position.distance_to(event.position)
			if distan < radio:
				index = event.index
				palanca.global_position  = event.position						
				direc = global_position.direction_to(palanca.global_position) * distan / radio
			pass
		elif event.index == index:
			index = -1
			palanca.position = Vector2.ZERO 
			direc = Vector2.ZERO
			pass
	if event is InputEventScreenDrag:
		if event.index == index:
			distan = global_position.distance_to(event.position)
			if distan <= radio:
				palanca.global_position  = event.position						
				direc = (global_position.direction_to(palanca.global_position) * distan) / radio
				pass
			else:
				direc = global_position.direction_to(event.position)
				palanca.global_position = global_position + (direc * radio) 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
