extends CharacterBody2D

# --- VARIABLES DE VIDA ---
@export var vida_maxima: float = 15.0
var vida_actual: float = 15.0
@export var es_mini: bool = false

@export var texto_flotante_scene: PackedScene
@onready var barra_vida = $ProgressBar 

@export var escena_moneda: PackedScene
# Esto evita que se divida 20 veces si le disparas muy rápido
var ya_se_dividio: bool = false

var dano = 2
var objetivo = null # El jugador cuando está a rango de ATAQUE
var jugador_a_perseguir = null # El jugador cuando está a rango de VISIÓN

# --- NUEVAS VARIABLES DE COOLDOWN DE ATAQUE ---
@export var tiempo_entre_ataques: float = 1.0 # Cada cuántos segundos golpea
var puede_atacar: bool = true

# --- VARIABLES DE MOVIMIENTO ---
var velocidad_patrulla = 80
var velocidad_persecucion = 100 # Corre un poco más rápido al perseguir
var direccion = Vector2.ZERO
var tiempo_proximo_paso = 0.0

func _ready() -> void:
	add_to_group("enemigos_facil")
	vida_actual = vida_maxima
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida_actual

# --- SEÑALES DE LA ZONA DE ATAQUE (Círculo Pequeño) ---
func _on_zona_ataque_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_daño"):
		objetivo = body
		# Quitamos el ataque inmediato de aquí para que lo controle el _physics_process

func _on_zona_ataque_body_exited(body: Node2D) -> void:
	if body == objetivo:
		objetivo = null 
		$visual/AnimatedSprite2D.play("idle")
		print("El jugador salió de la zona de ataque.")

func _on_timer_ataque_timeout() -> void:
	# Puedes borrar este nodo Timer de tu escena si quieres, ya no es necesario
	pass

# --- SEÑALES DE LA ZONA DE DETECCIÓN (Círculo Grande) ---
func _on_zona_deteccion_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_daño"):
		jugador_a_perseguir = body
		$visual/AnimatedSprite2D.play("ataque")

func _on_zona_deteccion_body_exited(body: Node2D) -> void:
	if body == jugador_a_perseguir:
		jugador_a_perseguir = null
		print("El jugador escapó de la vista.")

# --- LÓGICA DE MOVIMIENTO Y ATAQUE ---
func _physics_process(delta: float) -> void:
	
	# ESTADO 1: ATACANDO (Jugador muy cerca)
	if objetivo != null:
		velocity = Vector2.ZERO # Se detiene para pegar
		
		# SI EL CANDADO ESTÁ ABIERTO, ATACA
		if puede_atacar:
			atacar()
		
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
	if vida_actual == 0:
		puede_atacar = false
	move_and_slide()

# --- FUNCIONES DE COMBATE ---
func atacar():
	if objetivo != null and puede_atacar:
		puede_atacar = false # 1. Cerramos el candado
		objetivo.recibir_daño(dano)
		# 2. Esperamos el tiempo configurado (ej: 1 segundo)
		await get_tree().create_timer(tiempo_entre_ataques).timeout
		puede_atacar = true # 3. Abrimos el candado para el próximo golpe

func _on_ataque_timeout() -> void:
	pass

func recibir_daño(cantidad: int) -> void:
	if ya_se_dividio: return 
	$visual/AnimatedSprite2D.play("daño")
	vida_actual -= cantidad
	efecto_recibir_daño()
	vida_actual = clamp(vida_actual, 0, vida_maxima)
	barra_vida.value = vida_actual 
	crear_texto_flotante("-"+str(cantidad), Color(0.954, 0.001, 0.0, 1.0))
	
	if vida_actual <= 0:
		set_physics_process(false)
		morir()
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
	$visual/AnimatedSprite2D.play("died")
	await $visual/AnimatedSprite2D.animation_finished
	queue_free()

func crear_texto_flotante(valor: String, color: Color) -> void:
	if not texto_flotante_scene: return
	var texto = texto_flotante_scene.instantiate()
	get_parent().add_child(texto)
	texto.global_position = global_position + Vector2(0, -20)
	texto.mostrar(valor, color)
func soltar_moneda():
	var nueva_moneda = escena_moneda.instantiate()
	# Usamos get_parent() para que la moneda sea 'hermana' del cofre y no 'hija'
	get_parent().add_child(nueva_moneda)
	nueva_moneda.global_position = global_position
	nueva_moneda.global_position.y -= 50  # Esto la sube un poco para que se vea arriba del cofre
	#nueva_moneda.z_index = 1 # Esto la pone una capa por encima visualmente
