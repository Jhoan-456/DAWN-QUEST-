extends Area2D

@export var velocidad: float = 10.0 # Ajustada para que el movimiento de onda se aprecie fluido
@export var dano: float = 1
@export var desaceleracion: float = 150.0

@export var frecuencia_onda: float = 9
@export var amplitud_onda: float = 17.0

var direccion_vector: Vector2 = Vector2.RIGHT
var tiempo_transcurrido: float = 0.0

func _ready() -> void:
	# 🟢 Conecta las colisiones por CÓDIGO (evita duplicados si ya estaban conectadas)
	if not body_entered.is_connected(_on_impacto):
		body_entered.connect(_on_impacto)
	if not area_entered.is_connected(_on_impacto):
		area_entered.connect(_on_impacto)
	
	# Autodestrucción a los 3 segundos
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	tiempo_transcurrido += delta
	var vel_lineal = direccion_vector * velocidad
	var perpendicular = Vector2(-direccion_vector.y, direccion_vector.x)
	var vel_ondulante = perpendicular * (cos(tiempo_transcurrido * frecuencia_onda) * amplitud_onda * frecuencia_onda)
	global_position += (vel_lineal + vel_ondulante) * delta

# 🟢 Detección de impacto unificada
func _on_impacto(objeto: Node2D) -> void:
	# 1. Ignorar al jugador que dispara y a sus invocaciones
	if objeto.is_in_group("jugador") or objeto.is_in_group("hada_jugador"):
		return

	# 2. Buscar si la función de daño está en el nodo tocado o en su padre (para Hurtboxes)
	var objetivo: Node = objeto
	if not (objetivo.has_method("recibir_daño") or objetivo.has_method("tomar_dano") or objetivo.has_method("recibir_daño") or "vida" in objetivo):
		if objeto.get_parent() and (objeto.get_parent().has_method("recibir_daño") or objeto.get_parent().has_method("tomar_dano") or objeto.get_parent().has_method("recibir_danio") or "vida" in objeto.get_parent()):
			objetivo = objeto.get_parent()

	# 3. Aplicar el daño al objetivo detectado
	if objetivo.has_method("recibir_daño"):
		objetivo.recibir_daño(dano)
	elif objetivo.has_method("tomar_dano"):
		objetivo.tomar_dano(dano)
	elif objetivo.has_method("recibir_daño"):
		objetivo.recibir_daño(dano)
	elif "vida" in objetivo:
		objetivo.vida -= dano

	# 4. Destruir la burbuja tras impactar
	queue_free()
