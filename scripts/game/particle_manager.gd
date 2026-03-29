# Particle Manager
# Block place ve line clear particle efektlerini yönetir

class_name ParticleManager
extends Node2D

# Particle ayarları
var particles_enabled: bool = true
var block_particles: Array = []  # Aktif particle'lar
var sprite_loader: SpriteSheetLoader

func _ready():
	# Sprite sheet loader oluştur
	sprite_loader = SpriteSheetLoader.new()
	add_child(sprite_loader)

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
				velocity.y += 500.0 * delta  # Yer çekimi: 500 piksel/saniye²
				particle.set_meta("velocity", velocity)
				# Pozisyonu güncelle
				if particle is Sprite2D:
					particle.position += velocity * delta
				elif particle is ColorRect:
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
func spawn_line_clear_particles(row_y: int, grid_offset: Vector2 = Vector2.ZERO):
	if not particles_enabled:
		return

	for x in range(10):  # Grid genişliği
		var pos = Vector2(x * 32 + 16, row_y * 32 + 16) + grid_offset  # Hücre merkezi + offset
		_spawn_block_explosion(pos, Color.WHITE)  # Beyaz particle'lar

# Tek bir blok için patlama efekti
func _spawn_block_explosion(pos: Vector2, color: Color):
	var particle_count = Constants.PARTICLE_COUNT_PER_BLOCK * 2  # 2 kat daha fazla particle

	print("Spawning explosion at: ", pos, " color: ", color)

	for i in range(particle_count):
		var particle = Sprite2D.new()
		particle.centered = false
		particle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Pixel art

		# Sprite sheet'ten doğru renkte solid sprite al
		if sprite_loader != null:
			particle.texture = sprite_loader.get_solid_sprite(color)
		else:
			# Fallback: ColorRect kullan
			particle = ColorRect.new()
			(particle as ColorRect).color = color
			(particle as ColorRect).size = Vector2(4, 4)

		# Bir piksel boyutu: 4 (32/8)
		# İki piksel boyutunda: 8x8
		if particle is Sprite2D:
			particle.scale = Vector2(1.0, 1.0)  # 8x8 -> 8x8 (bir piksel)
			particle.position = pos - Vector2(4, 4)
		else:
			(particle as ColorRect).size = Vector2(8, 8)
			(particle as ColorRect).position = pos - Vector2(4, 4)

		particle.z_index = 1000  # Çok yüksek z-index, ön planda olsun

		# Rastgele yön ve hız
		var angle = randf() * TAU  # 0-2PI
		var speed = 100.0 + randf() * 200.0  # 100-300 arası
		var velocity = Vector2(cos(angle), sin(angle)) * speed

		# Kısa yaşam ömrü
		var lifetime = 0.4 + randf() * 0.3  # 0.4-0.7 saniye

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
		if particle is Sprite2D:
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
