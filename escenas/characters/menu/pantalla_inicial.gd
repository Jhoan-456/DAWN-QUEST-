extends Control

# ─── VARIABLES DE CONTROL ───
var menu_activo : bool = false        # Controla el menú horizontal (> o <)
var menu_vertical_abierto : bool = false # NUEVO: Controla si el menú vertical está desplegado
var tween_movimiento : Tween          # Anti-spam menú horizontal
var tween_vertical : Tween            # Anti-spam menú vertical

# Guardamos las posiciones originales de fábrica (X e Y)
var x_original_config : float
var x_original_salir : float
var x_original_novedades : float

var y_original_iniciar : float
var y_original_jugar : float
var y_original_multi : float
var y_original_guard : float

var transicion_empezada : bool = false
@export var escena_a_cargar: String = "res://escenas/characters/maps/MAPA.tscn"
@export var escena_ajustes = preload("res://escenas/characters/menu/menuAjustes.tscn")
@export var escena_linea = preload("res://escenas/characters/menu/menu_linea.tscn")
@export var escena_salir = preload("res://escenas/characters/menu/menuSalir.tscn")
@onready var cartel = $Titulo
@onready var cartel_2 = $Titulo_2

func _ready() -> void:
	iniciar()
	
	animar_parpadeo_texto_boton()
	
	# Conexiones de señales
	$iniciar.pressed.connect(_on_ini_pressed)
	$">".pressed.connect(_on_ini_pressed_2)
	
	# Guardamos posiciones originales X del menú horizontal
	x_original_config = $config.position.x
	x_original_salir = $salir.position.x
	x_original_novedades = $Nove.position.x
	
	# Guardamos posiciones originales Y del menú vertical
	y_original_iniciar = $iniciar.position.y
	y_original_jugar = $jugar.position.y
	y_original_multi = $multi.position.y
	y_original_guard = $guard.position.y
	
	$">".text = ">"
	
	$guard.visible = false
	$Nove.visible = false
	
	$jugar.pressed.connect(_on_pressed)
	
func _on_pressed() -> void:
	if transicion_empezada:
		return
	transicion_empezada = true
	ejecutar_intro_transicion()
		
func animar_parpadeo_texto_boton():
	var tween = create_tween().set_loops()
	var color_visible = Color(1, 1, 1, 1)
	var color_invisible = Color(1.0, 1.0, 1.0, 0.051)
	
	tween.tween_method(
		func(c): $iniciar.add_theme_color_override("font_color", c), 
		color_visible, 
		color_invisible, 
		0.5
	).set_trans(Tween.TRANS_SINE)
	
	tween.tween_method(
		func(c): $iniciar.add_theme_color_override("font_color", c), 
		color_invisible, 
		color_visible, 
		0.5
	).set_trans(Tween.TRANS_SINE)

# ─── MENÚ VERTICAL (Iniciar, Jugar, Multi) ───
func _on_ini_pressed():
	# 🔒 CONTROL ANTI-SPAM: Si se están moviendo, ignoramos el clic
	if tween_vertical and tween_vertical.is_running():
		return
		
	# Alternamos el estado del menú vertical
	menu_vertical_abierto = !menu_vertical_abierto
		
	tween_vertical = create_tween().set_parallel(true)
	
	var distancia : float = 180.0
	var duration : float = 1.0
	
	var destino_ini_y : float
	var destino_jugar : float
	var destino_multi : float
	var destino_guard :  float
	
	if menu_vertical_abierto:
		# El botón iniciar baja, jugar y multi suben
		destino_ini_y = y_original_iniciar + distancia
		destino_jugar = y_original_jugar - distancia
		destino_multi = y_original_multi - distancia
		destino_guard = y_original_guard - distancia
	else:
		# Todo regresa a su posición original de fábrica de forma segura
		destino_ini_y = y_original_iniciar
		destino_jugar = y_original_jugar
		destino_multi = y_original_multi
		destino_guard = y_original_guard
	
	tween_vertical.tween_property($iniciar, "position:y", destino_ini_y, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween_vertical.tween_property($jugar, "position:y", destino_jugar, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_vertical.tween_property($multi, "position:y", destino_multi, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween_vertical.tween_property($guard, "position:y", destino_guard, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
# ─── MENÚ HORIZONTAL (Botón >, Config, Salir) ───
func _on_ini_pressed_2():
	if tween_movimiento and tween_movimiento.is_running():
		return 
	
	menu_activo = !menu_activo
	
	var distancia : float = 170.0
	var duracion : float = 1.0
	
	tween_movimiento = create_tween().set_parallel(true)
	
	var destino_config : float
	var destino_salir : float
	var destino_novedad : float
	
	if menu_activo:
		$">".text = "<"
		destino_config = x_original_config + distancia
		destino_salir = x_original_salir + distancia
		destino_novedad = x_original_novedades + distancia
		
	else:
		$">".text = ">"
		destino_config = x_original_config
		destino_salir = x_original_salir
		destino_novedad = x_original_novedades
		
	tween_movimiento.tween_property($config, "position:x", destino_config, duracion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_movimiento.tween_property($salir, "position:x", destino_salir, duracion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween_movimiento.tween_property($Nove, "position:x", destino_novedad, duracion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ─── CERRAR MENÚ VERTICAL AL CLICKEAR FUERA ───
func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		# SI EL MENÚ VERTICAL ESTÁ ABIERTO...
		if menu_vertical_abierto:
			# ...y el clic NO fue sobre iniciar, jugar ni multi:
			if not $iniciar.get_global_rect().has_point(event.global_position) and \
			   not $jugar.get_global_rect().has_point(event.global_position) and \
			   not $multi.get_global_rect().has_point(event.global_position) and \
			   not $guard.get_global_rect().has_point(event.global_position):
				# 🔒 NUEVA EXCEPCIÓN: Si además estás tocando el botón ">", "config" o "salir",
				# NO cerramos el menú vertical, dejamos que el menú horizontal maneje su propio clic.
				if $">".get_global_rect().has_point(event.global_position) or \
				   $config.get_global_rect().has_point(event.global_position) or \
				   $salir.get_global_rect().has_point(event.global_position) or \
				   $Nove.get_global_rect().has_point(event.global_position):
					return # Ignora el resto de esta función y no cierra el vertical
				
				_on_ini_pressed() # Si diste clic en cualquier otra parte vacía, ahí sí se cierra
func ejecutar_intro_transicion():
	TransicionGlobal.cambiar_escena(escena_a_cargar)
func iniciar():
	var posicion_inicial_y = cartel.position.y
	var posicion_inicial_2_y = cartel_2.position.y
	var posicion_final_y = posicion_inicial_y + 300
	var posicion_final_2_y = posicion_inicial_2_y + 300
	var tween = create_tween()
	tween.tween_property(cartel, "position:y", posicion_final_y, 1)\
		.set_trans(Tween.TRANS_QUINT)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(cartel_2, "position:y", posicion_final_2_y, 0.9)\
		.set_trans(Tween.TRANS_QUINT)\
		.set_ease(Tween.EASE_OUT)
	pass 

func _on_config_pressed() -> void:
	# 1. Creamos una instancia del menú
	var menu = escena_ajustes.instantiate()
	
	# 2. Lo añadimos a la escena actual para que aparezca
	add_child(menu)
	pass # Replace with function body.
	
func _on_multi_pressed() -> void:
	TransicionGlobal.denegar_boton(self, "¡ESTA FUNCION NO ESTA DISPONIBLE!")
func _on_salir_pressed() -> void:
	var menu_salir = escena_salir.instantiate()
	add_child(menu_salir)
	
	pass # Replace with function body.
