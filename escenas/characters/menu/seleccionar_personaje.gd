extends Control

# 🟢 REFERENCIAS A NODOS
@onready var sprite_finnes: AnimatedSprite2D = $ConenerdorFinnes/AnimatedSprite2D
@onready var boton_finnes: Button = $ConenerdorFinnes/BotonFinnes

@onready var sprite_byte: AnimatedSprite2D = $ConenerdorByte/AnimatedSprite2D
@onready var boton_byte: Button = $ConenerdorByte/BotonByte

@onready var vbox_stats: VBoxContainer = $VBoxContainer
@onready var label_nombre: Label = $VBoxContainer/nombre
@onready var label_vida: Label = $VBoxContainer/vida
@onready var label_energia: Label = $VBoxContainer/energia
@onready var label_escudo: Label = $VBoxContainer/escudo
@onready var label_fuer: Label =$VBoxContainer/fuerza
@onready var label_inteli: Label =$VBoxContainer/inteligencia
@onready var label_velociataq: Label =$VBoxContainer/velocidad_ataq
@onready var label_velociproyec: Label =$VBoxContainer/velocidad_proyec
@onready var label_velocimovimi: Label =$VBoxContainer/velocidad_movi
@onready var label_probabicriti: Label =$VBoxContainer/probabili_critic
@onready var label_suerte: Label = $VBoxContainer/suerte


@onready var boton_empezar: Button = $Button
@onready var cartel: Node = $tit

var personaje_seleccionado: String = ""

# 📌 VARIABLES PARA CONTROLAR EL MOVIMIENTO DESDE LA DERECHA
var pos_original_stats: Vector2
var pos_original_boton: Vector2
var pos_oculta_stats: Vector2
var pos_oculta_boton: Vector2

var tween_desplazamiento: Tween

# 📊 DATOS DE ESTADÍSTICAS
var datos_personajes = {
	"Byte": {
		"nombre": "Byte",
		"vida": "160",
		"escudo": "150",
		"energia": "400",
		"fuerza": "5",
		"inteligencia": "9",
		"velocidad_ataque": "6.5",
		"velocidad_proyectil": "14.0",
		"velocidad_movimiento": "10.0",
		"probabilidad_critico": "1.5%",
		"suerte": "1.5%",
		"ruta": "res://escenas/characters/personajes/BYTE/byte.tscn"
	},
	"Finnes": {
		"nombre": "NOMBRE: Finnes",
		"vida": "VIDA: 80",
		"escudo": "ESCUDO: 20",
		"energia": "ENERGIA: 120",
		"ruta": "res://escenas/characters/personajes/FINNES/finnes.tscn"
	}
}

func _ready() -> void:
	# 1. GUARDAR POSICIONES ORIGINALES Y CALCULAR POSICIONES FUERA DE PANTALLA
	pos_original_stats = vbox_stats.position
	pos_original_boton = boton_empezar.position
	
	# Sumamos 500 píxeles en X para esconderlos bien a la derecha
	pos_oculta_stats = pos_original_stats + Vector2(500, 0)
	pos_oculta_boton = pos_original_boton + Vector2(500, 0)
	
	# Colocamos la interfaz fuera de la pantalla al arrancar
	vbox_stats.position = pos_oculta_stats
	boton_empezar.position = pos_oculta_boton
	
	# 2. ASEGURAR ANIMACIONES IDLE
	sprite_finnes.play("idle")
	sprite_byte.play("idle")
	
	# 3. CONECTAR SEÑALES
	boton_finnes.mouse_entered.connect(_on_finnes_hover)
	boton_finnes.mouse_exited.connect(_on_finnes_unhover)
	boton_finnes.pressed.connect(_on_finnes_click)
	
	boton_byte.mouse_entered.connect(_on_byte_hover)
	boton_byte.mouse_exited.connect(_on_byte_unhover)
	boton_byte.pressed.connect(_on_byte_click)
	
	boton_empezar.pressed.connect(_on_empezar_pressed)
	
	iniciar_cartel()

func iniciar_cartel() -> void:
	if cartel:
		var pos_y = cartel.position.y
		var tween = create_tween()
		tween.tween_property(cartel, "position:y", pos_y + 150, 1.0)\
			.set_trans(Tween.TRANS_QUINT)\
			.set_ease(Tween.EASE_OUT)

# ==========================================
# 🐟 EVENTOS DE FINNES
# ==========================================
func _on_finnes_hover() -> void:
	if personaje_seleccionado != "Finnes":
		sprite_finnes.play("seleccionado")

func _on_finnes_unhover() -> void:
	if personaje_seleccionado != "Finnes":
		sprite_finnes.play("idle")

func _on_finnes_click() -> void:
	personaje_seleccionado = "Finnes"
	sprite_finnes.play("seleccion_tocado")
	sprite_byte.play("idle")
	mostrar_estadisticas("Finnes")

# ==========================================
# 🖥️ EVENTOS DE BYTE
# ==========================================
func _on_byte_hover() -> void:
	if personaje_seleccionado != "Byte":
		sprite_byte.play("seleccionado")

func _on_byte_unhover() -> void:
	if personaje_seleccionado != "Byte":
		sprite_byte.play("idle")

func _on_byte_click() -> void:
	personaje_seleccionado = "Byte"
	sprite_byte.play("seleccion_tocado")
	sprite_finnes.play("idle")
	mostrar_estadisticas("Byte")

# ==========================================
# ⚙️ ANIMACIÓN DE DESPLAZAMIENTO (SLIDE)
# ==========================================
func mostrar_estadisticas(nombre_pers: String) -> void:
	var data = datos_personajes[nombre_pers]
	label_nombre.text = data["nombre"]
	label_vida.text = data["vida"]
	label_energia.text = data["energia"]
	label_escudo.text = data["escudo"]
	label_fuer.text = data["fuerza"]
	label_inteli.text = data["inteligencia"]
	label_velociataq.text = data["velocidad_ataque"]
	label_velociproyec.text = data["velocidad_proyectil"]
	label_velocimovimi.text = data["velocidad_movimiento"]
	label_probabicriti.text = data["probabilidad_critico"]
	label_suerte.text = data["suerte"]
	
	# Cancelamos la animación previa si el jugador hace clics muy rápidos
	if tween_desplazamiento and tween_desplazamiento.is_running():
		tween_desplazamiento.kill()
		
	tween_desplazamiento = create_tween().set_parallel(true)
	
	# Deslizar VBoxContainer hacia su posición original desde la derecha
	tween_desplazamiento.tween_property(vbox_stats, "position:x", pos_original_stats.x, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	# Deslizar Botón Empezar con un ligero retraso sutil para dar estilo UI
	tween_desplazamiento.tween_property(boton_empezar, "position:x", pos_original_boton.x, 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func ocultar_estadisticas() -> void:
	if tween_desplazamiento and tween_desplazamiento.is_running():
		tween_desplazamiento.kill()
		
	tween_desplazamiento = create_tween().set_parallel(true)
	
	# Regresar los paneles a la derecha fuera de la pantalla
	tween_desplazamiento.tween_property(vbox_stats, "position:x", pos_oculta_stats.x, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
		
	tween_desplazamiento.tween_property(boton_empezar, "position:x", pos_oculta_boton.x, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)

# ==========================================
# 🚀 BOTÓN EMPEZAR + TRANSICIONES GLOBALES
# ==========================================
func _on_empezar_pressed() -> void:
	if personaje_seleccionado == "": return
	
	# 1. Guardar la ruta del personaje elegido
	Datos.ruta_personaje_seleccionado = datos_personajes[personaje_seleccionado]["ruta"]
	
	# 2. Ruta exacta del nivel al que vas a ir
	var escena_destino = "res://escenas/characters/maps/GeneradorNivel.tscn"
	
	# 3. Elegir una transición al azar (0, 1 o 2) y cambiar de escena
	TransicionGlobal.transicion_actual = randi() % 3
	TransicionGlobal.cambiar_escena(escena_destino)
