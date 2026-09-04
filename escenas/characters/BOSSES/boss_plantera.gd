extends CharacterBody2D

# --- VARIABLES DE VIDA Y CONFIGURACIÓN ---
@export var vida_maxima: float = 100.0
var vida_actual: float = 100.0

@export var escena_proyectil: PackedScene
@export var texto_flotante_scene: PackedScene
@export var escena_moneda: PackedScene

@onready var barra_vida = $ProgressBar
@onready var sprite = $AnimatedSprite2D

# --- ESTADOS Y CONTROL DE ATAQUE ---
var jugador_a_perseguir: Node2D = null
var atacando: bool = false

# ⏱️ 1. DELAYS ENTRE ATAQUES (Aumentados para darle espacio al jugador)
@export_group("Delays y Cooldowns")
@export var tiempo_entre_rafagas: float = 2.0  # Pausa tras el abanico (Antes 1.0s)
@export var delay_fase_1: float = 2.0           # Pausa en Fase 1 (Antes 1.0s)
@export var delay_fase_2: float = 1.8           # Pausa en Fase 2 (Antes 0.8s)
@export var delay_fase_3: float = 1.5           # Pausa en Fase 3 (Antes 0.5s)

# 🎯 2. ESPACIO ENTRE PROYECTILES (A menor cantidad, mayor espacio libre)
@export_group("Configuración de Proyectiles")
@export var proyectiles_anillo_fase1: int = 8      # Esferas por anillo (Antes 12)
@export var proyectiles_zigzag_fase3: int = 8      # Esferas en zig-zag (Antes 12)
@export var proyectiles_abanico: int = 3           # Disparos dirigidos (Antes 5)
@export var incremento_angulo_espiral: float = 25.0 # Grados de separación en espiral (Antes 12.0)
@export var espera_espiral: float = 0.1            # Tiempo entre esferas de espiral (Antes 0.04s)

# Variable para turnar los ataques en la Fase 3 (< 70)
var turno_fase_3: bool = false 

func _ready() -> void:
	add_to_group("bosses")
	vida_actual = vida_maxima
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_actual

func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

# --- SEÑALES DE LA ZONA DE DETECCIÓN ---
func _on_zona_deteccion_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_daño") and not body.is_in_group("bosses"):
		jugador_a_perseguir = body
		if not atacando:
			iniciar_bucle_ataque_primera_fase()

func _on_zona_deteccion_body_exited(body: Node2D) -> void:
	if body == jugador_a_perseguir:
		jugador_a_perseguir = null
		atacando = false

# --- BUCLE PRINCIPAL (SISTEMA DE FASES POR VIDA) ---
func iniciar_bucle_ataque_primera_fase() -> void:
	atacando = true
	while atacando and jugador_a_perseguir != null and vida_actual > 0:
		
		# 🔴 FASE 3: Vida menor a 70 -> Alterna entre Espiral y Anillos Giratorios
		if vida_actual < 70.0:
			if turno_fase_3:
				# Espiral más pausada y con más espacio
				await disparar_espiral(25, espera_espiral, incremento_angulo_espiral)
			else:
				# Anillos Zig-Zag con 8 esferas (más huecos para esquivar)
				await disparar_anillos_zigzag(4, proyectiles_zigzag_fase3, 0.2)
			
			turno_fase_3 = not turno_fase_3
			await get_tree().create_timer(delay_fase_3).timeout
		
		# 🟠 FASE 2: Vida entre 70 y 80 -> Espiral amplia
		elif vida_actual < 80.0:
			await disparar_espiral(20, espera_espiral, incremento_angulo_espiral)
			await get_tree().create_timer(delay_fase_2).timeout
			
			
		# 🟢 FASE 1: Vida mayor o igual a 80 -> Anillo simple
		else:
			disparar_anillo(proyectiles_anillo_fase1)
			await get_tree().create_timer(delay_fase_1).timeout
		
		if jugador_a_perseguir == null or vida_actual <= 0: break
		
		# Disparo abanico secundario (ahora lanza solo 3 esferas)
		disparar_abanico(proyectiles_abanico, 60.0, jugador_a_perseguir.global_position)
		await get_tree().create_timer(tiempo_entre_rafagas).timeout

# --- FUNCIONES DE PATRONES DE PROYECTILES ---
func instanciar_esfera(dir: Vector2) -> void:
	if escena_proyectil == null: return
	var bala = escena_proyectil.instantiate()
	get_parent().add_child(bala)
	bala.global_position = global_position
	bala.direccion = dir.normalized()

func disparar_anillos_giratorios(cantidad_anillos: int = 5, esferas_por_anillo: int = 8, incremento_angulo: float = 15.0, espera: float = 0.2) -> void:
	var angulo_acumulado: float = 0.0
	
	for n in range(cantidad_anillos):
		if jugador_a_perseguir == null or vida_actual <= 0: break
		
		var paso_angulo = TAU / esferas_por_anillo
		for i in range(esferas_por_anillo):
			var angulo = (i * paso_angulo) + deg_to_rad(angulo_acumulado)
			var direccion_bala = Vector2.RIGHT.rotated(angulo)
			instanciar_esfera(direccion_bala)
		
		angulo_acumulado += incremento_angulo
		await get_tree().create_timer(espera).timeout

func disparar_espiral(total_proyectiles: int = 25, tiempo_espera: float = 0.1, incremento_angulo: float = 25.0) -> void:
	var angulo_acumulado: float = 0.0
	for i in range(total_proyectiles):
		if jugador_a_perseguir == null or vida_actual <= 0: break
		var direccion_bala = Vector2.RIGHT.rotated(deg_to_rad(angulo_acumulado))
		instanciar_esfera(direccion_bala)
		angulo_acumulado += incremento_angulo
		await get_tree().create_timer(tiempo_espera).timeout

func disparar_anillo(cantidad: int = 8) -> void:
	var paso_angulo = TAU / cantidad
	for i in range(cantidad):
		var angulo = i * paso_angulo
		var direccion_bala = Vector2.RIGHT.rotated(angulo)
		instanciar_esfera(direccion_bala)

func disparar_anillos_zigzag(cantidad_anillos: int = 4, esferas_por_anillo: int = 8, espera: float = 0.2) -> void:
	var paso_angulo = TAU / esferas_por_anillo
	var medio_paso = paso_angulo / 2.0
	
	for n in range(cantidad_anillos):
		if jugador_a_perseguir == null or vida_actual <= 0: break
		
		var offset_actual = medio_paso if (n % 2 == 1) else 0.0
		
		for i in range(esferas_por_anillo):
			var angulo = (i * paso_angulo) + offset_actual
			var direccion_bala = Vector2.RIGHT.rotated(angulo)
			instanciar_esfera(direccion_bala)
			
		await get_tree().create_timer(espera).timeout

func disparar_abanico(cantidad: int, apertura_grados: float, pos_objetivo: Vector2) -> void:
	var dir_hacia_objetivo = global_position.direction_to(pos_objetivo)
	var angulo_base = dir_hacia_objetivo.angle()
	var apertura_rad = deg_to_rad(apertura_grados)
	var angulo_inicio = angulo_base - (apertura_rad / 2.0)
	var paso = apertura_rad / (cantidad - 1) if cantidad > 1 else 0.0
	
	for i in range(cantidad):
		var angulo_actual = angulo_inicio + (i * paso)
		var direccion_bala = Vector2.RIGHT.rotated(angulo_actual)
		instanciar_esfera(direccion_bala)

# --- SISTEMA DE DAÑO Y EFECTOS ---
func recibir_daño(cantidad: int) -> void:
	vida_actual -= cantidad
	vida_actual = clamp(vida_actual, 0, vida_maxima)
	
	if barra_vida:
		barra_vida.value = vida_actual
		
	efecto_recibir_daño()
	crear_texto_flotante("-" + str(cantidad), Color(0.95, 0.1, 0.1, 1.0))
	
	if vida_actual <= 0:
		morir()

func efecto_recibir_daño() -> void:
	if not sprite: return
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		vec3 color_impacto = mix(tex.rgb, vec3(1.0), 100);
		COLOR = vec4(color_impacto, tex.a);
	}
	"""
	mat.shader = shader
	sprite.material = mat
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(sprite):
		sprite.material = null

func crear_texto_flotante(valor: String, color: Color) -> void:
	if not texto_flotante_scene: return
	var texto = texto_flotante_scene.instantiate()
	get_parent().add_child(texto)
	texto.global_position = global_position + Vector2(0, -35)
	texto.mostrar(valor, color)

func morir() -> void:
	atacando = false
	if escena_moneda:
		var nueva_moneda = escena_moneda.instantiate()
		get_parent().add_child(nueva_moneda)
		nueva_moneda.global_position = global_position
		
	if sprite and sprite.sprite_frames.has_animation("died"):
		sprite.play("died")
		await sprite.animation_finished
		
	queue_free()
