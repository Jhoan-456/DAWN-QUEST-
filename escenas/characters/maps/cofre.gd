extends Area2D

var jugador_cerca = false
var abierto = false	

var tween_flote : Tween
var posicion_y_original : float
# Called when the node enters the scene tree for the first time.
#-------------------------------------------------------------------------
@export var escena_moneda: PackedScene
@export var escena_posion: PackedScene
#-------------------------------------------------------------------------
func _ready() -> void:
	$flecha.visible = false
	posicion_y_original = $flecha.position.y
	#$AnimatedSprite2D.play("cerrado")
	pass # Replace with function body.	
func _on_body_exited(body):
	if body.name == "Player":
		jugador_cerca = false
		print(jugador_cerca)
		$flecha.visible = false
		detener_animacion_flecha()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if jugador_cerca and Input.is_action_pressed("interactuar") and not abierto:
		abrir_cofre()
	pass
func abrir_cofre():
	abierto = true	
	#$AnimatedSprite2D.play("abierto")
	print("Cofre Abierto Permanetemenbte")
	$flecha.visible = false
	soltar_moneda()
	soltar_posion()
	
func soltar_moneda():
	var nueva_moneda = escena_moneda.instantiate()
	# Usamos get_parent() para que la moneda sea 'hermana' del cofre y no 'hija'
	get_parent().add_child(nueva_moneda)
	nueva_moneda.global_position = global_position
	nueva_moneda.global_position.y -= 50  # Esto la sube un poco para que se vea arriba del cofre
	#nueva_moneda.z_index = 1 # Esto la pone una capa por encima visualmente
func soltar_posion():
	var nueva_posion = escena_posion.instantiate()
	# Usamos get_parent() para que la moneda sea 'hermana' del cofre y no 'hija'
	get_parent().add_child(nueva_posion)
	nueva_posion.global_position = global_position
	nueva_posion.global_position.y -= 50
	nueva_posion.global_position.x -= 40
	
func _on_body_entered(body: Node2D) -> void:
		if body.name == "Player":
			jugador_cerca = true
			print(jugador_cerca)
			print("Presiona el CLikc Izquierdo para Abrir")
			$flecha.visible = true
			iniciar_animacion_flecha()
		pass # Replace with function body.

func iniciar_animacion_flecha():
	# 1. Si ya había una animación, la matamos para no sobreponerlas
	if tween_flote and tween_flote.is_running():
		tween_flote.kill()
		
	# 2. Creamos el Tween y le decimos .set_loops() para que sea INFINITO
	tween_flote = create_tween().set_loops()
	
	# 3. Subimos la flecha 10 píxeles (en Godot, ir hacia arriba es restar en Y)
	# Usamos TRANS_SINE para que el movimiento sea suave y no robótico
	tween_flote.tween_property($flecha, "position:y", posicion_y_original - 10, 0.5).set_trans(Tween.TRANS_SINE)
	
	# 4. Bajamos la flecha a su posición original
	tween_flote.tween_property($flecha, "position:y", posicion_y_original, 0.5).set_trans(Tween.TRANS_SINE)

func detener_animacion_flecha():
	# Detenemos el Tween cuando el jugador se aleja
	if tween_flote and tween_flote.is_running():
		tween_flote.kill()
	
	# Reseteamos la posición por si el jugador se fue justo cuando la flecha estaba arriba
	$flecha.position.y = posicion_y_original
