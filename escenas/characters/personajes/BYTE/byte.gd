extends CharacterBody2D

@export_group("CARACTERISTICAS DE BYTE")
@export var speed: float = 130.0
@export var texto_flotante_scene: PackedScene
@export var info_flotante_scene: PackedScene
@export var radio_aim_assist: float = 250.0 # Distancia máxima en píxeles para apuntar solo
var esta_envenenado: bool = false
signal stats_cambiadas

# 📡 Variable sincronizada por red para suavizar movimiento (Lerp)
var sync_position: Vector2 = Vector2.ZERO

func _enter_tree() -> void:
	var id_jugador = name.to_int()
	
	# Si el nombre es un número (multijugador), asigna ese ID
	if id_jugador != 0:
		set_multiplayer_authority(id_jugador)
	# Si no es un número (prueba local con F6), asigna tu propio ID actual
	else:
		set_multiplayer_authority(multiplayer.get_unique_id())
		
# Transmite la textura del arma equipada a todas las pantallas
@rpc("any_peer", "call_local", "reliable")
func sincronizar_arma_visual_rpc(ruta_textura: String) -> void:
	if ruta_textura != "":
		$ArmaVisual.texture = load(ruta_textura)
		$ArmaVisual.visible = true
	else:
		$ArmaVisual.visible = false
		
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

# =====================================================================
# ⚡ PASIVA: SOBRECARGA
# =====================================================================
@export var pasiva_sobrecarga_lista: bool = false
@export var tiempo_pasiva_acumulado: float = 0.0
const TIEMPO_PASIVA: float = 8.0 # Cada 8 segundos

# =====================================================================
# 🔋 ACTIVO: BATERÍA PORTÁTIL (Escudo Físico Area2D)
# =====================================================================
@export var cooldown_activo: float = 10.0 # Tiempo de recarga de la habilidad activa
@export var escudo_bateria: float = 100.0 # Vida que tiene la burbuja de escudo

# Referencias a los nuevos nodos
@onready var burbuja_escudo = $BurbujaEscudo
@onready var escudo_visual = $BurbujaEscudo/AnimatedSprite2D

@export var boton_habilidad: TouchScreenButton 
@export var barra_recarga: TextureProgressBar # <--- NUEVO: La barra circular que creaste

var activo_listo: bool = true
var tiempo_activo_acumulado: float = 0.0
var vida_actual_escudo: float = 0.0 # Vida independiente del escudo de burbuja
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
var duracion_quemadura: float = 1.0

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
	sync_position = global_position
	$aro_energia.visible = false
	if has_node("activo-recarga"):
		$"activo-recarga".visible = false
	
	# Asegurarnos de que el escudo empiece apagado al iniciar
	if burbuja_escudo:
		burbuja_escudo.visible = false
		burbuja_escudo.set_deferred("monitorable", false)
		burbuja_escudo.set_deferred("monitoring", false)
	
	# Desactivar la UI y Cámara de los personajes que pertenecen a otros jugadores
	if not is_multiplayer_authority():
		if has_node("UI"):
			$UI.visible = false
		if has_node("Camera2D"):
			$Camera2D.enabled = false
		return

	# Configuración normal para el personaje local
	if has_node("Camera2D"):
		$Camera2D.enabled = true
	texto_fps.visible = Datos.fps_visibles
	texto_version.visible = Datos.version_visible
	texto_version.text = Datos.version_juego
	$AnimatedSprite2D.play("idle")


func _physics_process(delta: float) -> void:
	# 🟢 1. JUGADOR LOCAL (Tú controlas este personaje)
	if is_multiplayer_authority():
		var direction = Vector2.ZERO

	# Movimiento por Joystick
		if joystick != null and is_instance_valid(joystick):
			direction = joystick.direc

		# Movimiento por Teclado
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

		# Cambiar de arma
		if Input.is_action_just_pressed("cambiar_arma") or Input.is_action_just_pressed("c"):
			intercambiar_arma()
			
		if direction != Vector2.ZERO:
			var velocidad_total = speed + Velocidad_movimiento
			velocity = direction.normalized() * velocidad_total
			$AnimatedSprite2D.play()
			$AnimatedSprite2D.animation = "idle"
		else:
			velocity = Vector2.ZERO
			$AnimatedSprite2D.play("idle")

		# Orientación por movimiento
		if velocity.x != 0:
			actualizar_orientacion_espaldas(velocity.x < 0)

		# Apuntado, rotación del arma y volteo de la espalda
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
		
		# Guardamos la posición local para transmitirla a los demás
		sync_position = global_position

	# 🟡 2. JUGADOR REMOTO (Otro jugador en la red)
	else:
		var pos_anterior = global_position
		# Desplazamiento fluido cuadro a cuadro (Interpolación)
		global_position = global_position.lerp(sync_position, 25.0 * delta)
		
		# Animar al jugador remoto según la distancia recorrida
		var movimiento_real = global_position - pos_anterior
		if movimiento_real.length() > 0.1:
			$AnimatedSprite2D.play("idle")
			if movimiento_real.x != 0:
				actualizar_orientacion_espaldas(movimiento_real.x < 0)
		else:
			$AnimatedSprite2D.stop()


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	# --- ⚡ RECARGA DE LA PASIVA (Cada 8 segundos) ---
	if not pasiva_sobrecarga_lista:
		tiempo_pasiva_acumulado += _delta
		if tiempo_pasiva_acumulado >= TIEMPO_PASIVA:
			pasiva_sobrecarga_lista = true
			tiempo_pasiva_acumulado = 0.0
			crear_info_flotante("⚡ ¡Sobrecarga Lista!", Color(1.0, 0.9, 0.2))
			

	# --- 🔋 RECARGA VISUAL DE LA HABILIDAD (Estilo Soul Knight) ---
	if not activo_listo:
		tiempo_activo_acumulado += _delta
		
		if barra_recarga:
			var tiempo_restante = cooldown_activo - tiempo_activo_acumulado
			var porcentaje = (tiempo_restante / cooldown_activo) * 100.0
			barra_recarga.value = porcentaje

		if tiempo_activo_acumulado >= cooldown_activo:
			activo_listo = true
			tiempo_activo_acumulado = 0.0
			if barra_recarga:
				barra_recarga.value = 0 # Quita la capa oscura por completo
			crear_info_flotante("🔋 ¡Batería Lista!", Color(0.2, 1.0, 0.4))

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
	
	# ⚔️ LÓGICA DE DISPARO E INVOCACIÓN
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
		"escena_suelo_path": nodo_arma.scene_file_path,
		"limite_max": nodo_arma.limite_max if "limite_max" in nodo_arma else 3,
		"escenas_balas": nodo_arma.escenas_balas if "escenas_balas" in nodo_arma else []
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
	crear_info_flotante(str(nombre_mostrar), Color(0.2, 0.853, 1.0, 1.0))

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
	
	# 🔄 AL FINAL DE LA FUNCIÓN: Sincronizar con los demás
	if inventario_armas.is_empty():
		sincronizar_arma_visual_rpc.rpc("")
	else:	
		arma = inventario_armas[indice_arma_activa]
		if "textura" in arma and arma["textura"] != null:
			sincronizar_arma_visual_rpc.rpc(arma["textura"].resource_path)


func soltar_arma_actual_al_suelo() -> void:
	var arma_a_soltar = inventario_armas[indice_arma_activa]
	if arma_a_soltar.has("escena_suelo_path") and arma_a_soltar["escena_suelo_path"] != "":
		var escena_arma = load(arma_a_soltar["escena_suelo_path"])
		if escena_arma:
			var nueva_arma_suelo = escena_arma.instantiate()
			get_parent().add_child(nueva_arma_suelo)
			nueva_arma_suelo.global_position = global_position + Vector2(25, 0)


func disparar() -> void:
	if inventario_armas.is_empty():
		return

	var arma_actual = inventario_armas[indice_arma_activa]
	var es_invocacion = arma_actual.get("es_invocador", false)

	# 🎲 1. SELECCIÓN DE ESCENA (Aleatoria si tiene variantes como Libro de Agua, o bala por defecto)
	var escena_a_instanciar: PackedScene = escena_bala_actual
	var lista_variantes = arma_actual.get("escenas_balas", [])
	if lista_variantes.size() > 0:
		escena_a_instanciar = lista_variantes.pick_random()

	if not escena_a_instanciar:
		return

	# 🧚‍♂️ 2. CONTROL DE INVOCACIONES POR JUGADOR
	if es_invocacion:
		var maximo_permitido: int = arma_actual.get("limite_max", 3)
		var mis_hadas: Array = []
		for node in get_tree().get_nodes_in_group("hada_jugador"):
			if is_instance_valid(node):
				var es_mio = ("jugador" in node and node.jugador == self) or (node.get_multiplayer_authority() == get_multiplayer_authority())
				if es_mio:
					mis_hadas.append(node)
		
		while mis_hadas.size() >= maximo_permitido:
			var hada_vieja = mis_hadas.pop_front()
			if is_instance_valid(hada_vieja):
				hada_vieja.queue_free()

	# 3. CONSUMO Y ESTADOS
	Energia -= costo_energia_actual
	Energia = clamp(Energia, 0, max_energia)
	stats_cambiadas.emit()
	
	puede_disparar = false
	
	# 4. INSTANCIAR Y POSICIONAR PROYECTIL / INVOCACIÓN
	var bala = escena_a_instanciar.instantiate()
	get_parent().add_child(bala)
	
	if es_invocacion:
		# Las invocaciones nacen cerca con desfase para no encimarse
		var desfase = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		bala.global_position = global_position + desfase
	else:
		# Los disparos normales salen desde el punto de disparo del arma
		bala.global_position = $ArmaVisual/puntoDisparo.global_position
		bala.rotation = $ArmaVisual.rotation

	# 5. MULTIJUGADOR Y VECTORES
	if "jugador" in bala:
		bala.jugador = self
	bala.set_multiplayer_authority(get_multiplayer_authority())

	if "direccion_vector" in bala:
		bala.direccion_vector = Vector2.RIGHT.rotated($ArmaVisual.rotation)
	
	# 6. CÁLCULO DE DAÑO Y PASIVAS
	var es_critico = (randf() * 100.0) <= prob_critico_calculada
	var dano_final = dano_calculado * (1.5 if es_critico else 1.0)
	
	var es_no_fisico = not arma_actual.get("es_mele", false)

	var aplico_sobrecarga: bool = false
	if pasiva_sobrecarga_lista and es_no_fisico:
		dano_final *= 1.30
		aplico_sobrecarga = true
		pasiva_sobrecarga_lista = false 
		tiempo_pasiva_acumulado = 0.0

	if "daño" in bala:
		bala.daño = dano_final
	if "dano" in bala:
		bala.dano = dano_final
		
	if aplico_sobrecarga:
		if "es_electrico" in bala:
			bala.es_electrico = true
		crear_texto_flotante("⚡ +30%", Color(1.0, 0.9, 0.2))
		
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


# --- FUNCIÓN DE DAÑO DIRECTO AL JUGADOR ---
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

# --- NUEVAS FUNCIONES PARA EL ESCUDO BURBUJA ---
func recibir_dano_escudo(cantidad: int) -> void:
	if vida_actual_escudo <= 0: return # Ya está roto
	
	vida_actual_escudo -= cantidad
	crear_texto_flotante("🛡️ -" + str(cantidad), Color(0.2, 0.8, 1.0))
	
	if vida_actual_escudo <= 0:
		romper_escudo_visual()

func romper_escudo_visual() -> void:
	if burbuja_escudo:
		burbuja_escudo.set_deferred("monitorable", false)
		burbuja_escudo.set_deferred("monitoring", false)
	
	if escudo_visual:
		escudo_visual.play("destruccion")
		await escudo_visual.animation_finished
		burbuja_escudo.visible = false

# ------------------------------------------------

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
	
	var texto = info_flotante_scene.instantiate()
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
		
		if mirar_izquierda:
			$ArmaEspalda.position.x = 4            # Posición al mirar a la izquierda
			$ArmaEspalda.rotation_degrees = 45     # Invierte la diagonal a 45°
		else:
			$ArmaEspalda.position.x = -4           # Posición al mirar a la derecha
			$ArmaEspalda.rotation_degrees = -45    # Inclinación diagonal normal (-45°)


# =====================================================================
# HABILIDAD ACTIVA
# =====================================================================
func usar_bateria_portatil() -> void:
	if not is_multiplayer_authority() or not activo_listo:
		return

	activo_listo = false
	tiempo_activo_acumulado = 0.0
	
	$aro_energia.visible = true
	if barra_recarga:
		barra_recarga.value = 100 # Se llena de oscuridad al activarse

	# 1. Recargar Pasiva Instantáneamente
	pasiva_sobrecarga_lista = true
	tiempo_pasiva_acumulado = 0.0
	
	# 2. Activar la Burbuja Física
	if burbuja_escudo and escudo_visual:
		vida_actual_escudo = escudo_bateria # Le da vida equivalente a la estadística 'escudo_bateria'
		burbuja_escudo.visible = true
		burbuja_escudo.set_deferred("monitorable", true)
		burbuja_escudo.set_deferred("monitoring", true)
		escudo_visual.play("activo")

	crear_info_flotante("🛡️ Escudo Desplegado | Pasiva Lista!", Color(0.2, 0.8, 1.0))
