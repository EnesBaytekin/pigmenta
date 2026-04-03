# Game Setup Menu
# Pixel art blok butonları ile

extends Control

# Font
@onready var pixel_font: FontFile = preload("res://textures/fonts/pixy.ttf")

# Sprite loader
var sprite_loader: SpriteSheetLoader

# Renk seçenekleri
var all_colors: Array = [
	Color.RED,
	Color.GREEN,
	Color.BLUE,
	Color.YELLOW,
	Color.CYAN,
	Color.MAGENTA,
	Color.ORANGE,
	Color.PURPLE
]

var rgb_colors: Array = [Color.RED, Color.GREEN, Color.BLUE]

# Mevcut seçimler
var current_player_count: int = 1
var current_color_count: int = 2
var current_side_by_side: bool = false
var current_block_colors: Array = []
var current_player_colors: Array = []
var current_handicap: int = 0

# UI elementleri
var title_label: Label
var options_container: VBoxContainer

func _ready():
	# Sprite loader
	sprite_loader = SpriteSheetLoader.new()

	# Varsayılan değerler
	current_player_count = 1
	current_color_count = 2
	current_side_by_side = false
	current_handicap = 0
	current_block_colors = [Color.RED, Color.GREEN]
	current_player_colors = [Color.RED]

	# Arkaplan
	RenderingServer.set_default_clear_color(Color(0.1, 0.1, 0.1))

	# Pixel art ayarı
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# UI oluştur
	_create_pixel_menu()

	# Font uygula
	_apply_pixel_font()

	# İlk güncelleme
	_update_menu()

func _create_pixel_menu():
	# Başlık
	title_label = Label.new()
	title_label.text = "NEW GAME"
	title_label.position = Vector2(80, 10)
	title_label.custom_minimum_size = Vector2(160, 10)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)

	# Seçenekler konteyneri
	options_container = VBoxContainer.new()
	options_container.position = Vector2(80, 22)
	options_container.custom_minimum_size = Vector2(160, 42)
	options_container.add_theme_constant_override("separation", 2)
	add_child(options_container)

	# Seçenekleri oluştur
	_create_block_option("Players", "1", _on_player_change)
	_create_block_option("Colors", "2", _on_color_change)
	_create_block_option("Mode", "OVERLAP", _on_mode_change)
	_create_block_option("Handicap", "0", _on_handicap_change)

	# Start butonu
	_create_start_button()

func _create_block_option(label_text: String, value_text: String, callback: Callable):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(160, 8)

	# Label
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(60, 8)
	hbox.add_child(label)

	# Value
	var value_label = Label.new()
	value_label.text = value_text
	value_label.name = "ValueLabel"
	value_label.custom_minimum_size = Vector2(30, 8)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(value_label)

	# Block button (sprite sheet'ten)
	var block_btn = _create_block_button(value_text.length() + 2, callback)
	hbox.add_child(block_btn)

	options_container.add_child(hbox)

func _create_block_button(width_chars: int, callback: Callable) -> Control:
	# Container node - aynı zamanda click area olarak kullanılacak
	var container = Control.new()
	var btn_width = width_chars * 5 + 8  # her karakter 5px + padding
	container.custom_minimum_size = Vector2(btn_width, 8)
	container.mouse_filter = Control.MOUSE_FILTER_STOP  # Mouse event'lerini yakala

	# Arkaplan bloğu (beyaz solid sprite)
	var bg_sprite = Sprite2D.new()
	bg_sprite.centered = false
	bg_sprite.position = Vector2(0, 0)
	bg_sprite.texture = sprite_loader.get_solid_sprite(Color.WHITE)
	bg_sprite.scale = Vector2(btn_width / 8.0, 1.0)  # genişliği ayarla
	bg_sprite.z_index = 0  # Arkaplan
	container.add_child(bg_sprite)

	# Hover efekti - container'ın kendisine bağla
	container.mouse_entered.connect(func():
		bg_sprite.modulate = Color(0.7, 0.7, 0.7)  # Hover'da karart
	)
	container.mouse_exited.connect(func():
		bg_sprite.modulate = Color.WHITE  # Normal haline dön
	)

	# Click event
	container.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			callback.call()
			_update_menu()
	)

	# Buton text (>)
	var btn_label = Label.new()
	btn_label.text = ">"
	btn_label.position = Vector2(btn_width / 2 - 2, 0)
	btn_label.custom_minimum_size = Vector2(4, 8)
	btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_label.z_index = 1  # Yazı en üstte
	btn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Yazı mouse event'lerini engellemesin
	container.add_child(btn_label)

	return container

func _create_start_button():
	# Start butonu - geniş blok
	var container = Control.new()
	container.position = Vector2(80, 72)  # 22 + 42 + 8 = 72, 8px boşluk
	container.custom_minimum_size = Vector2(160, 8)
	container.mouse_filter = Control.MOUSE_FILTER_STOP  # Mouse event'lerini yakala

	# Arkaplan bloğu
	var bg_sprite = Sprite2D.new()
	bg_sprite.centered = false
	bg_sprite.position = Vector2(0, 0)
	bg_sprite.texture = sprite_loader.get_solid_sprite(Color.WHITE)
	bg_sprite.scale = Vector2(20.0, 1.0)  # 160px = 8 * 20
	bg_sprite.z_index = 0  # Arkaplan
	container.add_child(bg_sprite)

	# Hover efekti - container'ın kendisine bağla
	container.mouse_entered.connect(func():
		bg_sprite.modulate = Color(0.7, 0.7, 1.0)  # Hover'da hafif mavi
	)
	container.mouse_exited.connect(func():
		bg_sprite.modulate = Color.WHITE  # Normal haline dön
	)

	# Click event
	container.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_start_game()
	)

	# Button text
	var btn_label = Label.new()
	btn_label.text = "START GAME"
	btn_label.position = Vector2(0, 0)
	btn_label.custom_minimum_size = Vector2(160, 8)
	btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_label.z_index = 1  # Yazı en üstte
	btn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Yazı mouse event'lerini engellemesin
	container.add_child(btn_label)

	add_child(container)

func _apply_pixel_font():
	var font_size = 10

	# Başlık
	if title_label != null:
		title_label.add_theme_font_override("font", pixel_font)
		title_label.add_theme_font_size_override("font_size", font_size)

	# Tüm child node'lara uygula
	_apply_font_recursive(self, font_size)

func _apply_font_recursive(node: Node, size: int):
	if node is Control:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		if pixel_font != null:
			if node is Label:
				node.add_theme_font_override("font", pixel_font)
				node.add_theme_font_size_override("font_size", size)
				node.add_theme_constant_override("line_spacing", 0)

	for child in node.get_children():
		_apply_font_recursive(child, size)

func _update_menu():
	# Player count
	_update_option_value(0, str(current_player_count))
	# Color count
	_update_option_value(1, str(current_color_count))
	# Mode
	var mode_text = "SIDE" if current_side_by_side else "OVERLAP"
	_update_option_value(2, mode_text)
	# Handicap
	_update_option_value(3, str(current_handicap))

func _update_option_value(option_index: int, new_value: String):
	if option_index >= options_container.get_child_count():
		return

	var hbox = options_container.get_child(option_index)
	var value_label = hbox.get_node_or_null("ValueLabel")
	if value_label != null:
		value_label.text = new_value

# Callback fonksiyonları
func _on_player_change():
	current_player_count = (current_player_count % 2) + 1
	_ensure_player_colors()

func _on_color_change():
	current_color_count = (current_color_count % 3) + 1
	if not current_side_by_side:
		current_color_count = clamp(current_color_count, 1, 3)
	_ensure_block_colors()

func _on_mode_change():
	current_side_by_side = not current_side_by_side
	_ensure_block_colors()

func _on_handicap_change():
	current_handicap = (current_handicap + 1) % 6

func _ensure_block_colors():
	while current_block_colors.size() < current_color_count:
		if current_side_by_side:
			current_block_colors.append(all_colors[current_block_colors.size() % all_colors.size()])
		else:
			if current_block_colors.size() < 3:
				current_block_colors.append(rgb_colors[current_block_colors.size()])
			else:
				current_block_colors.append(all_colors[0])

	while current_block_colors.size() > current_color_count:
		current_block_colors.pop_back()

func _ensure_player_colors():
	while current_player_colors.size() < current_player_count:
		current_player_colors.append(all_colors[current_player_colors.size() % all_colors.size()])

	while current_player_colors.size() > current_player_count:
		current_player_colors.pop_back()

func _on_start_game():
	print("Starting game with:")
	print("  Players: ", current_player_count)
	print("  Colors: ", current_color_count)
	print("  Mode: ", "SIDE" if current_side_by_side else "OVERLAP")
	print("  Handicap: ", current_handicap)

	# Constants'a kaydet
	Constants.set_game_settings(
		current_player_count,
		current_color_count,
		current_side_by_side,
		current_block_colors,
		current_player_colors,
		current_handicap
	)

	# Oyuna geç
	get_tree().change_scene_to_file("res://scenes/game/test_game.tscn")
