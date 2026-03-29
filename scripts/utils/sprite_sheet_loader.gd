# Sprite Sheet Loader
# blocks.png dosyasından 8x8 pixel sprite'ları yükler

class_name SpriteSheetLoader
extends Node

# Texture referansı
var block_texture: Texture2D
var sprite_size: Vector2i = Vector2i(8, 8)  # Her sprite 8x8 pixel
var grid_size: Vector2i = Vector2i(4, 4)  # 4x4 grid

func _ready():
	# Texture'ı yükle
	block_texture = load("res://images/blocks.png")

	if block_texture == null:
		push_error("Failed to load blocks.png")

	# Not: Texture filter ayarı Sprite2D'lere yapılıyor (GridRenderer'da)
	# Bu yüzden burada conversion yapmaya gerek yok

# Aktif blok sprite'ını al (üst 2 satır - satır 0)
func get_active_sprite(color: Color) -> AtlasTexture:
	var sprite = AtlasTexture.new()
	sprite.atlas = block_texture

	var color_index = _get_color_index(color)
	var x = color_index + 1  # +1 çünkü 0. sütun siyah
	var y = 0  # İlk satır (active)

	sprite.region = Rect2(x * sprite_size.x, y * sprite_size.y, sprite_size.x, sprite_size.y)
	return sprite

# Solid blok sprite'ını al (satır 2 ve 3)
func get_solid_sprite(color: Color) -> AtlasTexture:
	var sprite = AtlasTexture.new()
	sprite.atlas = block_texture

	var sprite_pos = _get_solid_sprite_position(color)
	var x = sprite_pos.x
	var y = sprite_pos.y

	sprite.region = Rect2(x * sprite_size.x, y * sprite_size.y, sprite_size.x, sprite_size.y)
	return sprite

# Arkaplan sprite'ını al
func get_background_sprite() -> AtlasTexture:
	var sprite = AtlasTexture.new()
	sprite.atlas = block_texture

	sprite.region = Rect2(0, 0, sprite_size.x, sprite_size.y)  # (0,0) - Siyah
	return sprite

# Renk index'ini al (saf RGB renkleri için)
func _get_color_index(color: Color) -> int:
	# RGB katman renkleri için index (threshold 0.5)
	var is_red = color.r > 0.5 and color.g < 0.5 and color.b < 0.5
	var is_green = color.g > 0.5 and color.r < 0.5 and color.b < 0.5
	var is_blue = color.b > 0.5 and color.r < 0.5 and color.g < 0.5

	if is_red:
		return 0  # Kırmızı
	elif is_green:
		return 1  # Yeşil
	elif is_blue:
		return 2  # Mavi
	else:
		# Karışık renkler için dominant rengi bul
		if color.r >= color.g and color.r >= color.b:
			return 0  # Kırmızı dominant
		elif color.g >= color.r and color.g >= color.b:
			return 1  # Yeşil dominant
		else:
			return 2  # Mavi dominant

# Solid sprite pozisyonunu al (satır 2 ve 3)
func _get_solid_sprite_position(color: Color) -> Vector2i:
	# Renkleri tanımla (threshold 0.8 for clarity)
	var is_red = color.r > 0.8 and color.g < 0.2 and color.b < 0.2
	var is_green = color.g > 0.8 and color.r < 0.2 and color.b < 0.2
	var is_blue = color.b > 0.8 and color.r < 0.2 and color.g < 0.2

	var is_white = color.r > 0.8 and color.g > 0.8 and color.b > 0.8
	var is_yellow = color.r > 0.8 and color.g > 0.8 and color.b < 0.2
	var is_cyan = color.r < 0.2 and color.g > 0.8 and color.b > 0.8
	var is_magenta = color.r > 0.8 and color.g < 0.2 and color.b > 0.8

	# Satır 2: Saf renkler (Siyah, Kırmızı, Yeşil, Mavi)
	if is_red:
		return Vector2i(1, 2)  # Kırmızı
	elif is_green:
		return Vector2i(2, 2)  # Yeşil
	elif is_blue:
		return Vector2i(3, 2)  # Mavi

	# Satır 3: Karışık renkler (White, Cyan, Magenta, Yellow)
	elif is_white:
		return Vector2i(0, 3)  # White
	elif is_cyan:
		return Vector2i(1, 3)  # Cyan
	elif is_magenta:
		return Vector2i(2, 3)  # Magenta
	elif is_yellow:
		return Vector2i(3, 3)  # Yellow

	# Varsayılan: Siyah
	else:
		return Vector2i(0, 2)  # Siyah
