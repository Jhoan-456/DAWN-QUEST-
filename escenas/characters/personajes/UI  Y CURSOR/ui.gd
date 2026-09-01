extends CanvasLayer

# --- CONTROLES (Tu lógica original) ---
signal enviar_joystick(j: Joystick)
@onready var joystick = $Joystick
signal estado_disparo_cambiado(esta_presionado: bool)

# --- BARRAS DE ESTADO (Nuevo sistema) ---
@export var jugador: CharacterBody2D 

var vida = 20
var Escudo = 20
var Energia = 150

@onready var barra_vida: TextureProgressBar =$HBoxContainer/HBoxVida/Barra_vida
@onready var barra_escudo: TextureProgressBar = $HBoxContainer/HBoxEscudo/Barra_escudo
@onready var barra_energia: TextureProgressBar = $HBoxContainer/HBoxEnergia/Barra_Energia

@onready var texto_vida: Label = $HBoxContainer/HBoxVida/Barra_vida/LabelVida
@onready var texto_escudo: Label = $HBoxContainer/HBoxEscudo/Barra_escudo/LabelEscudo
@onready var texto_energia: Label = $HBoxContainer/HBoxEnergia/Barra_Energia/LabelEnergia


func _ready() -> void:
	# 1. Ejecuta tu lógica original del joystick
	enviar_joystick.emit(joystick)
	
	# 2. Conecta y configura las nuevas barras si el jugador existe
	if jugador:
		jugador.stats_cambiadas.connect(actualizar_interfaz)
		
		barra_vida.max_value = jugador.max_vida
		barra_escudo.max_value = jugador.max_escudo
		barra_energia.max_value = jugador.max_energia
		
		# Sincroniza los textos y tamaños por primera vez
		actualizar_interfaz()


func actualizar_interfaz() -> void:
	if not jugador: return
	
	# Animación de las barras en paralelo (0.2 segundos de transición)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(barra_vida, "value", jugador.vida, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(barra_escudo, "value", jugador.Escudo, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(barra_energia, "value", jugador.Energia, 0.2).set_trans(Tween.TRANS_SINE)
	
	# Actualización de los textos numéricos internos (Ej: "8/8")
	texto_vida.text = str(int(jugador.vida)) + "/" + str(int(jugador.max_vida))
	texto_escudo.text = str(int(jugador.Escudo)) + "/" + str(int(jugador.max_escudo))
	texto_energia.text = str(int(jugador.Energia)) + "/" + str(int(jugador.max_energia))

# En el script de tu UI:

# --- 🔘 BOTONES DE ACCIÓN (Tu lógica original limpia) ---

func _on_atacar_pressed() -> void:
	$Atacar.modulate.a = 0.5
	estado_disparo_cambiado.emit(true) # 👈 Avisa que estás presionando

func _on_atacar_released() -> void:
	$Atacar.modulate.a = 1.0
	estado_disparo_cambiado.emit(false) # 👈 Avisa que soltaste
	

func _on_cambiar_pressed() -> void:
	$cambiar.modulate.a = 0.5
	estado_disparo_cambiado.emit(true) # 👈 Avisa que estás presionando

func _on_cambiar_released() -> void:
	$cambiar.modulate.a = 1.0
	estado_disparo_cambiado.emit(false) # 👈 Avisa que soltaste
