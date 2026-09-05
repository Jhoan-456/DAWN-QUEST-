extends CharacterBody2D

@export var vel_seguimiento: float = 140.0
@export var vel_embestida: float = 400.0
@export var alcance_ataque: float = 35.0
@export var cadencia_ataque: float = 0.4

var dano: float = 4.0
var jugador: Node2D = null
var enemigo_objetivo: Node2D = null

var puede_atacar: bool = true
var en_embestida: bool = false
var offset_flotante: Vector2 = Vector2(-25, -30)


func _ready() -> void:
	add_to_group("súbdito_hada")
	jugador = get_tree().get_first_node_in_group("jugador")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if not jugador:
			return

	# Si está ejecutando el desplazamiento del campanazo
	if en_embestida:
		_procesar_embestida(delta)
		return

	# Buscar enemigo objetivo si no tiene uno
	if enemigo_objetivo == null or not is_instance_valid(enemigo_objetivo):
		enemigo_objetivo = buscar_enemigo_cercano()

	if enemigo_objetivo != null and is_instance_valid(enemigo_objetivo):
		var dist = global_position.distance_to(enemigo_objetivo.global_position)
		if dist > alcance_ataque:
			var dir = (enemigo_objetivo.global_position - global_position).normalized()
			velocity = dir * vel_seguimiento
		else:
			velocity = Vector2.ZERO
			if puede_atacar:
				atacar_enemigo(enemigo_objetivo)
	else:
		# Si no hay enemigos, flota al lado del jugador
		var pos_objetivo = jugador.global_position + offset_flotante
		var dist_jugador = global_position.distance_to(pos_objetivo)
		if dist_jugador > 15.0:
			var dir = (pos_objetivo - global_position).normalized()
			velocity = dir * vel_seguimiento
		else:
			velocity = Vector2.ZERO

	# Girar la vista del Hada según su movimiento
	if velocity.x != 0 and has_node("Sprite2D"):
		$Sprite2D.flip_h = velocity.x < 0

	move_and_slide()


# --- LÓGICA DEL CAMPANAZO ---
func redireccionar_a_enemigo() -> void:
	var nuevo_enemigo = buscar_enemigo_cercano()
	if nuevo_enemigo != null:
		enemigo_objetivo = nuevo_enemigo
		en_embestida = true
		
		# Golpea de inmediato al iniciar el desplazamiento
		atacar_enemigo(enemigo_objetivo)
		
		# Duración del desplazamiento rápido
		await get_tree().create_timer(0.25).timeout
		en_embestida = false


func _procesar_embestida(_delta: float) -> void:
	if enemigo_objetivo != null and is_instance_valid(enemigo_objetivo):
		var dir = (enemigo_objetivo.global_position - global_position).normalized()
		velocity = dir * vel_embestida
		move_and_slide()


# --- APLICAR DAÑO A ENEMIGOS ---
func atacar_enemigo(target: Node2D) -> void:
	if not puede_atacar or target == null or not is_instance_valid(target):
		return
		
	puede_atacar = false

	if target.has_method("recibir_daño"):
		target.recibir_daño(dano)
	elif target.has_method("recibir_dano"):
		target.recibir_dano(dano)
	elif "vida" in target:
		target.vida -= dano

	await get_tree().create_timer(cadencia_ataque).timeout
	puede_atacar = true


# --- BÚSQUEDA AUTOMÁTICA DE ENEMIGOS ---
func buscar_enemigo_cercano() -> Node2D:
	var lista_prioridades = ["bosses", "enemigos_dificil", "enemigos_medio", "enemigos_facil"]
	var enemigo_cercano: Node2D = null
	var dist_minima: float = 350.0 # Alcance máximo de detección

	for grupo in lista_prioridades:
		var enemigos = get_tree().get_nodes_in_group(grupo)
		for e in enemigos:
			if is_instance_valid(e):
				var d = global_position.distance_to(e.global_position)
				if d < dist_minima:
					dist_minima = d
					enemigo_cercano = e
		if enemigo_cercano != null:
			break

	return enemigo_cercano
