extends CharacterBody2D

# --- VARIABLES DE VIDA ---
@export var vida_maxima: float = 15.0
var vida_actual: float = 15.0
@export var es_mini: bool = false

@export var texto_flotante_scene: PackedScene
@export var escena_moneda: PackedScene

@onready var barra_vida = $ProgressBar 
@onready var sprite = $visual/AnimatedSprite2D

var ya_se_dividio: bool = false
var esta_muerto: bool = false
var recibiendo_dano: bool = false  # 👈 Evita interrupciones durante el golpe

var dano: int = 2
var objetivo: Node2D = null              # Jugador en rango de ATAQUE
var jugador_a_perseguir: Node2D = null  # Jugador en rango de VISIÓN

# --- COOLDOWN DE ATAQUE ---
@export var tiempo_entre_ataques: float = 1.0
var puede_atacar: bool = true

# --- MOVIMIENTO ---
var velocidad_patrulla: float = 80.0
var velocidad_persecucion: float = 100.0
var direccion: Vector2 = Vector2.ZERO
var tiempo_proximo_paso: float = 0.0

func _ready() -> void:
	add_to_group("enemigos_facil")
	vida_actual = vida_maxima
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_actual
	if sprite:
		sprite.play("idle_abajo")

# --- ZONAS DE DETECCIÓN Y ATAQUE ---
func _on_zona_ataque_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador") or body.has_method("recibir_daño"):
		objetivo = body

func _on_zona_ataque_body_exited(body: Node2D) -> void:
	if body == objetivo:
		objetivo = null

func _on_zona_deteccion_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador") or body.has_method("recibir_daño"):
		jugador_a_perseguir = body

func _on_zona_deteccion_body_exited(body: Node2D) -> void:
	if body == jugador_a_perseguir:
		jugador_a_perseguir = null

# --- BUCLE PRINCIPAL DE MOVIMIENTO ---
func _physics_process(delta: float) -> void:
	if esta_muerto:
		return

	# Revisa si el jugador está dentro de la zona de ataque en este instante
	comprobar_objetivo_en_rango()

	# ESTADO 1: ATACANDO
	if is_instance_valid(objetivo):
		velocity = Vector2.ZERO
		if puede_atacar and not recibiendo_dano:
			atacar()

	# ESTADO 2: PERSIGUIENDO
	elif is_instance_valid(jugador_a_perseguir):
		direccion = global_position.direction_to(jugador_a_perseguir.global_position)
		velocity = direccion * velocidad_persecucion
		
		# Solo regresa a idle_abajo si no está atacando ni sufriendo daño
		if not recibiendo_dano and sprite.animation != "ataque" and sprite.animation != "idle_abajo":
			sprite.play("idle_abajo")
			
		actualizar_orientacion_sprite(direccion.x)

	# ESTADO 3: PATRULLANDO
	else:
		tiempo_proximo_paso -= delta
		if is_on_wall():
			direccion = -direccion
			
		if tiempo_proximo_paso <= 0.0:
			direccion = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			tiempo_proximo_paso = randf_range(1, 3)

		velocity = direccion * velocidad_patrulla
		
		if not recibiendo_dano and sprite.animation != "ataque" and sprite.animation != "idle_abajo":
			sprite.play("idle_abajo")

		actualizar_orientacion_sprite(direccion.x)

	move_and_slide()

# --- VERIFICACIÓN Y ORIENTACIÓN ---
func comprobar_objetivo_en_rango() -> void:
	if has_node("Zona_ataque"):
		var cuerpos = $Zona_ataque.get_overlapping_bodies()
		for cuerpo in cuerpos:
			if cuerpo.is_in_group("jugador") or cuerpo.has_method("recibir_daño"):
				objetivo = cuerpo
				return
	objetivo = null

func actualizar_orientacion_sprite(dir_x: float) -> void:
	if dir_x > 0:
		sprite.flip_h = true
	elif dir_x < 0:
		sprite.flip_h = false

# --- COMBATE ---
func atacar() -> void:
	if is_instance_valid(objetivo) and puede_atacar and not esta_muerto and not recibiendo_dano:
		puede_atacar = false
		sprite.play("ataque")
		
		if objetivo.has_method("recibir_daño"):
			objetivo.recibir_daño(dano)
		
		if sprite.sprite_frames.has_animation("ataque"):
			await sprite.animation_finished
			
		if not esta_muerto and not recibiendo_dano:
			sprite.play("idle_abajo")

		await get_tree().create_timer(tiempo_entre_ataques).timeout
		puede_atacar = true

func recibir_daño(cantidad: int) -> void:
	if esta_muerto:
		return

	vida_actual -= cantidad
	vida_actual = clamp(vida_actual, 0, vida_maxima)
	
	if barra_vida:
		barra_vida.value = vida_actual
		
	crear_texto_flotante("-" + str(cantidad), Color(0.954, 0.0, 0.0, 1.0))
	
	if vida_actual <= 0:
		morir()
	else:
		reproducir_animacion_daño()

func reproducir_animacion_daño() -> void:
	if not is_instance_valid(sprite) or esta_muerto:
		return

	recibiendo_dano = true
	sprite.play("daño")

	# Shader de destello blanco
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		vec3 color_impacto = mix(tex.rgb, vec3(2.0), 0.75);
		COLOR = vec4(color_impacto, tex.a);
	}
	"""
	mat.shader = shader
	sprite.material = mat

	# Mantiene el destello del shader por 0.08s
	await get_tree().create_timer(0.08).timeout

	if is_instance_valid(sprite):
		sprite.material = null

	# Espera a que la animación "daño" termine por completo
	if sprite.sprite_frames.has_animation("daño"):
		await sprite.animation_finished

	recibiendo_dano = false

	# Regresa inmediatamente a idle_abajo al recuperarse
	if not esta_muerto and is_instance_valid(sprite):
		sprite.play("idle_abajo")

func morir() -> void:
	esta_muerto = true
	recibiendo_dano = false
	set_physics_process(false)
	
	if has_node("Zona_ataque"): $Zona_ataque.set_deferred("monitoring", false)
	if has_node("ZonaDeteccion"): $ZonaDeteccion.set_deferred("monitoring", false)
	if has_node("CollisionShape2D"): $CollisionShape2D.set_deferred("disabled", true)

	soltar_moneda()
	sprite.play("died")
	await sprite.animation_finished
	queue_free()

func crear_texto_flotante(valor: String, color: Color) -> void:
	if not texto_flotante_scene: return
	var texto = texto_flotante_scene.instantiate()
	get_parent().add_child(texto)
	texto.global_position = global_position + Vector2(0, -20)
	texto.mostrar(valor, color)

func soltar_moneda() -> void:
	if not escena_moneda: return
	var nueva_moneda = escena_moneda.instantiate()
	get_parent().add_child(nueva_moneda)
	nueva_moneda.global_position = global_position + Vector2(0, -10)
