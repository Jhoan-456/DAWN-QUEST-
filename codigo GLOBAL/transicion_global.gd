extends CanvasLayer

var transicion_actual: int = 0
# --- TRANSICIÓN 1: COLUMNAS QUE CAEN Y SUBEN ---
func ejecutar_transicion(escena_objetivo: String):
	var tamano_pantalla = get_viewport().get_visible_rect().size
	var columnas = []
	var cantidad_bloques = 10
	var ancho_bloque = tamano_pantalla.x / cantidad_bloques
	
	var tween_entrada = create_tween().set_parallel(true)
	
	for i in range(cantidad_bloques):
		var bloque = ColorRect.new()
		bloque.color = Color.BLACK
		bloque.size = Vector2(ancho_bloque + 1, tamano_pantalla.y)
		
		if i % 2 == 0:
			bloque.position = Vector2(i * ancho_bloque, -tamano_pantalla.y)
		else:
			bloque.position = Vector2(i * ancho_bloque, tamano_pantalla.y)
			
		add_child(bloque)
		columnas.append(bloque)
		
		tween_entrada.tween_property(bloque, "position:y", 0.0, 0.5)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
			
	await get_tree().create_timer(0.5).timeout
	
	get_tree().change_scene_to_file(escena_objetivo)
	await get_tree().create_timer(0.1).timeout
	
	var tween_salida = create_tween().set_parallel(true)
	
	for bloque in columnas:
		if is_instance_valid(bloque):
			bloque.pivot_offset = bloque.size / 2
			tween_salida.tween_property(bloque, "scale", Vector2.ZERO, 0.5)\
				.set_trans(Tween.TRANS_BACK)\
				.set_ease(Tween.EASE_IN)
				
	await get_tree().create_timer(0.5).timeout
	
	for bloque in columnas:
		if is_instance_valid(bloque):
			bloque.queue_free()
# --- TRANSICIÓN 2: ESCALERITAS CASCOTEADAS HACIA ABAJO ---
func ejecutar_transicion_escaleras(escena_objetivo: String):
	var tamano_pantalla = get_viewport().get_visible_rect().size
	var barras = []
	var cantidad_barras = 8         # Cuántas "escaleritas" horizontales se crearán
	var alto_barra = tamano_pantalla.y / cantidad_barras
	var duracion_barra = 0.6        # Cuánto tarda una sola barra en estirarse
	var retraso_entre_barras = 0.06 # El tiempo de espera entre peldaño y peldaño
	
	var tween_entrada = create_tween().set_parallel(true)
	
	for i in range(cantidad_barras):
		var barra = ColorRect.new()
		barra.color = Color.BLACK
		barra.size = Vector2(tamano_pantalla.x, alto_barra + 1)
		barra.position = Vector2(0, i * alto_barra)
		
		barra.pivot_offset = Vector2(0, 0)
		barra.scale.x = 0.0
		
		add_child(barra)
		barras.append(barra)
		
		tween_entrada.tween_property(barra, "scale:x", 1.0, duracion_barra)\
			.set_delay(i * retraso_entre_barras)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
			
	var tiempo_total_entrada = duracion_barra + (cantidad_barras * retraso_entre_barras)
	await get_tree().create_timer(tiempo_total_entrada).timeout
	
	get_tree().change_scene_to_file(escena_objetivo)
	await get_tree().create_timer(0.1).timeout
	
	var tween_salida = create_tween().set_parallel(true)
	
	for i in range(barras.size()):
		var barra = barras[i]
		if is_instance_valid(barra):
			barra.pivot_offset = Vector2(tamano_pantalla.x, 0)
			
			tween_salida.tween_property(barra, "scale:x", 0.0, duracion_barra)\
				.set_delay(i * retraso_entre_barras)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN)
				
	await get_tree().create_timer(tiempo_total_entrada).timeout
	
	for barra in barras:
		if is_instance_valid(barra):
			barra.queue_free()


# --- TRANSICIÓN 3: IRIS ESTILO MARIO MAKER 2 ---
func ejecutar_transicion_iris(escena_objetivo: String):
	var tamano_pantalla = get_viewport().get_visible_rect().size
	var relacion_aspecto = tamano_pantalla.x / tamano_pantalla.y
	
	# 1. Creamos un ColorRect que cubra toda la pantalla dinámicamente
	var fondo_iris = ColorRect.new()
	fondo_iris.size = tamano_pantalla
	fondo_iris.color = Color.BLACK
	fondo_iris.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 2. Creamos el Shader 100% por código para hacer el "agujero" circular
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform float radio : hint_range(0.0, 1.5) = 1.2;
	uniform float relacion = 1.777;
	void fragment() {
		// Centramos las coordenadas UV y corregimos la proporción para que no sea un óvalo
		vec2 uv_corregida = UV - vec2(0.5);
		uv_corregida.x *= relacion;
		
		float dist = length(uv_corregida);
		// Suavizamos mínimamente el borde del círculo como en los juegos retro
		float borde = smoothstep(radio - 0.01, radio, dist);
		COLOR = vec4(0.0, 0.0, 0.0, borde);
	}
	"""
	
	var material_iris = ShaderMaterial.new()
	material_iris.shader = shader
	material_iris.set_shader_parameter("radio", 1.2) # 1.2 asegura que las esquinas inicien libres
	material_iris.set_shader_parameter("relacion", relacion_aspecto)
	fondo_iris.material = material_iris
	
	add_child(fondo_iris)
	
	# 3. Animación de cierre (El radio del círculo se encoge de 1.2 a 0.0)
	var tween_cierre = create_tween()
	tween_cierre.tween_property(material_iris, "shader_parameter/radio", 0.0, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	await tween_cierre.finished
	
	# 4. CAMBIO DE ESCENA EN LA OSCURIDAD
	get_tree().change_scene_to_file(escena_objetivo)
	await get_tree().create_timer(0.1).timeout
	
	# 5. Animación de apertura (El radio del círculo crece de 0.0 a 1.2)
	var tween_abrir = create_tween()
	tween_abrir.tween_property(material_iris, "shader_parameter/radio", 1.2, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	await tween_abrir.finished
	
	# 6. Limpieza absoluta del nodo temporal
	if is_instance_valid(fondo_iris):
		fondo_iris.queue_free()
	# --- 🔀 FUNCIÓN MAESTRA PARA CAMBIAR DE ESCENA ---
func cambiar_escena(escena_objetivo: String):
	# El 'match' revisa qué número tiene guardado 'transicion_actual' 
	# y ejecuta automáticamente la función que corresponde.
	match transicion_actual:
		0:
			ejecutar_transicion(escena_objetivo)
		1:
			ejecutar_transicion_escaleras(escena_objetivo)
		2:
			ejecutar_transicion_iris(escena_objetivo)
#=====================================================================
# ESTA FUNCION NO ES UN TRANSICION, ES MAS TECNICO 
#=====================================================================
func denegar_boton(boton: Control, mensaje: String = "Esta función no está disponible") -> void:
	if not is_instance_valid(boton):
		return

	# ==========================================
	# 1. ANIMACIÓN DE TEMBLOR DE "NO" EN EL BOTÓN
	# ==========================================
	# Ajustamos el pivote al centro del botón para que gire bonito
	boton.pivot_offset = boton.size / 2.0
	
	var tween_shake = boton.create_tween()
	var angulo: float = 8.0 # Grados de inclinación
	var tiempo: float = 0.04 # Velocidad del temblor
	
	# Hace un bamboleo rápido a la izquierda y derecha
	tween_shake.tween_property(boton, "rotation_degrees", angulo, tiempo)
	tween_shake.tween_property(boton, "rotation_degrees", -angulo, tiempo)
	tween_shake.tween_property(boton, "rotation_degrees", angulo * 0.5, tiempo)
	tween_shake.tween_property(boton, "rotation_degrees", -angulo * 0.5, tiempo)
	tween_shake.tween_property(boton, "rotation_degrees", 0.0, tiempo)

	# ==========================================
	# 2. CARTEL / TEXTO ROJO FLOTANTE
	# ==========================================
	var label = Label.new()
	label.text = mensaje
	
	# Cambiamos el color a rojo brillante
	label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1.0))
	
	# Posicionamos el texto justo donde el jugador hizo clic (o sobre el botón)
	var pos_inicial = boton.get_global_mouse_position() + Vector2(-60, -25)
	label.global_position = pos_inicial
	
	# Lo agregamos a la escena actual para que sea visible
	get_tree().current_scene.add_child(label)
	
	# Animación: El texto sube un poco y se vuelve transparente (Fade Out)
	var tween_texto = label.create_tween().set_parallel(true)
	tween_texto.tween_property(label, "global_position:y", pos_inicial.y - 40.0, 1.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_texto.tween_property(label, "modulate:a", 1.0, 1.0)\
		.set_ease(Tween.EASE_IN)
	
	# Se destruye el Label al finalizar la animación para no consumir memoria
	tween_texto.chain().tween_callback(label.queue_free)
