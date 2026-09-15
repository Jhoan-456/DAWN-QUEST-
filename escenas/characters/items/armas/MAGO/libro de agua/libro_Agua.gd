extends Area2D

var jugador_cerca: bool = false
var jugador_ref: Node2D = null # Guardamos la referencia directa del jugador

# Variables para controlar nuestra animación por código
var tween_flote : Tween
var posicion_y_original : float

var flecha : Sprite2D
var sprite_principal : Sprite2D

@export_group("ATRIBUTOS DEL ARMA DEFAULT")
@export var textura_normal : Texture2D
@export var textura_seleccionado : Texture2D
@export var escena_bala : PackedScene # Asigna aquí el proyectil/gota de agua en el Inspector
@export var costo_energia: float = 0.8 # Bajo costo por bala para sostener la alta cadencia
@export var es_clase_rango: bool = false
@export var es_clase_mele: bool = false
@export var es_clase_mago: bool = true # 🧙‍♂️ Marcado como arma de Mago
@export var es_clase_invocador: bool = false
@export var nombre_arma: String = "Libro de Agua" # 📖 Nombre oficial

@export_group("ESTADÍSTICAS DEL ARMA")
@export var dano_base: float = 1.2 # 💥 Daño bajo por proyectil
@export var escalado_inteligencia: float = 0.30 # 🧠 Escalado equilibrado para ataques ráfaga
@export var escalado_fuerza: float = 0.0
@export var cadencia_base: float = 0.09 # ⚡ ¡Cadencia descomunal! (0.09s entre disparos)
@export var multiplicador_vel_proyectil: float = 1.4 # 🚀 Agua a alta velocidad

# --- EXTRAS ---
@export var aplica_quemadura: bool = false # 💧 Desactivado (es agua)
@export var duracion_quemadura: float = 0.0


func _on_body_entered(body):
	if body.is_in_group("jugador"):
		jugador_cerca = true
		jugador_ref = body
		if sprite_principal and textura_seleccionado:
			sprite_principal.texture = textura_seleccionado
		if flecha:
			flecha.visible = true
			iniciar_animacion_flecha()
		
		
func _on_body_exited(body):
	if body.is_in_group("jugador"):
		jugador_cerca = false
		jugador_ref = null
		if sprite_principal and textura_normal:
			sprite_principal.texture = textura_normal
		if flecha:
			flecha.visible = false
			detener_animacion_flecha()
		
		
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
	if jugador_cerca and is_instance_valid(jugador_ref) and Input.is_action_just_pressed("interactuar"):
		if jugador_ref.has_method("equipar_arma"):
			jugador_ref.equipar_arma(self)
			queue_free() # Borramos el arma del suelo
	
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
