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
	var particle_count = Constants.PARTICLE_COUNT_PER_BLOCK

	for i in range(particle_count):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)  # Biraz daha büyük
		particle.position = pos - Vector2(3, 3)  # Merkezleme
		particle.color = color
		particle.z_index = 50

		# Rastgele yön ve hız
		var angle = randf() * TAU  # 0-2PI
		var speed = randf() * Constants.PARTICLE_EXPLOSION_SPEED * 0.3
		var velocity = Vector2(cos(angle), sin(angle)) * speed

		# Hedef pozisyon hesapla
		var lifetime = Constants.PARTICLE_LIFETIME * 1.5  # Daha uzun süre görünsün
		var target_pos = pos + velocity * lifetime

		particle.set_meta("lifetime", lifetime)

		add_child(particle)
		block_particles.append(particle)

		# Tween ile animasyon
		var tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)

		# Pozisyon animasyonu
		tween.tween_property(particle, "position", target_pos - Vector2(3, 3), lifetime)

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
