extends CharacterBody2D

@export var speed: float = 130.0
@export var texto_flotante_scene: PackedScene
var esta_envenenado: bool = false
signal stats_cambiadas
#------------------------------------------------------
var vida :float = 20
var Escudo :float  = 20
var Energia :float  = 150
#@export var costo_energia_disparo: float = 5.0 # Cuánta energía gasta cada bala
var max_vida :float  = 20
var max_escudo :float  = 20
var max_energia :float  = 150
var Moneda = 0
var joystick : Joystick
var ping_actual : int = 30
#------------------------------------------------------
@export var radio_aim_assist: float = 250.0 # Distancia máxima en píxeles para apuntar solo
var enemigo_mas_cercano: Node2D = null
#------------------------------------------------------
var puede_disparar: bool = true
#------------------------------------------------------
var tiene_arma = false
@export var escena_bala : PackedScene # Aquí arrastrarás la escena de la bala
#------------------------------------------------------
@onready var texto_moneda = $UI/LabelMoneda
@onready var texto_fps = $UI/fps
@onready var texto_version = $UI/Version
@onready var texto_segundos = $UI/segund_efect
@onready var texto_internet = $UI/LabelInternet
#------------------------------------------------------
#var zoom_activado = false
#var zoom_normal = Vector2(2,2)
#var zoom_cerca = Vector2(10,10)
#var tween_zoom : Tween
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
	# 2. Si el archivo global dice que sí se deben ver, calculamos los FPS
	# 1. Creamos una dirección vacía cada frame
	var direction = Vector2.ZERO
	if joystick != null and is_instance_valid(joystick):
		direction = joystick.direc
		if Input.is_action_pressed("mover_derecha"):
			direction.x += 1
			print("se movio")
		if Input.is_action_pressed("mover_izquierda"):
			direction.x -= 1
			print("se movio")
		if Input.is_action_pressed("mover_arriba"):
			direction.y -= 1
			print("se movio")
		if Input.is_action_pressed("mover_abajo"):
			direction.y += 1
			print("se movio")
		#if Input.is_action_pressed("zoom"):
			#zoom_activado = !zoom_activado
			#aplicar_zoom_suave()
		if Input.is_action_just_pressed("F3"):
			Datos.fps_visibles = not Datos.fps_visibles
			Datos.version_visible = not Datos.version_visible
		
	# 3. Si hay movimiento, normalizamos y aplicamos la velocidad
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
		$AnimatedSprite2D.play()
		# Control de animaciones y flip
		$AnimatedSprite2D.animation = "idle"
		#----------------------------------------#--
		if direction.x != 0:#
			$AnimatedSprite2D.flip_h = direction.x < 0#
	else:
		# Si no tocamos nada, la velocidad debe ser CERO
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()
	# Borra lo del scale.x y pon esto:
	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
	
	if tiene_arma:
		
		# 1. Buscamos si hay un enemigo en el rango de asistencia
		enemigo_mas_cercano = buscar_enemigo_cercano()
		var angulo_apuntado: float = 0.0
		var debe_rotar_arma: bool = false
		
		# CASO A: Hay un enemigo cerca -> Aim Assist AUTOMÁTICO
		# CASO A: Hay un enemigo cerca -> Aim Assist AUTOMÁTICO
		if enemigo_mas_cercano != null and is_instance_valid(enemigo_mas_cercano):
			# Cambiamos direction_to por la resta directa de posiciones globales para asegurar precisión
			var vector_direccion = enemigo_mas_cercano.global_position - global_position
			angulo_apuntado = vector_direccion.angle()
			debe_rotar_arma = true
			
		# CASO B: No hay enemigos cerca -> Apuntas tú mismo (hacia donde te mueves)
		elif velocity.length() > 0:
			angulo_apuntado = velocity.angle()
			debe_rotar_arma = true
			
		# 2. Aplicamos la rotación y volteamos el arma si apunta a la izquierda
		if debe_rotar_arma:
			$ArmaVisual.rotation = angulo_apuntado
			if abs(angulo_apuntado) > PI/2:
				$ArmaVisual.flip_v = true
				$AnimatedSprite2D.flip_h = true
			else:
				$ArmaVisual.flip_v = false
				$AnimatedSprite2D.flip_h = false

	# 4. LA CLAVE: Esta función mueve al personaje usando la 'velocity' que definimos arriba
	move_and_slide()
#------------------------------------------------------
func _process(delta: float) -> void:
	if texto_fps.visible :
		var fps: int = Engine.get_frames_per_second()
		texto_fps.text = "FPS: " + str(fps)
		if fps <= 10:
			texto_fps.modulate = Color(1.0, 0.0, 0.0, 1.0)
		elif fps == 60:
			texto_fps.modulate = Color(0.0, 0.973, 0.339, 1.0)
		elif fps == 100:
			texto_fps.modulate = Color(1.0, 1.0, 1.0, 1.0)
		elif fps >  100:
			texto_fps.modulate = Color(0.4, 0.898, 1.0, 1.0)
	
	#actualizar_visual_ping(ping_actual)
	# Esta línea actualiza el texto de la pntalla para que muestre el valor real
	# Usamos str() para convertir el número en texto
	var costo_actual = obtener_costo_energia_actual()
	texto_moneda.text = "Monedas: " + str(Moneda)
	if tiene_arma and puede_disparar and Energia >= costo_actual and Input.is_action_pressed("interactuar"):
		disparar()
		equipar_arma()
func obtener_costo_energia_actual() -> float:
	if $ArmaVisual:
		# 1. Si el arma es un nodo hijo dentro de $ArmaVisual
		if $ArmaVisual.get_child_count() > 0:
			var arma_hijo = $ArmaVisual.get_child(0)
			if "costo_energia" in arma_hijo:
				return arma_hijo.costo_energia
		
		# 2. Si el script del arma está en $ArmaVisual directamente
		if "costo_energia" in $ArmaVisual:
			return $ArmaVisual.costo_energia
	
	# 3. Solo si no encuentra el arma usa el respaldo
	return 5.0 
#------------------------------------------------------
# Función para hacer la transición suave
#func aplicar_zoom_suave():
	# 1. Matamos la animación anterior si presionas C muy rápido
	#if tween_zoom and tween_zoom.is_running():
		#tween_zoom.kill()
		
	# 2. Creamos un nuevo Tween
	#tween_zoom = create_tween()
	
	# 3. Decidimos cuál es el objetivo (¿Cerca o Normal?)
	#var objetivo_zoom = zoom_cerca if zoom_activado else zoom_normal
	
	# 4. Animamos la propiedad "zoom" de la Camera2D en 0.3 segundos
	# Asegúrate de que tu nodo de cámara se llame exactamente "Camera2D"
	#tween_zoom.tween_property($Camera2D, "zoom", objetivo_zoom, 0.3).set_trans(Tween.TRANS_SINE)
#------------------------------------------------------------------------------------------------
func actualizar_visual_ping(ms: int) -> void:
	var texto_estrellas = ""
	var color_ping = Color.WHITE

	# Evaluamos qué tan buena es la conexión (menor ms = mejor)
	if ms <= 50:
		texto_estrellas = "*****"
		color_ping = Color(0.0, 0.973, 0.339, 1.0) # Verde (Excelente)
	elif ms <= 100:
		texto_estrellas = "****"
		color_ping = Color(0.6, 0.9, 0.2, 1.0) # Verde amarillento (Buena)
	elif ms <= 150:
		texto_estrellas = "***"
		color_ping = Color(1.0, 0.8, 0.0, 1.0) # Amarillo (Regular)
	elif ms <= 250:
		texto_estrellas = "**"
		color_ping = Color(1.0, 0.5, 0.0, 1.0) # Naranja (Mala)
	else:
		texto_estrellas = "*"
		color_ping = Color(1.0, 0.0, 0.0, 1.0) # Rojo (Pésima)

	# Actualizamos el Label que ya tienes preparado
	texto_internet.text = "Ping: " + texto_estrellas
	texto_internet.modulate = color_ping
#------------------------------------------------------------------------------------------------
func recibir_daño(cantidad: int):
	$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
	# 1. SI EL JUGADOR TIENE ESCUDO
	if Escudo > 0:
		# Calculamos cuánto daño puede absorber el escudo como máximo
		var daño_al_escudo = min(cantidad, Escudo)
		
		Escudo -= daño_al_escudo
		efecto_recibir_daño()
		cantidad -= daño_al_escudo # El daño restante que pasará a la vida
		
		# Mostramos el texto flotante gris del escudo roto
		crear_texto_flotante("-" + str(daño_al_escudo), Color(0.561, 0.561, 0.561, 1.0))
		
		stats_cambiadas.emit()
	
	# 2. SI QUEDÓ DAÑO SOBRANTE (O si no tenía escudo desde el principio)
	if cantidad > 0:
		$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0)
		vida -= cantidad
		vida = clamp(vida, 0 , max_vida)
		efecto_recibir_daño()
		stats_cambiadas.emit()
		crear_texto_flotante("-" + str(cantidad), Color(0.874, 0.0, 0.254, 1.0))
		
		if vida <= 0:
			vida = 0 # Evitamos que la vida también quede en números negativos
			print("Game over")

func efecto_recibir_daño() -> void:
	var sprite = $AnimatedSprite2D
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
#------------------------------------------------------
func _on_ui_enviar_joystick(j: Joystick) -> void:
	joystick = j
	pass # Replace with function body.
	
#------------------------------------------------------
func equipar_arma():
	tiene_arma = true
	$ArmaVisual.visible = true
	print("¡Arma equipada!")

#------------------------------------------------------
func disparar():
	var costo = obtener_costo_energia_actual()
	
	# 2. Restamos la energía según esa arma
	Energia -= costo
	Energia = clamp(Energia, 0, max_energia)
	
	stats_cambiadas.emit()
	# 1. Restamos la energía
	Energia = clamp(Energia, 0, max_energia)
	
	# 2. Notificamos a la UI para que actualice la barra de tu imagen
	stats_cambiadas.emit()
	puede_disparar = false 
	var bala = escena_bala.instantiate()
	get_parent().add_child(bala)
	
	# La bala sale de la punta del arma (que es hija del arma)
	bala.global_position = $ArmaVisual/puntoDisparo.global_position
	
	# Le pasamos la rotación actual del arma a la bala
	bala.rotation = $ArmaVisual.rotation
	
	# Creamos un vector de dirección basado en el ángulo del arma
	# Vector2.RIGHT es (1, 0), y lo rotamos según el arma
	bala.direccion_vector = Vector2.RIGHT.rotated($ArmaVisual.rotation)
	await get_tree().create_timer(0.7).timeout
	puede_disparar = true
	aplicar_retroceso()

#------------------------------------------------------------------------
func aplicar_retroceso():
	# 1. FORZAMOS el arma a volver a su posición original (0,0 o donde la tengas)
	# Esto evita que los retrocesos se acumulen si disparas rápido
	$ArmaVisual.position = Vector2(0, 0) # Cámbialo por tu posición base si no es 0,0
	# 1. Creamos un "Tween"
	var tween = create_tween()
	
	# 2. Calculamos la posición de "retroceso" (un poquito hacia atrás)
	# Usamos el signo menos para que se mueva al lado opuesto de donde apunta
	var retroceso_pos = $ArmaVisual.position - Vector2(10,0).rotated($ArmaVisual.rotation)
	var posicion_original = $ArmaVisual.position
	
	# 3. Animamos el golpe hacia atrás (muy rápido: 0.05 segundos)
	tween.tween_property($ArmaVisual, "position", retroceso_pos, 0.07)
	
	# 4. Animamos el regreso a la posición original (un poco más lento: 0.1 segundos)
	tween.tween_property($ArmaVisual, "position", posicion_original, 0.07)
#---------------------------------------------------------------------------------------------------
func crear_texto_flotante(valor: String, color: Color) -> void:
	if not texto_flotante_scene: return
	
	var texto = texto_flotante_scene.instantiate()
	# Lo colocamos en el mundo general para que no se mueva pegado al personaje
	get_parent().add_child(texto)
	# Lo posicionamos justo encima de la cabeza del personaje
	texto.global_position = global_position + Vector2(0, -20)
	texto.mostrar(valor, color)
#---------------------------------------------------------------------------
func recibir_veneno():
	# 1. Si ya está sufriendo por el veneno, no hacemos nada (evita acumulación infinita)
	if esta_envenenado: return 
	esta_envenenado = true
	# EFECTO VISUAL: Pintamos al personaje de un tono morado/verdoso para que se note el veneno
	$AnimatedSprite2D.modulate = Color(0.564, 0.349, 0.87, 1.0)

	# CONFIGURACIÓN DEL VENENO:
	var tics_totales = 3    # Cuántas veces recibirá daño
	var daño_por_tic = 1    # Cuánta vida pierde en cada golpe de veneno
	var tiempo_espera = 1 # Cada cuántos segundos actúa el venen
	# 2. El bucle que se encarga de repetir el daño
	for i in range(tics_totales):
		stats_cambiadas.emit()
		# Esperamos 1 segundo antes de aplicar el siguiente golpe
		await get_tree().create_timer(tiempo_espera).timeout
		
		# NOTA: El veneno en los juegos suele ir DIRECTO a la vida saltándose el escudo.
		# Por eso restamos directamente a 'vida' en vez de usar recibir_daño().
		vida -= daño_por_tic
		vida = clamp(vida, 0, 20) # Evitamos que baje de 0

		texto_segundos.text = "Veneno: " + str(tiempo_espera)
		# Mostramos el numerito morado flotando sobre el jugador
		crear_texto_flotante("-" + str(daño_por_tic), Color(0.6, 0.0, 0.7, 1.0))
		
		
		# Si el jugador se queda sin vida por el veneno, detenemos el temporizador
		if vida <= 0:
			print("Game over por veneno")
			break
	# 3. Al terminar el efecto, limpiamos al personaje
	$AnimatedSprite2D.modulate = Color(1.0, 1.0, 1.0, 1.0) # Restaura su color original
	esta_envenenado = false
func buscar_enemigo_cercano() -> Node2D:
	# 1. Lista ordenada por prioridad (de más peligroso a menos peligroso)
	var lista_prioridades = ["bosses",
	 "enemigos_dificil",
	 "enemigos_medio",
	 "enemigos_facil"]
	
	# 2. Iteramos grupo por grupo en orden de jerarquía
	for grupo in lista_prioridades:
		var lista_enemigos = get_tree().get_nodes_in_group(grupo)
		var enemigo_mas_cercano_del_grupo: Node2D = null
		
		# Inicializamos la distancia máxima con el radio de asistencia
		var distancia_minima: float = radio_aim_assist
		
		# Buscamos el enemigo más cercano DENTRO del grupo actual
		for enemigo in lista_enemigos:
			if is_instance_valid(enemigo):
				var distancia = global_position.distance_to(enemigo.global_position)
				
				# Solo lo tomamos en cuenta si está dentro del radio de disparo
				if distancia <= distancia_minima:
					distancia_minima = distancia
					enemigo_mas_cercano_del_grupo = enemigo
		
		# ¡LA CLAVE! Si encontramos al menos un enemigo de esta categoría en rango,
		# lo devolvemos inmediatamente y NO seguimos buscando en categorías inferiores.
		if enemigo_mas_cercano_del_grupo != null:
			#print("Apuntando a categoría [", grupo, "] a distancia: ", distancia_minima)
			return enemigo_mas_cercano_del_grupo

	# 3. Si recorrió todos los grupos y no hay ningún enemigo dentro del radio
	return null
#func _input(event: InputEvent) -> void:
	# 1. SI DETECTA UN CURSOR DE MOUSE O TECLADO (PC)
	#if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		
		# Ocultamos el joystick (verificando que ya haya cargado)
		#if joystick != null and is_instance_valid(joystick):
		#	joystick.visible = false
			
		## Ocultamos los botones en pantalla (¡Asegúrate de poner la ruta correcta de tus botones!)
		#if has_node("UI/Atacar"):
		#	$UI/Atacar.visible = false
		#if has_node("UI/cambiar"):
		#	$UI/cambiar.visible = false


	# 2. SI DETECTA QUE ALGUIEN TOCA LA PANTALLA (Celular/Tablet)
	#elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		
		# Mostramos el joystick
		#if joystick != null and is_instance_valid(joystick):
		#	joystick.visible = true
			
		## Mostramos los botones nuevamente
		#if has_node("UI/Atacar"):
		#	$UI/Atacar.visible = true
		#if has_node("UI/cambiar"):
		#	$UI/cambiar.visible = true


func _on_pausar_pressed() -> void:
	var escena_a_pausa = escena_pausa.instantiate()
	
	get_tree().paused = true 
	
	add_child(escena_a_pausa)
	pass # Replace with function body.
