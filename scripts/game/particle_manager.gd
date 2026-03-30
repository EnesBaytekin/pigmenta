# Particle Manager
# Block place ve line clear particle efektlerini yönetir

class_name ParticleManager
extends Node2D

# Particle ayarları
var particles_enabled: bool = true
var block_particles: Array = []  # Aktif particle'lar
var line_highlights: Array = []  # Line clear highlight'ları

func _process(delta):
	# Particle'ları güncelle
	var particles_to_remove = []
	for i in range(block_particles.size()):
		var particle = block_particles[i]
		if not is_instance_valid(particle):
			particles_to_remove.append(i)
			continue

		# Hız ve pozisyon güncelle
		if particle.has_meta("velocity"):
			var velocity = particle.get_meta("velocity")

			# Yavaşlama (friction)
			var friction = 2.0  # Hız azalma çarpanı
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta * 60.0)  # frame-rate bağımsız
			particle.set_meta("velocity", velocity)

			# Pozisyonu güncelle
			if particle is ColorRect:
				particle.position += velocity * delta

			# Hız çok düşükse particle'ı kaldır
			if velocity.length() < 1.0:
				particles_to_remove.append(i)

	# Ölen particle'ları temizle (tersten, index kaymasın diye)
	particles_to_remove.reverse()
	for i in particles_to_remove:
		if is_instance_valid(block_particles[i]):
			block_particles[i].queue_free()
		block_particles.remove_at(i)

# Block place particle efekti spawn et
func spawn_block_place_particles(positions: Array, colors: Array):
	if not particles_enabled:
		return

	print("Particle Manager: Spawning ", positions.size(), " cells")
	for i in range(positions.size()):
		var pos = positions[i]
		var color = colors[i] if i < colors.size() else Color.WHITE
		print("  Cell ", i, " at ", pos, " color ", color)
		_spawn_cell_explosion(pos, color)

# Line clear highlight efekti spawn et
func spawn_line_clear_particles(row_indices: Array, grid_offset: Vector2 = Vector2.ZERO):
	if not particles_enabled:
		return

	# Satırları highlight'la (beyaz çizgi olarak)
	for row_y in row_indices:
		_spawn_line_highlight(row_y, grid_offset)

# Tek bir hücre için patlama efekti (çevresindeki 28 pixelden particle)
func _spawn_cell_explosion(cell_pos: Vector2, cell_color: Color):
	print("    Spawning explosion at ", cell_pos, " color ", cell_color)

	# Cell pozisyonu (hücrenin sol üst köşesi)
	var cell_x = int(cell_pos.x)
	var cell_y = int(cell_pos.y)

	# 8x8 hücrenin çevresindeki piksellerin pozisyonları
	var perimeter_positions = _get_cell_perimeter_positions(Vector2i(cell_x, cell_y))

	print("    Perimeter positions: ", perimeter_positions.size())

	for offset_pos in perimeter_positions:
		var particle = ColorRect.new()
		particle.size = Vector2(1, 1)  # 1 piksel boyutu
		particle.position = cell_pos + offset_pos

		# Renk: base renk + hafif varyasyon
		var color_variation = randf_range(-0.2, 0.2)  # -0.2 ile +0.2 arası değişim
		var particle_color = Color(
			clamp(cell_color.r + color_variation, 0.0, 1.0),
			clamp(cell_color.g + color_variation, 0.0, 1.0),
			clamp(cell_color.b + color_variation, 0.0, 1.0),
			1.0
		)
		particle.color = particle_color

		particle.z_index = 1000  # Ön planda

		# Rastgele yöne başlangıç hızı
		var angle = randf() * TAU  # 0-2PI
		var speed = 50.0 + randf() * 50.0  # 50-100 arası başlangıç hızı
		var velocity = Vector2(cos(angle), sin(angle)) * speed

		particle.set_meta("velocity", velocity)

		add_child(particle)
		block_particles.append(particle)

# 8x8 hücrenin çevresindeki piksellerin pozisyonlarını döndür (28 pixel)
func _get_cell_perimeter_positions(cell_pos: Vector2i) -> Array:
	var positions = []

	# Üst kenar: (0,0)'dan (7,0)'ya kadar - 8 pixel
	for x in range(8):
		positions.append(Vector2(x, 0))

	# Sağ kenar: (7,1)'den (7,7)'ye kadar - 7 pixel
	for y in range(1, 8):
		positions.append(Vector2(7, y))

	# Alt kenar: (6,7)'den (0,7)'ye kadar - 7 pixel
	for x in range(6, -1, -1):
		positions.append(Vector2(x, 7))

	# Sol kenar: (0,6)'dan (0,1)'e kadar - 6 pixel
	for y in range(6, 0, -1):
		positions.append(Vector2(0, y))

	return positions

# Satır highlight efekti (bembeyaz çizgi)
func _spawn_line_highlight(row_y: int, grid_offset: Vector2):
	var highlight = ColorRect.new()
	highlight.color = Color.WHITE
	highlight.size = Vector2(80, 8)  # 10 hücre * 8 pixel = 80x8
	highlight.position = Vector2(0, row_y * 8) + grid_offset
	highlight.z_index = 999  # Particle'ların hemen arkasında

	add_child(highlight)
	line_highlights.append(highlight)

	# 0.3 saniye sonra kaldır (daha uzun highlight)
	var tween = create_tween()
	tween.set_parallel(false)
	tween.tween_interval(0.3)  # 300ms bekle
	tween.tween_callback(func():
		if is_instance_valid(highlight):
			highlight.queue_free()
			line_highlights.erase(highlight)
	)

# Particle'ları temizle
func clear_all_particles():
	for particle in block_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	block_particles.clear()

	for highlight in line_highlights:
		if is_instance_valid(highlight):
			highlight.queue_free()
	line_highlights.clear()

# Particle enabled/disable
func set_particles_enabled(enabled: bool):
	particles_enabled = enabled
	if not enabled:
		clear_all_particles()
