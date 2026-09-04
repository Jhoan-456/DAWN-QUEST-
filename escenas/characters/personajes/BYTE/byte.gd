extends CharacterBody2D

@export_group("CARACTERISTICAS DE BYTE")
@export var speed: float = 130.0
@export var texto_flotante_scene: PackedScene
@export var radio_aim_assist: float = 250.0 # Distancia máxima en píxeles para apuntar solo
var esta_envenenado: bool = false
signal stats_cambiadas

#====================================================================
@export_group("ATRIBUTOS DEL BYTE")
@export var vida :float = 160
@export var Escudo :float = 150
@export var Energia :float = 400
@export var fuerza: int = 5
@export var inteligencia: int = 9
@export var Velocidad_ataque : float = 6.5	
@export var Velocidad_proyectil: float = 14.0
@export var Velocidad_movimiento: float = 10.0
@export var Probabilidad_crítico: float = 1.5
@export var Suerte : float = 1.2
@export var Bateria_Portatil : PackedScene # Item Inicial (activo)
# → Al usarla recarga instantáneamente la pasiva y da un pequeño escudo.
# PASIVA - SOBRE-CARGA	
#==========================================================================

@export_group("VIDA MAXIMO DE BYTE")
@export var max_vida :float = 160
@export var max_escudo :float = 150
@export var max_energia :float = 400
#=====================================================================

# --- DATOS DEL ARMA EQUIPADA ---
var escena_bala_actual : PackedScene = null # 👈 Guarda la bala del arma que tienes en la mano
var dano_calculado: float = 10.0
var cadencia_calculada: float = 0.5
var vel_proyectil_calculada: float = 0.0
var prob_critico_calculada: float = 0.0
var costo_energia_actual: float = 5.0

# Efectos de estado transferibles del arma
var aplica_quemadura: bool = false
var duracion_quemadura: float = 0.0

var Moneda = 0
var joystick : Joystick
var ping_actual : int = 30
var enemigo_mas_cercano: Node2D = null
var puede_disparar: bool = true
var tiene_arma = false

@onready var texto_moneda = $UI/LabelMoneda
@onready var texto_fps = $UI/fps
@onready var texto_version = $UI/Version
@onready var texto_segundos = $UI/segund_efect
@onready var texto_internet = $UI/LabelInternet

@export var escena_pausa = preload("res://escenas/characters/menu/menuPausa.tscn")


func _ready() -> void:
	add_to_group("jugador")
	texto_fps.visible = Datos.fps_visibles
	texto_version.visible = Datos.version_visible
	texto_version.text = "VERSION: " + Datos.version_juego


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
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "idle"
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
	
	if tiene_arma and puede_disparar and Energia >= costo_energia_actual and Input.is_action_pressed("interactuar"):
		disparar()


func equipar_arma(nodo_arma: Node2D) -> void:
	tiene_arma = true
	$ArmaVisual.visible = true
	
	# 🎨 CAMBIAR LA TEXTURA VISUAL DEL ARMA EN MANO
	if "textura_normal" in nodo_arma and nodo_arma.textura_normal != null:
		$ArmaVisual.texture = nodo_arma.textura_normal
	
	# Guardamos la escena de la bala del arma recogida
	if "escena_bala" in nodo_arma:
		escena_bala_actual = nodo_arma.escena_bala
	
	if "costo_energia" in nodo_arma:
		costo_energia_actual = nodo_arma.costo_energia
	
	recalcular_atributos_por_clase(nodo_arma)
	print("¡Arma equipada correctamente!")


func recalcular_atributos_por_clase(arma: Node2D) -> void:
	# 1. Obtener valores base del arma o usar valores por defecto seguros
	var base_dano: float = arma.dano_base if "dano_base" in arma else 5.0
	var esc_int: float = arma.escalado_inteligencia if "escalado_inteligencia" in arma else 0.0
	var esc_fuerza: float = arma.escalado_fuerza if "escalado_fuerza" in arma else 0.0
	var cad_base: float = arma.cadencia_base if "cadencia_base" in arma else 0.5
	var mult_vel_p: float = arma.multiplicador_vel_proyectil if "multiplicador_vel_proyectil" in arma else 1.0

	# 2. Reseteo general de estadísticas
	prob_critico_calculada = Probabilidad_crítico
	
	# --- EXTRAS ---
	if "aplica_quemadura" in arma:
		aplica_quemadura = arma.aplica_quemadura
		duracion_quemadura = arma.duracion_quemadura

	# 3. Cálculo genérico según la clase activa del arma
	if "es_clase_mago" in arma and arma.es_clase_mago:
		dano_calculado = base_dano + (inteligencia * esc_int) + (fuerza * esc_fuerza)
		cadencia_calculada = max(0.15, cad_base - (Velocidad_ataque * 0.03))
		vel_proyectil_calculada = (Velocidad_proyectil * 30.0) * mult_vel_p

	elif "es_clase_mele" in arma and arma.es_clase_mele:
		dano_calculado = base_dano + (fuerza * esc_fuerza) + (inteligencia * esc_int)
		cadencia_calculada = max(0.1, cad_base - (Velocidad_ataque * 0.04))
		vel_proyectil_calculada = 0.0

	elif "es_clase_rango" in arma and arma.es_clase_rango:
		dano_calculado = base_dano + (fuerza * esc_fuerza)
		cadencia_calculada = max(0.1, cad_base - (Velocidad_ataque * 0.05))
		vel_proyectil_calculada = (Velocidad_proyectil * 35.0) * mult_vel_p
		prob_critico_calculada = Probabilidad_crítico * 1.2

	elif "es_clase_invocador" in arma and arma.es_clase_invocador:
		dano_calculado = base_dano + (inteligencia * esc_int) + (Suerte * 1.5)
		cadencia_calculada = max(0.2, cad_base)
		vel_proyectil_calculada = (Velocidad_proyectil * 25.0) * mult_vel_p

	print("⚔️ Arma equipada | Daño final:", dano_calculado, " | Cadencia:", cadencia_calculada, " | Vel. Proyectil:", vel_proyectil_calculada)

func disparar() -> void:
	if not escena_bala_actual:
		print("⚠️ ALERTA: Esta arma no tiene asignada una 'escena_bala' en su Inspector.")
		return

	Energia -= costo_energia_actual
	Energia = clamp(Energia, 0, max_energia)
	stats_cambiadas.emit()
	
	puede_disparar = false
	
	# Instanciamos la bala del arma actual
	var bala = escena_bala_actual.instantiate()
	get_parent().add_child(bala)
	
	bala.global_position = $ArmaVisual/puntoDisparo.global_position
	bala.rotation = $ArmaVisual.rotation
	bala.direccion_vector = Vector2.RIGHT.rotated($ArmaVisual.rotation)
	
	# Asignamos el daño calculado a la bala (con o sin Ñ)
	var es_critico = (randf() * 100.0) <= prob_critico_calculada
	var dano_final = dano_calculado * (1.5 if es_critico else 1.0)

	if "daño" in bala:
		bala.daño = dano_final
	if "dano" in bala:
		bala.dano = dano_final # 👈 Corregido: ya no dice 'bala.daño' aquí
		
	if "velocidad" in bala:
		bala.velocidad = vel_proyectil_calculada

	# Transferir efecto de quemadura si la bala lo soporta
	if "aplica_quemadura" in bala:
		bala.aplica_quemadura = aplica_quemadura
		bala.duracion_quemadura = duracion_quemadura

	aplicar_retroceso()
	
	await get_tree().create_timer(cadencia_calculada).timeout
	puede_disparar = true
func aplicar_retroceso():
	$ArmaVisual.position = Vector2(0, 0)
	var tween = create_tween()
	var retroceso_pos = $ArmaVisual.position - Vector2(10,0).rotated($ArmaVisual.rotation)
	var posicion_original = $ArmaVisual.position
	
	tween.tween_property($ArmaVisual, "position", retroceso_pos, 0.07)
	tween.tween_property($ArmaVisual, "position", posicion_original, 0.07)


func recibir_daño(cantidad: int):
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


func recibir_veneno():
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
		vida = clamp(vida, 0, max_vida)

		texto_segundos.text = "Veneno: " + str(tiempo_espera)
		crear_texto_flotante("-" + str(daño_por_tic), Color(0.6, 0.0, 0.7, 1.0))
		
		if vida <= 0:
			print("Game over por veneno")
			break

	$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
	esta_envenenado = false


func crear_texto_flotante(valor: String, color: Color) -> void:
	if not texto_flotante_scene: return
	
	var texto = texto_flotante_scene.instantiate()
	get_parent().add_child(texto)
	texto.global_position = global_position + Vector2(0, -20)
	texto.mostrar(valor, color)


func buscar_enemigo_cercano() -> Node2D:
	var lista_prioridades = ["bosses", "enemigos_dificil", "enemigos_medio", "enemigos_facil"]
	
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


func _on_ui_enviar_joystick(j: Joystick) -> void:
	joystick = j


func _on_pausar_pressed() -> void:
	var escena_a_pausa = escena_pausa.instantiate()
	get_tree().paused = true 
	add_child(escena_a_pausa)
