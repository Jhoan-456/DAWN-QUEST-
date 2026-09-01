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
@export var tiempo_entre_rafagas: float = 1.0

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
				# Ataque A: Espiral rápida
				await disparar_espiral(80, 0.08, 12.0)
			else:
				
				await disparar_anillos_zigzag(6, 12, 0.15)
			
			# Cambiamos el turno para el siguiente ataque
			turno_fase_3 = not turno_fase_3
			await get_tree().create_timer(0.5).timeout
		
		# 🟠 FASE 2: Vida entre 70 y 80 -> Solo Espiral continua
		elif vida_actual < 80.0:
			await disparar_espiral(25, 0.04, 12.0)
			await get_tree().create_timer(0.8).timeout
			
		# 🟢 FASE 1: Vida mayor o igual a 80 -> Anillo estático simple
		else:
			disparar_anillo(12)
			await get_tree().create_timer(1.0).timeout
		
		if jugador_a_perseguir == null or vida_actual <= 0: break
		
		# Disparo secundario constante hacia el jugador
		disparar_abanico(5, 60.0, jugador_a_perseguir.global_position)
		await get_tree().create_timer(tiempo_entre_rafagas).timeout

# --- FUNCIONES DE PATRONES DE PROYECTILES ---
func instanciar_esfera(dir: Vector2) -> void:
	if escena_proyectil == null: return
	var bala = escena_proyectil.instantiate()
	get_parent().add_child(bala)
	bala.global_position = global_position
	bala.direccion = dir.normalized()

# 🆕 NUEVO PATRÓN (< 70 VIDA): Anillos Ráfaga con Ángulo Incremental
func disparar_anillos_giratorios(cantidad_anillos: int = 5, esferas_por_anillo: int = 12, incremento_angulo: float = 10.0, espera: float = 0.1) -> void:
	var angulo_acumulado: float = 0.0
	
	for n in range(cantidad_anillos):
		if jugador_a_perseguir == null or vida_actual <= 0: break
		
		# Dispara un anillo completo de esferas
		var paso_angulo = TAU / esferas_por_anillo
		for i in range(esferas_por_anillo):
			var angulo = (i * paso_angulo) + deg_to_rad(angulo_acumulado)
			var direccion_bala = Vector2.RIGHT.rotated(angulo)
			instanciar_esfera(direccion_bala)
		
		# Suma el ángulo para que el siguiente anillo salga ligeramente girado
		angulo_acumulado += incremento_angulo
		
		# Pausa corta entre cada anillo
		await get_tree().create_timer(espera).timeout

# PATRÓN ESPIRAL (< 80 VIDA)
func disparar_espiral(total_proyectiles: int = 30, tiempo_espera: float = 0.04, incremento_angulo: float = 12.0) -> void:
	var angulo_acumulado: float = 0.0
	for i in range(total_proyectiles):
		if jugador_a_perseguir == null or vida_actual <= 0: break
		var direccion_bala = Vector2.RIGHT.rotated(deg_to_rad(angulo_acumulado))
		instanciar_esfera(direccion_bala)
		angulo_acumulado += incremento_angulo
		await get_tree().create_timer(tiempo_espera).timeout

func disparar_anillo(cantidad: int = 12) -> void:
	var paso_angulo = TAU / cantidad
	for i in range(cantidad):
		var angulo = i * paso_angulo
		var direccion_bala = Vector2.RIGHT.rotated(angulo)
		instanciar_esfera(direccion_bala)
# 🆕 PATRÓN ZIG-ZAG (Alterna ángulos para cubrir los espacios vacíos del anterior)
func disparar_anillos_zigzag(cantidad_anillos: int = 6, esferas_por_anillo: int = 12, espera: float = 0.15) -> void:
	var paso_angulo = TAU / esferas_por_anillo
	var medio_paso = paso_angulo / 2.0 # La mitad de la distancia entre proyectiles para tapar el hueco
	
	for n in range(cantidad_anillos):
		if jugador_a_perseguir == null or vida_actual <= 0: break
		
		# Si el número de anillo es impar (1, 3, 5...), desplazamos las esferas exactamente a los huecos
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
