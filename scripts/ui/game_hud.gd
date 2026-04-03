# Game HUD
# Oyun içi gösterge paneli (Score, Layer, etc.)

class_name GameHUD
extends Control

# Font
@onready var pixel_font: FontFile = preload("res://textures/fonts/pixy.ttf")

# UI elementleri
var score_label: Label
var layer_label: Label
var player_label: Label

# Referanslar
var game_manager: GameManager

func _ready():
	# Pixel font uygula
	_apply_font()

	# UI oluştur
	_create_ui()

	# Texture filter (pixel art için)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _apply_font():
	# Font'u uygula - tüm yazılar için 10px
	if pixel_font != null:
		add_theme_font_override("font", pixel_font)
		add_theme_font_size_override("font_size", 10)

func _create_ui():
	# Sağ tarafta HUD oluştur (CanvasLayer içinde, ekran koordinatlarına göre)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	vbox.position = Vector2(10, 10)  # Sol üstten başla
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Score
	score_label = _create_label("SCORE: 0")
	vbox.add_child(score_label)

	# Layer
	layer_label = _create_label("LAYER: -")
	vbox.add_child(layer_label)

	# Player (multiplayer için)
	player_label = _create_label("PLAYER: 1")
	vbox.add_child(player_label)

func _create_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label

# GameManager referansını ayarla
func set_game_manager(gm: GameManager):
	game_manager = gm

	# İlk güncelleme
	update_hud()

# HUD'ı güncelle
func update_hud():
	if game_manager == null:
		return

	# Score
	var score = game_manager.get_score()
	score_label.text = "SCORE: %d" % score

	# Layer
	var layer_idx = game_manager.get_current_layer_index()
	var layer_colors = Constants.game_block_colors
	var layer_name = "LAYER: %d" % layer_idx

	if layer_idx < layer_colors.size():
		var color = layer_colors[layer_idx]
		# Renk ismini belirle
		if color == Color.RED:
			layer_name = "LAYER: RED"
		elif color == Color.GREEN:
			layer_name = "LAYER: GREEN"
		elif color == Color.BLUE:
			layer_name = "LAYER: BLUE"
		else:
			layer_name = "LAYER: %d" % layer_idx

	layer_label.text = layer_name

	# Player
	var player_id = game_manager.get_current_player_id()
	player_label.text = "PLAYER: %d" % (player_id + 1)
