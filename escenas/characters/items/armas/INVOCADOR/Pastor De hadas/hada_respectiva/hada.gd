extends CharacterBody2D

@export var velocidad_movimiento: float = 130.0
@export var dano: float = 8.0
@export var cadencia_ataque: float = 1.0 # Segundos entre cada golpe
@export var radio_deteccion: float = 300.0
@export var rango_ataque: float = 40.0 # Qué tan cerca debe estar para golpear

var puede_atacar: bool = true
var objetivo_actual: CharacterBody2D = null
var jugador: CharacterBody2D = null

func _ready() -> void:
	add_to_group("hada_jugador")

func _physics_process(_delta: float) -> void:
# Si no se le asignó un jugador desde byte.gd, busca a cuál asociarse
	if not is_instance_valid(jugador):
		buscar_jugador()

	objetivo_actual = buscar_enemigo_cercano()

	# 1. MOVIMIENTO DIRECTO
	mover_hada()

	# 2. ATAQUE DIRECTO
	if is_instance_valid(objetivo_actual) and puede_atacar:
		if esta_tocando_objetivo():
			atacar_automatico()

func mover_hada() -> void:
	if is_instance_valid(objetivo_actual):
		# Va DIRECTO hacia el enemigo para chocar con él
		var direccion = (objetivo_actual.global_position - global_position).normalized()
		velocity = direccion * velocidad_movimiento
	elif is_instance_valid(jugador):
		# Sigue al jugador si se aleja más de 20px
		var distancia = global_position.distance_to(jugador.global_position)
		if distancia > 20.0:
			var direccion = (jugador.global_position - global_position).normalized()
			velocity = direccion * velocidad_movimiento
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func buscar_enemigo_cercano() -> CharacterBody2D:
	var grupos = ["bosses", "enemigos_dificil", "enemigos_medio", "enemigos_facil"]
	var enemigo_cercano: CharacterBody2D = null
	var distancia_minima: float = radio_deteccion

	for grupo in grupos:
		for enemigo in get_tree().get_nodes_in_group(grupo):
			# Validamos que exista y que realmente sea un CharacterBody2D
			if is_instance_valid(enemigo) and enemigo is CharacterBody2D:
				var dist = global_position.distance_to(enemigo.global_position)
				if dist < distancia_minima:
					distancia_minima = dist
					enemigo_cercano = enemigo as CharacterBody2D

	return enemigo_cercano


func buscar_jugador() -> void:
	# Si el hada no tiene jugador asignado, busca cuál es la autoridad del nodo
	var lista_jugadores = get_tree().get_nodes_in_group("jugador")
	for p in lista_jugadores:
		if is_instance_valid(p) and p is CharacterBody2D:
			# Compara si la autoridad de la red del jugador coincide con la del hada
			if p.get_multiplayer_authority() == get_multiplayer_authority():
				jugador = p as CharacterBody2D
				break
func atacar_automatico() -> void:
	puede_atacar = false

	if is_instance_valid(objetivo_actual):
		# AQUÍ LE HACE DAÑO DIRECTO AL ENEMIGO
		# Revisa cómo se llama tu función de daño en los enemigos y cámbiala si es necesario
		if objetivo_actual.has_method("recibir_daño"):
			objetivo_actual.recibir_daño(dano)
		elif objetivo_actual.has_method("recibir_dano"): # Por si le pusiste otro nombre
			objetivo_actual.recibir_dano(dano)
			
		print("¡El hada golpeó al enemigo!") # Para que veas en la consola que sí está atacando

	await get_tree().create_timer(cadencia_ataque).timeout
	puede_atacar = true
func esta_tocando_objetivo() -> bool:
	if not is_instance_valid(objetivo_actual):
		return false

	# 1. Distancia directa (para enemigos pequeños)
	if global_position.distance_to(objetivo_actual.global_position) <= rango_ataque:
		return true

	# 2. Colisión física (para Bosses grandes donde chocamos con su cuerpo antes de llegar al centro)
	for i in get_slide_collision_count():
		var colision = get_slide_collision(i)
		if colision.get_collider() == objetivo_actual:
			return true

	return false
