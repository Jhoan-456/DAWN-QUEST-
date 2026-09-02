extends CharacterBody2D

@export var speed: float = 130.0
@export var texto_flotante_scene: PackedScene
var esta_envenenado: bool = false
signal stats_cambiadas

#------------------------------------------------------
var vida : float = 20.0
var Escudo : float = 20.0
var Energia : float = 150.0
var max_vida : float = 20.0
var max_escudo : float = 20.0
var max_energia : float = 150.0
var Moneda = 0
var joystick : Joystick
var ping_actual : int = 30

# Variable para almacenar el costo de energía del arma actual
var costo_energia_actual: float = 1.0

#------------------------------------------------------
@export var radio_aim_assist: float = 250.0 # Distancia máxima en píxeles para apuntar solo
var enemigo_mas_cercano: Node2D = null

#------------------------------------------------------
var puede_disparar: bool = true
var tiene_arma = false
@export var escena_bala : PackedScene

#------------------------------------------------------
@onready var texto_moneda = $UI/LabelMoneda
@onready var texto_fps = $UI/fps
@onready var texto_version = $UI/Version
@onready var texto_segundos = $UI/segund_efect
@onready var texto_internet = $UI/LabelInternet

#------------------------------------------------------
@export var escena_pausa = preload("res://escenas/characters/menu/menuPausa.tscn")

#-------------------------------------------------------
func _ready() -> void:
	add_to_group("jugador")
	texto_fps.visible = Datos.fps_visibles
	texto_version.visible = Datos.version_visible
	texto_version.text = "VERSION: " + Datos.version_juego
	$AnimatedSprite2D.play("idle")

func _physics_process(_delta: float) -> void:
	var direction = Vector2.ZERO
	if joystick != null and is_instance_valid(joystick):
		direction = joystick.direc
		if Input.is_action_pressed("mover_derecha"):
			direction.x += 1
		if Input.is_action_pressed("mover_izquierda"):
			direction.x -= 1
		if Input.is_action_pressed("mover_arriba"):
			direction.y -= 1
		if Input.is_action_pressed("mover_abajo"):
			direction.y += 1
		
		if Input.is_action_just_pressed("F3"):
			Datos.fps_visibles = not Datos.fps_visibles
			Datos.version_visible = not Datos.version_visible
		
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
		$AnimatedSprite2D.play("idle")
		if direction.x != 0:
			$AnimatedSprite2D.flip_h = direction.x < 0
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()

	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
	
	if tiene_arma:
		enemigo_mas_cercano = buscar_enemigo_cercano()
		var angulo_apuntado: float = 0.0
		var debe_rotar_arma: bool = false
		
		if enemigo_mas_cercano != null and is_instance_valid(enemigo_mas_cercano):
			var vector_direccion = enemigo_mas_cercano.global_position - global_position
			angulo_apuntado = vector_direccion.angle()
			debe_rotar_arma = true
			
		elif velocity.length() > 0:
			angulo_apuntado = velocity.angle()
			debe_rotar_arma = true
			
		if debe_rotar_arma:
			$ArmaVisual.rotation = angulo_apuntado
			if abs(angulo_apuntado) > PI/2:
				$ArmaVisual.flip_v = true
				$AnimatedSprite2D.flip_h = true
			else:
				$ArmaVisual.flip_v = false
				$AnimatedSprite2D.flip_h = false

	move_and_slide()

#------------------------------------------------------
func _process(_delta: float) -> void:
	if texto_fps.visible:
		var fps: int = Engine.get_frames_per_second()
		texto_fps.text = "FPS: " + str(fps)
		if fps <= 10:
			texto_fps.modulate = Color(1.0, 0.0, 0.0, 1.0)
		elif fps == 60:
			texto_fps.modulate = Color(0.0, 0.973, 0.339, 1.0)
		elif fps == 100:
			texto_fps.modulate = Color(1.0, 1.0, 1.0, 1.0)
		elif fps > 100:
			texto_fps.modulate = Color(0.4, 0.898, 1.0, 1.0)
	
	texto_moneda.text = "Monedas: " + str(Moneda)
	
	var costo_actual = obtener_costo_energia_actual()
	if tiene_arma and puede_disparar and Energia >= costo_actual and Input.is_action_pressed("interactuar"):
		disparar()

func obtener_costo_energia_actual() -> float:
	return costo_energia_actual

#------------------------------------------------------
func equipar_arma(costo: float = 1.0) -> void:
	tiene_arma = true
	costo_energia_actual = costo
	$ArmaVisual.visible = true
	print("¡Arma equipada con costo de energía: ", costo_energia_actual, "!")

#------------------------------------------------------
func disparar() -> void:
	var costo = obtener_costo_energia_actual()
	
	Energia -= costo
	Energia = clamp(Energia, 0, max_energia)
	stats_cambiadas.emit()
	
	puede_disparar = false 
	var bala = escena_bala.instantiate()
	get_parent().add_child(bala)
	
	bala.global_position = $ArmaVisual/puntoDisparo.global_position
	bala.rotation = $ArmaVisual.rotation
	bala.direccion_vector = Vector2.RIGHT.rotated($ArmaVisual.rotation)
	
	aplicar_retroceso()
	await get_tree().create_timer(0.7).timeout
	puede_disparar = true

#------------------------------------------------------------------------
func aplicar_retroceso() -> void:
	$ArmaVisual.position = Vector2(0, 0)
	var tween = create_tween()
	var retroceso_pos = $ArmaVisual.position - Vector2(10, 0).rotated($ArmaVisual.rotation)
	var posicion_original = $ArmaVisual.position
	
	tween.tween_property($ArmaVisual, "position", retroceso_pos, 0.07)
	tween.tween_property($ArmaVisual, "position", posicion_original, 0.07)

#---------------------------------------------------------------------------------------------------
func actualizar_visual_ping(ms: int) -> void:
	var texto_estrellas = ""
	var color_ping = Color.WHITE

	if ms <= 50:
		texto_estrellas = "*****"
		color_ping = Color(0.0, 0.973, 0.339, 1.0)
	elif ms <= 100:
		texto_estrellas = "****"
		color_ping = Color(0.6, 0.9, 0.2, 1.0)
	elif ms <= 150:
		texto_estrellas = "***"
		color_ping = Color(1.0, 0.8, 0.0, 1.0)
	elif ms <= 250:
		texto_estrellas = "**"
		color_ping = Color(1.0, 0.5, 0.0, 1.0)
	else:
		texto_estrellas = "*"
		color_ping = Color(1.0, 0.0, 0.0, 1.0)

	texto_internet.text = "Ping: " + texto_estrellas
	texto_internet.modulate = color_ping

#---------------------------------------------------------------------------------------------------
func recibir_daño(cantidad: int) -> void:
	$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if Escudo > 0:
		var daño_al_escudo = min(cantidad, Escudo)
		Escudo -= daño_al_escudo
		efecto_recibir_daño()
		cantidad -= daño_al_escudo
		crear_texto_flotante("-" + str(daño_al_escudo), Color(0.561, 0.561, 0.561, 1.0))
		stats_cambiadas.emit()
	
	if cantidad > 0:
		$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
		vida -= cantidad
		vida = clamp(vida, 0 , max_vida)
		efecto_recibir_daño()
		stats_cambiadas.emit()
		crear_texto_flotante("-" + str(cantidad), Color(0.874, 0.0, 0.254, 1.0))
		
		if vida <= 0:
			vida = 0
			print("Game over")

func efecto_recibir_daño() -> void:
	var sprite = $AnimatedSprite2D
	if not sprite: return

	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		vec3 color_impacto = mix(tex.rgb, vec3(2.0), 100);
		COLOR = vec4(color_impacto, tex.a);
	}
	"""
	mat.shader = shader
	sprite.material = mat

	await get_tree().create_timer(0.05).timeout

	if is_instance_valid(sprite):
		sprite.material = null

#------------------------------------------------------
func _on_ui_enviar_joystick(j: Joystick) -> void:
	joystick = j

#---------------------------------------------------------------------------
func crear_texto_flotante(valor: String, color: Color) -> void:
	if not texto_flotante_scene: return
	
	var texto = texto_flotante_scene.instantiate()
	get_parent().add_child(texto)
	texto.global_position = global_position + Vector2(0, -20)
	texto.mostrar(valor, color)

#---------------------------------------------------------------------------
func recibir_veneno() -> void:
	if esta_envenenado: return 
	esta_envenenado = true
	$AnimatedSprite2D.modulate = Color(0.564, 0.349, 0.87, 1.0)

	var tics_totales = 3
	var daño_por_tic = 1
	var tiempo_espera = 1

	for i in range(tics_totales):
		stats_cambiadas.emit()
		await get_tree().create_timer(tiempo_espera).timeout
		
		vida -= daño_por_tic
		vida = clamp(vida, 0, 20)

		texto_segundos.text = "Veneno: " + str(tiempo_espera)
		crear_texto_flotante("-" + str(daño_por_tic), Color(0.6, 0.0, 0.7, 1.0))
		
		if vida <= 0:
			print("Game over por veneno")
			break

	$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
	esta_envenenado = false

#---------------------------------------------------------------------------
func buscar_enemigo_cercano() -> Node2D:
	var lista_prioridades = [
		"bosses",
		"enemigos_dificil",
		"enemigos_medio",
		"enemigos_facil"
	]
	
	for grupo in lista_prioridades:
		var lista_enemigos = get_tree().get_nodes_in_group(grupo)
		var enemigo_mas_cercano_del_grupo: Node2D = null
		var distancia_minima: float = radio_aim_assist
		
		for enemigo in lista_enemigos:
			if is_instance_valid(enemigo):
				var distancia = global_position.distance_to(enemigo.global_position)
				if distancia <= distancia_minima:
					distancia_minima = distancia
					enemigo_mas_cercano_del_grupo = enemigo
		
		if enemigo_mas_cercano_del_grupo != null:
			return enemigo_mas_cercano_del_grupo

	return null

#---------------------------------------------------------------------------
func _on_pausar_pressed() -> void:
	var escena_a_pausa = escena_pausa.instantiate()
	get_tree().paused = true 
	add_child(escena_a_pausa)
