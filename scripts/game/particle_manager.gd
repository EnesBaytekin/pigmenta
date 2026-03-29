# Particle Manager
# Block place ve line clear particle efektlerini yönetir

class_name ParticleManager
extends Node2D

# Particle ayarları
var particles_enabled: bool = true
var block_particles: Array = []  # Aktif particle'lar

func _ready():
	pass

func _process(delta):
	# Debug: Particle sayısını yazdır (sadece ilk birkaç saniyede)
	if Engine.get_process_frames() % 60 == 0:  # Her saniye bir
		print("Active particles: ", block_particles.size())

	# Particle'ları güncelle
	var particles_to_remove = []
	for i in range(block_particles.size()):
		var particle = block_particles[i]
		if not is_instance_valid(particle):
			particles_to_remove.append(i)
			continue

		# Yaşam ömrü kontrolü
		if particle.has_meta("lifetime"):
			particle.set_meta("lifetime", particle.get_meta("lifetime") - delta)
			if particle.get_meta("lifetime") <= 0:
				particles_to_remove.append(i)
				continue

			# Yer çekimi efekti (velocity'yi güncelle)
			if particle.has_meta("velocity"):
				var velocity = particle.get_meta("velocity")
				velocity.y += Constants.PARTICLE_GRAVITY * delta  # Aşağı doğru ivme
				particle.set_meta("velocity", velocity)
				# Pozisyonu güncelle
				particle.position += velocity * delta

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

	print("Spawning particles: ", positions.size(), " positions")
	for i in range(positions.size()):
		var pos = positions[i]
		var color = colors[i] if i < colors.size() else Color.WHITE
		_spawn_block_explosion(pos, color)

# Line clear particle efekti spawn et
func spawn_line_clear_particles(row_y: int, layer_colors: Array, grid_offset: Vector2 = Vector2.ZERO):
	if not particles_enabled:
		return

	for x in range(10):  # Grid genişliği
		var pos = Vector2(x * 32 + 16, row_y * 32 + 16) + grid_offset  # Hücre merkezi + offset
		for color in layer_colors:
			_spawn_block_explosion(pos, color)  # Block explosion kullan, daha büyük etki

# Tek bir blok için patlama efekti
func _spawn_block_explosion(pos: Vector2, color: Color):
	var particle_count = Constants.PARTICLE_COUNT_PER_BLOCK * 2  # 2 kat daha fazla particle

	print("Spawning explosion at: ", pos, " color: ", color)

	for i in range(particle_count):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)  # Orta boyut
		particle.position = pos - Vector2(3, 3)  # Merkezleme
		particle.color = color
		particle.z_index = 1000  # Çok yüksek z-index, ön planda olsun

		# Rastgele yön ve hız (orta hız)
		var angle = randf() * TAU  # 0-2PI
		var speed = 100.0 + randf() * 150.0  # Orta hız patlama
		var velocity = Vector2(cos(angle), sin(angle)) * speed

		# Orta yaşam ömrü
		var lifetime = 0.5 + randf() * 0.3  # 0.5-0.8 saniye

		particle.set_meta("lifetime", lifetime)
		particle.set_meta("velocity", velocity)

		add_child(particle)
		block_particles.append(particle)

		# Tween ile animasyon (sadece fade ve scale)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)

		# Opacity animasyonu (fade out)
		tween.tween_property(particle, "modulate:a", 0.0, lifetime)

		# Scale animasyonu (küçülerek yok olma)
		tween.tween_property(particle, "scale", Vector2(0, 0), lifetime)

# Particle'ları temizle
func clear_all_particles():
	for particle in block_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	block_particles.clear()

# Particle enabled/disable
func set_particles_enabled(enabled: bool):
	particles_enabled = enabled
	if not enabled:
		clear_all_particles()
