extends Node2D

@export var escena_jugador: PackedScene = preload("res://escenas/characters/personajes/BYTE/byte.tscn")

const PUERTO_BROADCAST = 8911
var udp_emisor = PacketPeerUDP.new()
var tiempo_broadcast: float = 0.0


func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_jugador_conectado)
		multiplayer.peer_disconnected.connect(_on_jugador_desconectado)
		
		udp_emisor.set_broadcast_enabled(true)
		udp_emisor.set_dest_address("255.255.255.255", PUERTO_BROADCAST)
		
		instanciar_jugador(1)


func _process(delta: float) -> void:
	if multiplayer.is_server():
		tiempo_broadcast += delta
		if tiempo_broadcast >= 1.0:
			tiempo_broadcast = 0.0
			udp_emisor.put_packet("PARTIDA_BYTE_HOST".to_utf8_buffer())


func _on_jugador_conectado(id: int) -> void:
	instanciar_jugador(id)


func _on_jugador_desconectado(id: int) -> void:
	if has_node(str(id)):
		get_node(str(id)).queue_free()


func instanciar_jugador(id: int) -> void:
	var jugador = escena_jugador.instantiate()
	jugador.name = str(id)
	jugador.global_position = Vector2(100 + (id * 30), 100)
	add_child(jugador)
