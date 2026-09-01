extends Sprite2D

@export var escala_final: Vector2 = Vector2(0.35, 0.35)

var tween_idle : Tween # Guardamos el tween de flotado para poder frenarlo

func _ready() -> void:
	# Ajuste automático si ya escalaste en el editor
	if scale != Vector2.ONE:
		escala_final = scale
		
	# Estado inicial: invisible y pequeño
	scale = Vector2.ZERO
	modulate.a = 0.0
	
	animar_aparicion()
	await get_tree().create_timer(6.0).timeout
	animar_desaparicion()

# --- ANIMACIÓN DE ENTRADA ---
func animar_aparicion() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_property(self, "scale", escala_final, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# Al terminar, empieza a flotar
	tween.chain().tween_callback(iniciar_flotado_idle)

# --- ANIMACIÓN DE ESPERA (FLOTAR) ---
func iniciar_flotado_idle() -> void:
	var pos_y = position.y
	tween_idle = create_tween().set_loops()
	tween_idle.tween_property(self, "position:y", pos_y - 6.0, 1.2).set_trans(Tween.TRANS_SINE)
	tween_idle.tween_property(self, "position:y", pos_y, 1.2).set_trans(Tween.TRANS_SINE)

# --- ANIMACIÓN DE SALIDA (DESAPARECER) ---
func animar_desaparicion() -> void:
	# 1. Frenamos el flotado para que no interfiera
	if tween_idle:
		tween_idle.kill()
	
	# 2. Creamos la animación de salida
	var tween_out = create_tween().set_parallel(true)
	
	# Se vuelve transparente
	tween_out.tween_property(self, "modulate:a", 0.0, 0.4)
	
	# Se encoge con un efecto de "anticipación" (EASE_IN)
	tween_out.tween_property(self, "scale", Vector2.ZERO, 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	
	# 3. Opcional: Borrar el logo o cambiar de escena al terminar
	tween_out.chain().tween_callback(queue_free)
