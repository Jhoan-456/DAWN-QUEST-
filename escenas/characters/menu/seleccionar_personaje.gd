extends Control

@onready var cartel = $tit 
# Señales para avisarle al menú principal qué está pasando
signal personaje_enfocado(personaje)
signal personaje_desenfocado()
signal personaje_confirmado(nombre)

@export var nombre_personaje: String = "Guerrero"
@export_multiline var datos_pergamino: String = "HP: 100\nFuerza: 15\nUn bárbaro implacable."

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var boton: TextureButton = $botonInvisible

var posicion_original: Vector2
var tween_movimiento: Tween
 # Pon aquí el nombre exacto de tu nodo
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	posicion_original = position
	sprite.play("idle") # Animación en bucle por defecto
	
	# Conectamos las señales nativas del botón invisible
	boton.mouse_entered.connect(_on_mouse_entered)
	boton.mouse_exited.connect(_on_mouse_exited)
	boton.pressed.connect(_on_pressed)
	iniciar()
func _on_mouse_entered() -> void:
	personaje_enfocado.emit(self)
	
	# EFECTO: Dar un paso al frente (subir un poco en Y) y agrandarse sutilmente
	if tween_movimiento: tween_movimiento.kill()
	tween_movimiento = create_tween().set_parallel(true)
	tween_movimiento.tween_property(self, "position", posicion_original + Vector2(0, -15), 0.2).set_trans(Tween.TRANS_BACK)
	tween_movimiento.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_BACK)
	
	# Reproducir animación de saludo/reacción
	if sprite.sprite_frames.has_animation("saludo"):
		sprite.play("saludo")
func _on_mouse_exited() -> void:
	personaje_desenfocado.emit()
	
	# EFECTO: Regresar a su posición y tamaño original
	if tween_movimiento: tween_movimiento.kill()
	tween_movimiento = create_tween().set_parallel(true)
	tween_movimiento.tween_property(self, "position", posicion_original, 0.2).set_trans(Tween.TRANS_BACK)
	tween_movimiento.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	sprite.play("idle")

func _on_pressed() -> void:
	personaje_confirmado.emit(nombre_personaje)
func iniciar():
	var posicion_inicial_y = cartel.position.y
	
	# 2. Calculamos el destino sumándole píxeles hacia abajo.
	# Si ves que se queda muy arriba, cambia el 250 por un número más grande (ej: 300 o 350)
	var posicion_final_y = posicion_inicial_y + 150 
	
	# 3. Creamos el Tween para que haga el recorrido solo al iniciar
	var tween = create_tween()
	
	# 4. Deslizamos de forma fluida desde su sitio actual hasta el destino en pantalla
	tween.tween_property(cartel, "position:y", posicion_final_y, 1)\
		.set_trans(Tween.TRANS_QUINT)\
		.set_ease(Tween.EASE_OUT)
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
