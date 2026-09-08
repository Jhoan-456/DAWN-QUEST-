extends Node2D

const PUERTO_JUEGO = 8910
const PUERTO_BROADCAST = 8911

var peer: ENetMultiplayerPeer = null
var udp_escucha: PacketPeerUDP = null
var buscando_partida: bool = false

@export_file("*.tscn") var escena_mundo: String = "res://multijugador/mundo.tscn"

@onready var line_edit_ip: LineEdit = $Control/LineEdit
@onready var label_mi_ip: Label = $Control/LabelmiIp
@onready var label_estado: Label = $Control/LabelEstado


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

	# Mostrar IP local del dispositivo
	var mi_ip = obtener_ip_local()
	label_mi_ip.text = "TU IP LAN: " + mi_ip


func _process(_delta: float) -> void:
	if buscando_partida:
		escuchar_broadcast_servidor()


# --- REINICIAR CONEXIONES PREVIAS ---
func limpiar_conexion() -> void:
	parar_busqueda_udp()
	
	# Si ya había una red activa, la cerramos para no generar conflicto de puertos
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


# --- OBTENER IP LOCAL ---
func obtener_ip_local() -> String:
	var direcciones = IP.get_local_addresses()
	for ip in direcciones:
		if not ":" in ip and ip != "127.0.0.1":
			if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
				return ip
	return "127.0.0.1"


# --- BOTÓN: CREAR PARTIDA (HOST) ---
func _on_host_pressed() -> void:
	limpiar_conexion()
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PUERTO_JUEGO)
	if error != OK:
		label_estado.text = "❌ Error al crear servidor."
		return

	multiplayer.multiplayer_peer = peer
	print("🟢 Servidor iniciado en puerto ", PUERTO_JUEGO)
	get_tree().change_scene_to_file(escena_mundo)


# --- BOTÓN: UNIRSE MANUALMENTE (CLIENTE) ---
func _on_client_pressed() -> void:
	var ip = line_edit_ip.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
		
	conectar_a_ip(ip)


# --- BOTÓN: BUSCAR PARTIDA LAN ---
func _on_btn_buscar_pressed() -> void:
	limpiar_conexion()
	
	udp_escucha = PacketPeerUDP.new()
	var error = udp_escucha.bind(PUERTO_BROADCAST)
	if error != OK:
		label_estado.text = "❌ Error al abrir radar UDP."
		return
		
	buscando_partida = true
	label_estado.text = "🔍 Buscando partidas en el Wi-Fi..."


func escuchar_broadcast_servidor() -> void:
	if udp_escucha != null and udp_escucha.is_bound():
		while udp_escucha.get_available_packet_count() > 0:
			var ip_servidor = udp_escucha.get_packet_ip()
			var bytes_paquete = udp_escucha.get_packet() # Vacía el paquete actual
			var mensaje = bytes_paquete.get_string_from_utf8()

			if mensaje == "PARTIDA_BYTE_HOST":
				label_estado.text = "¡Encontrado! Conectando a " + ip_servidor + "..."
				line_edit_ip.text = ip_servidor
				
				# Conectamos directamente a la IP encontrada
				conectar_a_ip(ip_servidor)
				break


func conectar_a_ip(ip_destino: String) -> void:
	limpiar_conexion()
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_destino, PUERTO_JUEGO)
	if error != OK:
		label_estado.text = "❌ Error al intentar conectar a " + ip_destino
		return

	multiplayer.multiplayer_peer = peer
	label_estado.text = "🟡 Conectando a " + ip_destino + "..."


func parar_busqueda_udp() -> void:
	buscando_partida = false
	if udp_escucha != null and udp_escucha.is_bound():
		udp_escucha.close()


func _on_connected_to_server() -> void:
	label_estado.text = "✅ ¡Conectado al Host!"
	get_tree().change_scene_to_file(escena_mundo)


func _on_connection_failed() -> void:
	label_estado.text = "🚨 No se pudo conectar al Host."
