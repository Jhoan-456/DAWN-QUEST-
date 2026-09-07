extends Node2D

const PUERTO = 8910
var peer = ENetMultiplayerPeer.new()

# Ajusta esta ruta a tu escena del mundo
@export_file("*.tscn") var escena_mundo: String = "res://multijugador/mundo.tscn"

@onready var line_edit_ip: LineEdit = $Control/LineEdit


func _ready() -> void:
	# Escuchamos cuando la conexión del cliente es confirmada por el servidor
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


# --- BOTÓN CREAR PARTIDA (HOST) ---
func _on_host_pressed() -> void:
	var error = peer.create_server(PUERTO)
	if error != OK:
		print("❌ Error al crear servidor: ", error)
		return

	multiplayer.multiplayer_peer = peer
	print("🟢 Servidor iniciado en puerto ", PUERTO)
	
	# El Host cambia a la escena inmediatamente
	get_tree().change_scene_to_file(escena_mundo)


# --- BOTÓN UNIRSE (CLIENTE) ---
func _on_client_pressed() -> void:
	var ip = line_edit_ip.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"

	var error = peer.create_client(ip, PUERTO)
	if error != OK:
		print("❌ Error al intentar conectar: ", error)
		return

	multiplayer.multiplayer_peer = peer
	print("🟡 Conectando a ", ip, "...")
	# ⚠️ NO cambiamos de escena aquí. Esperamos la confirmación del servidor.


func _on_connected_to_server() -> void:
	print("✅ ¡Conexión establecida con el Host! Cargando mundo...")
	get_tree().change_scene_to_file(escena_mundo)


func _on_connection_failed() -> void:
	print("🚨 No se pudo conectar al Host. Revisa la IP y la red.")
