extends Node2D

# Variables requeridas por el script del jugador (byte.gd)
var dano: float = 4.0
var daño: float = 4.0:
	set(value):
		daño = value
		dano = value

var velocidad: float = 0.0

# Asigna aquí tu escena del Hada (CharacterBody2D)
@export var escena_hada: PackedScene = preload("res://escenas/characters/items/armas/INVOCADOR/Pastor De hadas/hada_respectiva/hada.tscn") # Ajusta la ruta a tu escena del Hada


func _ready() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if not jugador:
		queue_free()
		return

	# Verificar si el Hada ya existe en la partida
	var hada_existente = get_tree().get_first_node_in_group("súbdito_hada")

	if hada_existente == null:
		# 1. PRIMERA VEZ: Invocamos al Hada
		if escena_hada != null:
			var nueva_hada = escena_hada.instantiate()
			nueva_hada.global_position = jugador.global_position + Vector2(25, -25)
			nueva_hada.dano = dano
			jugador.get_parent().add_child(nueva_hada)
			print("🧚 ¡Hada invocada correctamente!")
	else:
		# 2. CAMPANAZO: El Hada ya existe, la hacemos embestir/redireccionarse
		hada_existente.dano = dano
		hada_existente.redireccionar_a_enemigo()
		print("🔔 ¡Campanazo! El hada se desplaza hacia un enemigo.")

	# Destruimos este nodo invisible de inmediato
	queue_free()
