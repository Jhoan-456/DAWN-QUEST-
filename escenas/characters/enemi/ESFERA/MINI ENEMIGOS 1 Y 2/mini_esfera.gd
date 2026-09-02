extends CharacterBody2D

# --- VARIABLES DE VIDA ---
@export var vida_maxima: float = 8.75
var vida_actual: float = 8.75
@export var es_mini: bool = false
@export var texto_flotante_scene: PackedScene
@export var escena_moneda: PackedScene

@onready var barra_vida = $ProgressBar 
# Esto evita que se divida 20 veces si le disparas muy rápido
var ya_se_dividio: bool = false

var dano = 3
var objetivo = null # El jugador cuando está a rango de ATAQUE
var jugador_a_perseguir = null # El jugador cuando está a rango de VISIÓN

# --- NUEVAS VARIABLES DE COOLDOWN DE ATAQUE ---
@export var tiempo_entre_ataques: float = 1.0 # Cada cuántos segundos golpea
var puede_atacar: bool = true

# --- ⏱️ CONFIGURACIÓN DE COOLDOWNS DE DISPARO ---
@export_group("Cooldowns de Disparo")
@export var cadencia_disparo: float = 0.3  # Tiempo (segundos) entre cada esfera lanzada
@export var tiempo_recarga: float = 3.0   # Tiempo (segundos) para recargar el escudo completo

# --- VARIABLES DE MOVIMIENTO ---
var velocidad_patrulla = 70
var velocidad_persecucion = 80 # Corre un poco más rápido al perseguir
var direccion = Vector2.ZERO
var tiempo_proximo_paso = 0.0

const PROYECTIL_ESCENA = preload("res://escenas/characters/enemi/ESFERA/proyectil_maligna.tscn") # <- Verifica tu ruta
var max_proyectiles: int = 5 # <- Ajustado a 5 proyectiles para la mini esfera
var proyectiles_disponibles: Array = []
var esta_recargando_proyectiles: bool = false

# 🆕 NODOS DEL ESCUDO (Asegúrate de crearlos como hijos en la escena de la mini esfera)
@onready var contenedor_proyectiles = $ContenedorProyectiles
@onready var timer_disparo_proyectil = $TimerDisparo
@onready var timer_recarga_proyectiles = $TimerRecarga


func _ready() -> void:
	add_to_group("enemigos_medio")
	vida_actual = vida_maxima
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida_actual
	
	# 🆕 Configuración de los Cooldowns en los Timers
	if timer_disparo_proyectil:
		timer_disparo_proyectil.wait_time = cadencia_disparo
		timer_disparo_proyectil.one_shot = false
		
	if timer_recarga_proyectiles:
		timer_recarga_proyectiles.wait_time = tiempo_recarga
		timer_recarga_proyectiles.one_shot = true
	
	generar_escudo_proyectiles()

# --- SEÑALES DE LA ZONA DE ATAQUE (Círculo Pequeño) ---
func _on_zona_ataque_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_daño"):
		objetivo = body
		atacar()

func _on_zona_ataque_body_exited(body: Node2D) -> void:
	if body == objetivo:
		objetivo = null 
		$visual/AnimatedSprite2D.play("idle")
		print("El jugador salió de la zona de ataque.")

func _on_timer_ataque_timeout() -> void:
	atacar()

# --- SEÑALES DE LA ZONA DE DETECCIÓN (Círculo Grande) ---
func _on_zona_deteccion_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_daño"):
		jugador_a_perseguir = body
		
		# 🆕 Si ve al jugador, tiene munición y no está recargando, ¡empieza a disparar!
		if not esta_recargando_proyectiles and timer_disparo_proyectil.is_stopped():
			timer_disparo_proyectil.start()

func _on_zona_deteccion_body_exited(body: Node2D) -> void:
	if body == jugador_a_perseguir:
		jugador_a_perseguir = null
		print("El jugador escapó de la vista.")
		
		# 🆕 Detenemos el disparo si el jugador se escapa
		timer_disparo_proyectil.stop()

# --- LÓGICA DE MOVIMIENTO ---
func _physics_process(delta: float) -> void:
	
	# ESTADO 1: ATACANDO (Jugador muy cerca)
	if objetivo != null:
		velocity = Vector2.ZERO # Se detiene para pegar
		
	# ESTADO 2: PERSIGUIENDO (Jugador a la vista, pero lejos para pegar)
	elif jugador_a_perseguir != null:
		direccion = global_position.direction_to(jugador_a_perseguir.global_position)
		velocity = direccion * velocidad_persecucion
		
		if direccion.x > 0:
			$visual.scale.x = -1
		elif direccion.x < 0:
			$visual.scale.x = 1
			
	# ESTADO 3: PATRULLANDO AL AZAR (No hay nadie cerca)
	else:
		tiempo_proximo_paso -= delta
		if is_on_wall():
			direccion = direccion * -1 
		if tiempo_proximo_paso <= 0:
			direccion = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			tiempo_proximo_paso = randf_range(1, 3)
			if $visual/AnimatedSprite2D.animation != "idle":
				$visual/AnimatedSprite2D.play("idle")
				
		velocity = direccion * velocidad_patrulla
		
		if direccion.x > 0:
			$visual.scale.x = -1
		elif direccion.x < 0:
			$visual.scale.x = 1
			
	move_and_slide()

# --- FUNCIONES DE COMBATE ---
func atacar():
	if objetivo != null and puede_atacar:
		puede_atacar = false # 1. Cerramos el candado
		
		objetivo.recibir_daño(dano)
		# 2. SISTEMA DE PROBABILIDAD (50% Veneno)
		if randf() < 0.5:
			print("¡Suerte! El golpe no te envenenó.")
		else:
			print("¡Mala suerte! Golpe venenoso.")
			if objetivo.has_method("recibir_veneno"):
				objetivo.recibir_veneno()
		
		await get_tree().create_timer(tiempo_entre_ataques).timeout
		puede_atacar = true # 3. Abrimos el candado para el próximo golpe

func _on_ataque_timeout() -> void:
	pass

func recibir_daño(cantidad: int) -> void:
	if ya_se_dividio: return 
	
	vida_actual -= cantidad
	efecto_recibir_daño()
	vida_actual = clamp(vida_actual, 0, vida_maxima)
	barra_vida.value = vida_actual
	
	if vida_actual <= 0:
		set_physics_process(false)
		morir()
	crear_texto_flotante("-"+str(cantidad),Color(0.954, 0.001, 0.0, 1.0))
func efecto_recibir_daño() -> void:
	var sprite = $visual/AnimatedSprite2D
	if not sprite: return

	# 1. Shader con mezcla (mix): le da el brillo blanco sin perder la forma ni los bordes
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		// Mezclamos el color original con blanco al 75% (0.75) para conservar el relieve
		vec3 color_impacto = mix(tex.rgb, vec3(2.0), 100);
		COLOR = vec4(color_impacto, tex.a);
	}
	"""
	mat.shader = shader
	sprite.material = mat

	# 2. El destello dura solo 0.08s para sentirse rápido y reactivo al golpe
	await get_tree().create_timer(0.05).timeout

	# 3. Quitamos el shader para restaurar el sprite normal
	if is_instance_valid(sprite):
		sprite.material = null

func morir() -> void:
	# 🆕 Al morir, limpiamos los proyectiles para que no queden flotando en el aire
	limpiar_proyectiles()
	
	# Desactivar colisiones para que no siga golpeando mientras desaparece
	if has_node("Zona_ataque"): $Zona_ataque.set_deferred("monitoring", false)
	if has_node("ZonaDeteccion"): $ZonaDeteccion.set_deferred("monitoring", false)
	if has_node("CollisionShape2D"): $CollisionShape2D.set_deferred("disabled", true)
	
	$visual/AnimatedSprite2D.play("died")
	await $visual/AnimatedSprite2D.animation_finished
	soltar_moneda()
	queue_free()

func crear_texto_flotante(valor: String, color: Color) -> void:
	if not texto_flotante_scene: return
	
	var texto = texto_flotante_scene.instantiate()
	get_parent().add_child(texto)
	texto.global_position = global_position + Vector2(0, -20)
	texto.mostrar(valor, color)

func soltar_moneda():
	var nueva_moneda = escena_moneda.instantiate()
	get_parent().add_child(nueva_moneda)
	nueva_moneda.global_position = global_position
	nueva_moneda.global_position.y -= 50


# =====================================================================
# --- 🆕 FUNCIONES DE LOS 5 PROYECTILES ---
# =====================================================================

func generar_escudo_proyectiles() -> void:
	limpiar_proyectiles()
	
	for i in range(max_proyectiles):
		var nuevo_proyectil = PROYECTIL_ESCENA.instantiate()
		contenedor_proyectiles.add_child(nuevo_proyectil)
		
		# Godot dividirá automáticamente los 360 grados entre 5 para formar un pentágono perfecto
		nuevo_proyectil.angulo_actual = (i * TAU) / max_proyectiles
		proyectiles_disponibles.append(nuevo_proyectil)

func recargar_en_secuencia() -> void:
	esta_recargando_proyectiles = true
	limpiar_proyectiles()
	
	# Aparecen los 5 proyectiles uno por uno en su posición correcta
	for i in range(max_proyectiles):
		if not is_inside_tree() or ya_se_dividio: return
		
		var nuevo_proyectil = PROYECTIL_ESCENA.instantiate()
		contenedor_proyectiles.add_child(nuevo_proyectil)
		
		nuevo_proyectil.angulo_actual = (i * TAU) / max_proyectiles
		proyectiles_disponibles.append(nuevo_proyectil)
		
		await get_tree().create_timer(0.15).timeout
		
	esta_recargando_proyectiles = false
	
	if jugador_a_perseguir and timer_disparo_proyectil.is_stopped():
		timer_disparo_proyectil.start()

func limpiar_proyectiles() -> void:
	proyectiles_disponibles.clear()
	if contenedor_proyectiles:
		for hijo in contenedor_proyectiles.get_children():
			hijo.queue_free()

# 🆕 Conecta aquí la señal 'timeout' del TimerDisparo (0.3s):
func _on_timer_disparo_timeout() -> void:
	if proyectiles_disponibles.size() > 0 and jugador_a_perseguir:
		var proyectil_a_lanzar = proyectiles_disponibles.pop_front()
		
		if is_instance_valid(proyectil_a_lanzar):
			proyectil_a_lanzar.disparar_hacia(jugador_a_perseguir.global_position)
			
		# Al llegar a 0 proyectiles, espera 3 segundos para recargar
		if proyectiles_disponibles.size() == 0:
			timer_disparo_proyectil.stop()
			timer_recarga_proyectiles.start(tiempo_recarga)

# 🆕 Conecta aquí la señal 'timeout' del TimerRecarga (3.0s):
func _on_timer_recarga_timeout() -> void:
	recargar_en_secuencia()
