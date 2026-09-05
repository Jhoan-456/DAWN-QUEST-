extends CharacterBody2D

@export_group("CARACTERISTICAS DE BYTE")
@export var speed: float = 130.0
@export var texto_flotante_scene: PackedScene
@export var info_flotante_scene: PackedScene
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
#==========================================================================

@export_group("VIDA MAXIMO DE BYTE")
@export var max_vida :float = 160
@export var max_escudo :float = 150
@export var max_energia :float = 400
#=====================================================================

# --- DATOS DEL ARMA EQUIPADA ---
var escena_bala_actual : PackedScene = null
var dano_calculado: float = 10.0
var cadencia_calculada: float = 0.5
var vel_proyectil_calculada: float = 0.0
var prob_critico_calculada: float = 0.0
var costo_energia_actual: float = 5.0

# Efectos de estado transferibles del arma
var aplica_quemadura: bool = false
var duracion_quemadura: float = 0.0

var Moneda = 0
@onready var joystick: Joystick = $UI/Joystick
var ping_actual : int = 30
var enemigo_mas_cercano: Node2D = null
var puede_disparar: bool = true
var tiene_arma = false

# --- SISTEMA DE INVENTARIO (2 SLOTS) ---
var inventario_armas: Array[Dictionary] = []
var indice_arma_activa: int = 0

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
	$AnimatedSprite2D.play("idle")


func _physics_process(_delta: float) -> void:
	var direction = Vector2.ZERO

	# 1. Movimiento por Joystick (si existe y está instanciado)
	if joystick != null and is_instance_valid(joystick):
		direction = joystick.direc

	# 2. Movimiento por Teclado
	if Input.is_action_pressed("mover_derecha"):
		direction.x += 1
	if Input.is_action_pressed("mover_izquierda"):
		direction.x -= 1
	if Input.is_action_pressed("mover_arriba"):
		direction.y -= 1
	if Input.is_action_pressed("mover_abajo"):
		direction.y += 1

	# Teclas de atajo / depuración
	if Input.is_action_just_pressed("F3"):
		Datos.fps_visibles = not Datos.fps_visibles
		Datos.version_visible = not Datos.version_visible

	# 🔄 3. CAMBIAR DE ARMA (Al presionar la C o la acción configurada)
	if Input.is_action_just_pressed("cambiar_arma") or Input.is_action_just_pressed("c"):
		intercambiar_arma()
		
	# 4. Aplicar velocidad
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
		$AnimatedSprite2D.play()
		$AnimatedSprite2D.animation = "idle"
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()

	# Orientación por movimiento
	if velocity.x != 0:
		actualizar_orientacion_espaldas(velocity.x < 0)

	# 5. Apuntado, rotación del arma y volteo de la espalda
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
			var mirar_izquierda = abs(angulo_apuntado) > PI/2
			$ArmaVisual.flip_v = mirar_izquierda
			actualizar_orientacion_espaldas(mirar_izquierda)

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


# --- LÓGICA DE INVENTARIO Y EQUIPAR ARMAS ---

func equipar_arma(nodo_arma: Node2D) -> void:
	var datos_arma = {
		"nombre": nodo_arma.nombre_arma if "nombre_arma" in nodo_arma else nodo_arma.name,
		"textura": nodo_arma.textura_normal if "textura_normal" in nodo_arma else null,
		"escena_bala": nodo_arma.escena_bala if "escena_bala" in nodo_arma else null,
		"costo_energia": nodo_arma.costo_energia if "costo_energia" in nodo_arma else 5.0,
		"dano_base": nodo_arma.dano_base if "dano_base" in nodo_arma else 5.0,
		"esc_int": nodo_arma.escalado_inteligencia if "escalado_inteligencia" in nodo_arma else 0.0,
		"esc_fuerza": nodo_arma.escalado_fuerza if "escalado_fuerza" in nodo_arma else 0.0,
		"cad_base": nodo_arma.cadencia_base if "cadencia_base" in nodo_arma else 0.5,
		"mult_vel_p": nodo_arma.multiplicador_vel_proyectil if "multiplicador_vel_proyectil" in nodo_arma else 1.0,
		"es_mago": nodo_arma.es_clase_mago if "es_clase_mago" in nodo_arma else false,
		"es_mele": nodo_arma.es_clase_mele if "es_clase_mele" in nodo_arma else false,
		"es_rango": nodo_arma.es_clase_rango if "es_clase_rango" in nodo_arma else false,
		"es_invocador": nodo_arma.es_clase_invocador if "es_clase_invocador" in nodo_arma else false,
		"aplica_quemadura": nodo_arma.aplica_quemadura if "aplica_quemadura" in nodo_arma else false,
		"duracion_quemadura": nodo_arma.duracion_quemadura if "duracion_quemadura" in nodo_arma else 0.0,
		"escena_suelo_path": nodo_arma.scene_file_path
	}

	if inventario_armas.size() < 2:
		inventario_armas.append(datos_arma)
		indice_arma_activa = inventario_armas.size() - 1
	else:
		soltar_arma_actual_al_suelo()
		inventario_armas[indice_arma_activa] = datos_arma

	activar_arma_actual()
	print("⚔️ Total de armas guardadas en inventario:", inventario_armas.size())


func intercambiar_arma() -> void:
	if inventario_armas.size() < 2:
		crear_info_flotante("Solo 1 arma equipada", Color(0.8, 0.8, 0.8))
		return
	
	indice_arma_activa = 1 - indice_arma_activa
	activar_arma_actual()
	print("🔄 Cambiaste al slot de arma:", indice_arma_activa)


func activar_arma_actual() -> void:
	if inventario_armas.is_empty():
		tiene_arma = false
		$ArmaVisual.visible = false
		if has_node("ArmaEspalda"):
			$ArmaEspalda.visible = false
		return

	tiene_arma = true
	$ArmaVisual.visible = true

	# 1. MOSTRAR ARMA ACTIVA EN LA MANO
	var arma = inventario_armas[indice_arma_activa]

	if "textura" in arma and arma["textura"] != null:
		$ArmaVisual.texture = arma["textura"]

	# 2. MOSTRAR ARMA SECUNDARIA EN LA ESPALDA
	if has_node("ArmaEspalda"):
		if inventario_armas.size() > 1:
			var indice_secundario = 1 - indice_arma_activa
			var arma_secundaria = inventario_armas[indice_secundario]
			if "textura" in arma_secundaria and arma_secundaria["textura"] != null:
				$ArmaEspalda.texture = arma_secundaria["textura"]
				$ArmaEspalda.visible = true
		else:
			$ArmaEspalda.visible = false

	# 3. MOSTRAR TEXTO FLOTANTE CON EL NOMBRE
	var nombre_mostrar = arma["nombre"] if "nombre" in arma else "Arma"
	crear_info_flotante(str(nombre_mostrar), Color(1.0, 0.85, 0.2))

	# Actualizar variables de combate
	escena_bala_actual = arma["escena_bala"]
	costo_energia_actual = arma["costo_energia"]
	aplica_quemadura = arma["aplica_quemadura"]
	duracion_quemadura = arma["duracion_quemadura"]

	prob_critico_calculada = Probabilidad_crítico

	if arma["es_mago"]:
		dano_calculado = arma["dano_base"] + (inteligencia * arma["esc_int"]) + (fuerza * arma["esc_fuerza"])
		cadencia_calculada = max(0.15, arma["cad_base"] - (Velocidad_ataque * 0.03))
		vel_proyectil_calculada = (Velocidad_proyectil * 30.0) * arma["mult_vel_p"]

	elif arma["es_mele"]:
		dano_calculado = arma["dano_base"] + (fuerza * arma["esc_fuerza"]) + (inteligencia * arma["esc_int"])
		cadencia_calculada = max(0.1, arma["cad_base"] - (Velocidad_ataque * 0.04))
		vel_proyectil_calculada = 0.0

	elif arma["es_rango"]:
		dano_calculado = arma["dano_base"] + (fuerza * arma["esc_fuerza"])
		cadencia_calculada = max(0.1, arma["cad_base"] - (Velocidad_ataque * 0.05))
		vel_proyectil_calculada = (Velocidad_proyectil * 35.0) * arma["mult_vel_p"]
		prob_critico_calculada = Probabilidad_crítico * 1.2

	elif arma["es_invocador"]:
		dano_calculado = arma["dano_base"] + (inteligencia * arma["esc_int"]) + (Suerte * 1.5)
		cadencia_calculada = max(0.2, arma["cad_base"])
		vel_proyectil_calculada = (Velocidad_proyectil * 25.0) * arma["mult_vel_p"]

	print("⚔️ Arma Activa | Daño:", dano_calculado, " | Cadencia:", cadencia_calculada)


func soltar_arma_actual_al_suelo() -> void:
	var arma_a_soltar = inventario_armas[indice_arma_activa]
	if arma_a_soltar.has("escena_suelo_path") and arma_a_soltar["escena_suelo_path"] != "":
		var escena_arma = load(arma_a_soltar["escena_suelo_path"])
		if escena_arma:
			var nueva_arma_suelo = escena_arma.instantiate()
			get_parent().add_child(nueva_arma_suelo)
			nueva_arma_suelo.global_position = global_position + Vector2(25, 0)


func disparar() -> void:
	if not escena_bala_actual:
		print("⚠️ ALERTA: Esta arma no tiene asignada una 'escena_bala' en su Inspector.")
		return

	Energia -= costo_energia_actual
	Energia = clamp(Energia, 0, max_energia)
	stats_cambiadas.emit()
	
	puede_disparar = false
	
	var bala = escena_bala_actual.instantiate()
	get_parent().add_child(bala)
	
	bala.global_position = $ArmaVisual/puntoDisparo.global_position
	bala.rotation = $ArmaVisual.rotation

	# 🛠️ Verificación segura antes de asignar la dirección:
	if "direccion_vector" in bala:
		bala.direccion_vector = Vector2.RIGHT.rotated($ArmaVisual.rotation)
	
	var es_critico = (randf() * 100.0) <= prob_critico_calculada
	var dano_final = dano_calculado * (1.5 if es_critico else 1.0)

	if "daño" in bala:
		bala.daño = dano_final
	if "dano" in bala:
		bala.dano = dano_final
		
	if "velocidad" in bala:
		bala.velocidad = vel_proyectil_calculada

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
func crear_info_flotante(valor: String, color: Color) -> void:
	if not info_flotante_scene: return
	
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
func actualizar_orientacion_espaldas(mirar_izquierda: bool) -> void:
	$AnimatedSprite2D.flip_h = mirar_izquierda

	if has_node("ArmaEspalda"):
		$ArmaEspalda.flip_h = mirar_izquierda
		var pos_x_base = abs($ArmaEspalda.position.x)
		$ArmaEspalda.position.x = -pos_x_base if mirar_izquierda else pos_x_base
