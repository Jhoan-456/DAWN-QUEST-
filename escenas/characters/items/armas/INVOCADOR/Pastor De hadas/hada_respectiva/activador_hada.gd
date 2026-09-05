extends Node2D


# --- VARIABLES COMPATIBLES---
@export var texto_flotante_scene : PackedScene
var direccion_vector: Vector2 = Vector2.ZERO
var velocidad: float = 0.0
var dano: float = 4.0
var daño: float = 4.0:
	set(value):
		daño = value
		dano = value

# --- CONFIGURACIÓN DE LA INVOCACIÓN ---
@export var limite_maximo: int = 1 # Cambia este valor desde el Inspector si deseas más hadas
@export var escena_hada: PackedScene = preload("res://escenas/characters/items/armas/INVOCADOR/Pastor De hadas/hada_respectiva/hada.tscn")


func _ready() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if not jugador:
		queue_free()
		return

	# Obtenemos la lista actual de hadas en juego
	var hadas_existentes = get_tree().get_nodes_in_group("súbdito_hada")

	# 1. Si no hemos llegado al límite, invocamos una nueva
	if hadas_existentes.size() < limite_maximo:
		if escena_hada != null:
			var nueva_hada = escena_hada.instantiate()
			
			# Pequeña variación de posición para que no aparezcan superpuestas si hay varias
			var offset_aparicion = Vector2(randf_range(-15, 15), randf_range(-15, 15))
			nueva_hada.global_position = jugador.global_position + Vector2(25, -25) + offset_aparicion
			
			nueva_hada.dano = dano
			jugador.get_parent().add_child(nueva_hada)
			print("🧚 ¡Hada invocada! (", hadas_existentes.size() + 1, "/", limite_maximo, ")")

	# 2. Si ya alcanzamos el límite, ejecutamos el campanazo en TODAS las hadas invocadas
	else:
		for hada in hadas_existentes:
			if is_instance_valid(hada):
				hada.dano = dano
				if hada.has_method("redireccionar_a_enemigo"):
					hada.redireccionar_a_enemigo()
		print("🔔 ¡Campanazo! ", hadas_existentes.size(), " hada(s) embisten.")
				
		

	# Destruye el activador invisible
	queue_free()

func crear_texto_flotante(valor: String,color: Color) -> void:
	if not texto_flotante_scene: return
	
	var texto = texto_flotante_scene.instantiate()
	get_parent().add_child(texto)
	texto.global_position = global_position + Vector2(0, -20)
	texto.mostrar(valor, color)
