extends Node2D

@export var escena_jugador: PackedScene = preload("res://escenas/characters/personajes/BYTE/byte.tscn") # Ruta a tu personaje byte.tscn

func _ready() -> void:
	# Si somos el servidor/host, escuchamos las conexiones entrantes
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_jugador_conectado)
		multiplayer.peer_disconnected.connect(_on_jugador_desconectado)
		
		# Instanciamos al Host (ID de la red = 1)
		instanciar_jugador(1)


func _on_jugador_conectado(id: int) -> void:
	instanciar_jugador(id)


func _on_jugador_desconectado(id: int) -> void:
	if has_node(str(id)):
		get_node(str(id)).queue_free()


func instanciar_jugador(id: int) -> void:
	var jugador = escena_jugador.instantiate()
	jugador.name = str(id)
	jugador.global_position = Vector2(100 + (id * 30), 100) # Separación inicial
	add_child(jugador)
