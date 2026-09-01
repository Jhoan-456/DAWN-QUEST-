extends Control

@export var escena_a_cargar: String = "res://botones/pantalla_inicial.tscn"
var progreso: Array = []
var transicion_empezada : bool = false

# ─── MODIFICADO: Subimos a 4 segundos para que "la blanquita" vaya más lento
var tiempo_minimo : float = 7.0  
# ─── CORREGIDO: Debe empezar en 0.0 para que cuente el tiempo real desde el inicio
var tiempo_transcurrido : float = 0.1 

var carga_lista : bool = false
var nueva_escena : PackedScene
var tween_barra : Tween

var version : String = "BETA 0.0.1"

func _ready():
	if escena_a_cargar == "":
		return
	# Inicializamos la barra en 0
	$ProgressBar.value = 0
	ResourceLoader.load_threaded_request(escena_a_cargar)
	
	# El tween ahora usará los 4 segundos completos para rellenar la barra suavemente
	tween_barra = create_tween()
	tween_barra.tween_property($ProgressBar, "value", 120.0, tiempo_minimo).set_trans(Tween.TRANS_LINEAR)

func _process(delta):
	tiempo_transcurrido += delta
	# Ejemplo: Monitoreamos tu barra de carga (ajusta el nombre de tu barra)
	if $ProgressBar.value >= 100 and not transicion_empezada:
		transicion_empezada = true
		ejecutar_intro_transicion()
	
	# Si la PC ya terminó de cargar el mapa de fondo
	if not carga_lista:
		var estado = ResourceLoader.load_threaded_get_status(escena_a_cargar, progreso)
		if estado == ResourceLoader.THREAD_LOAD_LOADED:
			nueva_escena = ResourceLoader.load_threaded_get(escena_a_cargar)
			carga_lista = true

	# Cambiamos de escena SOLO cuando la barra termine (tiempo_transcurrido >= 4.0)
	if carga_lista and tiempo_transcurrido >= tiempo_minimo:
		get_tree().change_scene_to_packed(nueva_escena)
		set_process(false)
		
	# ─── ACTUALIZACIÓN DEL PORCENTAJE ───
	# clampi se asegura de que el número vaya de 0 a 100 al ritmo del Tween de la barra
	var porcentaje_actual = clampi($ProgressBar.value, 0, 100)
	$Porcentaje.text = str(porcentaje_actual) + "%" 
	
	# Muestra tu versión abajo
	$Version.text = "Version: " + str(version)
func ejecutar_intro_transicion():
	# 1. Bloqueamos la pantalla temporalmente
	$TransicionGlobal/PantallaNegra.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween_intro = create_tween()
	
	tween_intro.tween_property($TransicionGlobal/PantallaNegra, "color", Color(0.0, 0.0, 0.0, 1.0), 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_intro.tween_callback(func():
		$ProgressBar.visible = false 
		print("¡Pantalla oculta! Cambiando cosas por detrás...")
	)
	
	
	tween_intro.tween_property($TransicionGlobal/PantallaNegra, "color", Color(0.0, 0.0, 0.0, 0.0), 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 5. LIBERAR: Desbloqueamos los clics
	tween_intro.tween_callback(func():
		$TransicionGlobal/PantallaNegra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
# --- SCRIPT PARA CONTROLAR EL EFECTO IRIS ---
func ejecutar_efectodel_irirs():
	TransicionGlobal.ejecutar_efecto_irir(escena_a_cargar)
	
