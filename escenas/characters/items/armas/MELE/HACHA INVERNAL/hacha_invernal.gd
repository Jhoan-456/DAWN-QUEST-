extends Area2D

# ==========================================
# 🟢 VARIABLES Y REFERENCIAS
# ==========================================
var jugador_cerca: bool = false
var jugador_ref: Node2D = null

var tween_flote: Tween
var posicion_y_original: float

var flecha: Sprite2D
var sprite_principal: Sprite2D

@export_group("ATRIBUTOS GENERALES DEL ARMA")
@export var textura_normal: Texture2D
@export var textura_seleccionado: Texture2D
@export var costo_energia: float = 6.0
@export var es_clase_mele: bool = true
@export var es_clase_rango: bool = false
@export var es_clase_mago: bool = false
@export var es_clase_invocador: bool = false
@export var nombre_arma: String = "Hacha Invernal"

@export_group("ESTADÍSTICAS Y DAÑO (HACHA INVERNAL)")
@export var dano_mele_base: float = 5.0
@export var escalado_fuerza: float = 0.50 # 50% de la Fuerza total 💪🏽

@export var dano_proyectil_base: float = 3.0
@export var escalado_inteligencia: float = 0.30 # 30% de la Inteligencia total 🧠

@export var velocidad_ataque: float = 0.95 # Cadencia lenta / debajo del promedio (segundos por ataque)
@export var velocidad_proyectil: float = 900.0 # Velocidad alta para la Fase 2

@export_group("FASE 2 Y EVOLUCIÓN")
@export var textura_fase2_normal: Texture2D # Sprite normal de la fase 2
@export var textura_fase2_seleccionado: Texture2D # Sprite resaltado de la fase 2
@export var escena_proyectil_hielo: PackedScene # Proyectil que dispara en la Fase 2
@export var escena_efecto_corte: PackedScene # Ráfaga/efecto blanco de aire al atacar

var enemigos_derrotados: int = 0
var requiere_bajas_fase2: int = 15
var fase_2_activa: bool = false
var puede_atacar: bool = true

# ==========================================
# 🔄 CICLO DE VIDA Y RECOGIDA DEL SUELO
# ==========================================
func _ready() -> void:
	flecha = find_child("flecha", true, false)
	for hijo in get_children():
		if hijo is Sprite2D and hijo != flecha:
			sprite_principal = hijo
			break
			
	if flecha:
		flecha.visible = false
		posicion_y_original = flecha.position.y

func _process(_delta: float) -> void:
	# Si está en el suelo y el jugador interactúa
	if jugador_cerca and is_instance_valid(jugador_ref) and Input.is_action_just_pressed("interactuar"):
		if jugador_ref.has_method("equipar_arma"):
			jugador_ref.equipar_arma(self)
			queue_free()

func _on_body_entered(body):
	if body.is_in_group("jugador"):
		jugador_cerca = true
		jugador_ref = body
		actualizar_textura_seleccionado(true)
		if flecha:
			flecha.visible = true
			iniciar_animacion_flecha()

func _on_body_exited(body):
	if body.is_in_group("jugador"):
		jugador_cerca = false
		jugador_ref = null
		actualizar_textura_seleccionado(false)
		if flecha:
			flecha.visible = false
			detener_animacion_flecha()

# ==========================================
# ⚔️ LÓGICA DE ATAQUE Y ANIMACIÓN MELÉ
# ==========================================
func atacar(jugador: Node2D) -> void:
	if not puede_atacar:
		return
		
	# Verificar energía del jugador
	if jugador.has_method("usar_energia"):
		if not jugador.usar_energia(costo_energia):
			return

	puede_atacar = false
	
	# 1. ANIMACIÓN DE CORTE SWING CON TWEEN
	animar_blanqueado_corte()
	
	# 2. GENERAR EFECTO VISUAL DEL AIRE BLANCO
	instanciar_efecto_corte(jugador)
	
	# 3. APLICAR DAÑO MELÉ EN ÁREA
	hacer_dano_mele(jugador)
	
	# 4. FASE 2: SI ESTÁ ACTIVA, DISPARAR PROYECTILES DE HIELO
	if fase_2_activa:
		disparar_rafaga_fase2(jugador)

	# Cooldown / Velocidad de ataque por debajo del promedio
	await get_tree().create_timer(velocidad_ataque).timeout
	puede_atacar = true

func animar_blanqueado_corte() -> void:
	if sprite_principal:
		var tween_swing = create_tween()
		var rot_inicial = sprite_principal.rotation_degrees
		# Giro rápido de tajo meleo
		tween_swing.tween_property(sprite_principal, "rotation_degrees", rot_inicial - 60.0, 0.08)
		tween_swing.tween_property(sprite_principal, "rotation_degrees", rot_inicial + 40.0, 0.12)
		tween_swing.tween_property(sprite_principal, "rotation_degrees", rot_inicial, 0.1)

func instanciar_efecto_corte(jugador: Node2D) -> void:
	if escena_efecto_corte:
		var corte = escena_efecto_corte.instantiate()
		jugador.get_parent().add_child(corte)
		
		# Apuntar el viento blanco hacia la dirección del mouse o del jugador
		var dir_mouse = (jugador.get_global_mouse_position() - jugador.global_position).normalized()
		corte.global_position = jugador.global_position + dir_mouse * 30.0
		corte.rotation = dir_mouse.angle()

func hacer_dano_mele(jugador: Node2D) -> void:
	# CALCULO: 5 + 50% de la fuerza total
	var fuerza_jugador = jugador.fuerza if "fuerza" in jugador else 0.0
	var dano_final_mele = dano_mele_base + (fuerza_jugador * escalado_fuerza)
	
	# Detectar enemigos frente al jugador en área
	var dir_mouse = (jugador.get_global_mouse_position() - jugador.global_position).normalized()
	var espacio_fisi = get_world_2d().direct_space_state
	
	# Usamos una consulta de forma/área pequeña enfrente del jugador
	var query = PhysicsShapeQueryParameters2D.new()
	var cir = CircleShape2D.new()
	cir.radius = 45.0
	query.shape = cir
	query.transform = Transform2D(0, jugador.global_position + dir_mouse * 35.0)
	query.collision_mask = 2 # Capa de enemigos
	
	var resultados = espacio_fisi.intersect_shape(query)
	for res in resultados:
		var objeto = res.collider
		if objeto.is_in_group("enemigos") and objeto.has_method("recibir_dano"):
			# Pasamos la referencia 'self' para que si muere, cuente la baja
			objeto.recibir_dano(dano_final_mele, self)

# ==========================================
# ❄️ FASE 2: DISPARO DE PROYECTILES
# ==========================================
func disparar_rafaga_fase2(jugador: Node2D) -> void:
	if not escena_proyectil_hielo:
		return
		
	# CALCULO: 3 + 30% de la inteligencia total
	var inteligencia_jugador = jugador.inteligencia if "inteligencia" in jugador else 0.0
	var dano_final_proyectil = dano_proyectil_base + (inteligencia_jugador * escalado_inteligencia)
	
	var dir_base = (jugador.get_global_mouse_position() - jugador.global_position).normalized()
	
	# Disparar 3 proyectiles en abanico / ráfaga
	var angulos = [-0.2, 0.0, 0.2] # Ángulos en radianes para abrir el abanico
	
	for angulo in angulos:
		var proyectil = escena_proyectil_hielo.instantiate()
		jugador.get_parent().add_child(proyectil)
		
		proyectil.global_position = jugador.global_position + dir_base * 20.0
		var dir_final = dir_base.rotated(angulo)
		
		# Asignar atributos al proyectil
		if "dano" in proyectil: proyectil.dano = dano_final_proyectil
		if "velocidad" in proyectil: proyectil.velocidad = velocidad_proyectil
		if "direccion" in proyectil: proyectil.direccion = dir_final
		if "arma_origen" in proyectil: proyectil.arma_origen = self
		
		proyectil.rotation = dir_final.angle()

# ==========================================
# 📈 CONTADOR DE BAJAS Y EVOLUCIÓN
# ==========================================
func registrar_baja_enemigo() -> void:
	if fase_2_activa:
		return
		
	enemigos_derrotados += 1
	print("Bajas con Hacha Invernal: ", enemigos_derrotados, "/", requiere_bajas_fase2)
	
	if enemigos_derrotados >= requiere_bajas_fase2:
		activar_fase_2()

func activar_fase_2() -> void:
	fase_2_activa = true
	print("¡EL HACHA INVERNAL HA EVOLUCIONADO A FASE 2!")
	
	# Cambiamos las texturas a la versión congelada/mejorada
	if textura_fase2_normal:
		textura_normal = textura_fase2_normal
	if textura_fase2_seleccionado:
		textura_seleccionado = textura_fase2_seleccionado
		
	actualizar_textura_seleccionado(jugador_cerca)

func actualizar_textura_seleccionado(seleccionado: bool) -> void:
	if sprite_principal:
		if seleccionado and textura_seleccionado:
			sprite_principal.texture = textura_seleccionado
		elif textura_normal:
			sprite_principal.texture = textura_normal

# ==========================================
# 🏹 FLECHA DE INDICACIÓN EN EL SUELO
# ==========================================
func iniciar_animacion_flecha():
	if tween_flote and tween_flote.is_running():
		tween_flote.kill()
	tween_flote = create_tween().set_loops()
	tween_flote.tween_property($flecha, "position:y", posicion_y_original - 10, 0.5).set_trans(Tween.TRANS_SINE)
	tween_flote.tween_property($flecha, "position:y", posicion_y_original, 0.5).set_trans(Tween.TRANS_SINE)

func detener_animacion_flecha():
	if tween_flote and tween_flote.is_running():
		tween_flote.kill()
	if flecha:
		$flecha.position.y = posicion_y_original
