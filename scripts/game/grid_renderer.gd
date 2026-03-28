# Grid Renderer
# Oyun grid'ini ekranda render eder
# Overlapped ve Side-by-side modları destekler

class_name GridRenderer
extends Node2D

# Grid boyutları
var cell_size: Vector2 = Vector2(32, 32)  # Her hücrenin piksel boyutu
var grid_size: Vector2i = Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)

# Grid verisi
var grid_data: GridData

# Render ayarları
var view_mode: Constants.ViewMode = Constants.ViewMode.OVERLAPPED
var show_ghost: bool = true  # Ghost piece göster

# Texture'lar
var block_texture: Texture2D
var ghost_texture: Texture2D
var grid_background: ColorRect

# Sprite container (her hücre için)
var cell_sprites: Array = []  # 3D array: [layer][y][x]

# Ghost piece
var ghost_sprites: Array = []

# Aktif piece
var active_piece_sprites: Array = []

# Layer colors (highlight için)
var layer_colors: Array = []

# Highlight (aktif katman için)
var layer_highlight: ColorRect

func _ready():
	_create_grid_background()
	_create_layer_highlight()

func _process(delta):
	pass

# Grid verisini ayarla
func set_grid_data(data: GridData):
	grid_data = data
	grid_size = Vector2i(data.width, data.height)
	_create_cell_sprites()  # Grid verisi geldiğinde sprite'ları oluştur
	_update_layout()

# Görünüm modunu ayarla
func set_view_mode(mode: Constants.ViewMode):
	view_mode = mode
	_update_layout()

# Hücre boyutunu ayarla
func set_cell_size(size: Vector2):
	cell_size = size
	_update_layout()

# Layer renklerini ayarla
func set_layer_colors(colors: Array):
	layer_colors = colors
	_update_all_cells()

# Ghost göster/gizle
func set_show_ghost(show: bool):
	show_ghost = show
	_update_ghost_visibility()

# Grid arkaplanını oluştur
func _create_grid_background():
	grid_background = ColorRect.new()
	grid_background.color = Color(0.1, 0.1, 0.1, 0.8)  # Koyu gri
	grid_background.z_index = -10
	add_child(grid_background)

# Layer highlight (aktif katmanın çerçevesi)
func _create_layer_highlight():
	layer_highlight = ColorRect.new()
	layer_highlight.color = Color.TRANSPARENT
	layer_highlight.z_index = 100
	add_child(layer_highlight)

# Hücre sprite'larını oluştur
func _create_cell_sprites():
	# Önceki sprite'ları temizle
	_clear_cell_sprites()

	cell_sprites.clear()

	if grid_data == null:
		return

	var total_layers = grid_data.layer_count

	for layer_idx in range(total_layers):
		var layer_array = []
		for y in range(grid_size.y):
			var row_array = []
			for x in range(grid_size.x):
				var sprite = ColorRect.new()
				sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(sprite)
				row_array.append(sprite)
			layer_array.append(row_array)
		cell_sprites.append(layer_array)

# Layout'u güncelle
func _update_layout():
	# Grid boyutunu hesapla
	var grid_width = grid_size.x * cell_size.x
	var grid_height = grid_size.y * cell_size.y

	# Arkaplanı ayarla
	if grid_background != null:
		grid_background.size = Vector2(grid_width, grid_height)
		grid_background.position = Vector2.ZERO

	# Hücreleri konumlandır ve görünürlük ayarla
	if grid_data != null:
		for layer_idx in range(grid_data.layer_count):
			var is_visible = (view_mode == Constants.ViewMode.SIDE_BY_SIDE) or (view_mode == Constants.ViewMode.OVERLAPPED and layer_idx == 0)

			for y in range(grid_size.y):
				for x in range(grid_size.x):
					if layer_idx < cell_sprites.size() and y < cell_sprites[layer_idx].size() and x < cell_sprites[layer_idx][y].size():
						var sprite = cell_sprites[layer_idx][y][x]
						sprite.size = cell_size

						# Overlapped mod: hepsi aynı pozisyonda, side-by-side: yan yana
						if view_mode == Constants.ViewMode.OVERLAPPED:
							sprite.position = Vector2(x * cell_size.x, y * cell_size.y)
						else:  # SIDE_BY_SIDE
							sprite.position = Vector2(
								layer_idx * (grid_width + 20) + x * cell_size.x,  # 20px spacing
								y * cell_size.y
							)

						# Görünürlük ayarla
						if layer_idx == 0 or view_mode == Constants.ViewMode.SIDE_BY_SIDE:
							sprite.visible = is_visible
						else:
							sprite.visible = false  # Overlapped modda sadece ilk katman

	# Hücreleri güncelle
	_update_all_cells()

# Tüm hücreleri güncelle
func _update_all_cells():
	if grid_data == null or cell_sprites.is_empty():
		return

	if view_mode == Constants.ViewMode.OVERLAPPED:
		# Overlapped mod: sadece ilk katmanı göster, tüm renkleri karıştır
		for y in range(min(grid_size.y, cell_sprites[0].size())):
			for x in range(min(grid_size.x, cell_sprites[0][y].size())):
				_update_cell_overlapped(x, y)
	else:
		# Side-by-side mod: her katmanı ayrı göster
		for layer_idx in range(min(grid_data.layer_count, cell_sprites.size())):
			for y in range(min(grid_size.y, cell_sprites[layer_idx].size())):
				for x in range(min(grid_size.x, cell_sprites[layer_idx][y].size())):
					_update_cell_separated(layer_idx, x, y)

# Overlapped modda hücre güncelle (tüm katmanlardaki renkleri karıştır)
func _update_cell_overlapped(x: int, y: int):
	if grid_data == null or cell_sprites.is_empty():
		return

	if y >= cell_sprites[0].size() or x >= cell_sprites[0][y].size():
		return

	var sprite = cell_sprites[0][y][x]

	# Tüm katmanlardaki renkleri topla
	var colors_at_pos = grid_data.get_colors_at_position(x, y)

	if colors_at_pos.is_empty():
		# Hiçbir katmanda blok yok
		sprite.color = Color.TRANSPARENT
		sprite.color.a = 0.0
	else:
		# Renkleri karıştır (RGB additive blending)
		var blended_color = Constants.blend_colors(colors_at_pos)
		sprite.color = blended_color
		sprite.color.a = 1.0

# Side-by-side modda hücre güncelle (tek katman)
func _update_cell_separated(layer_idx: int, x: int, y: int):
	if grid_data == null:
		return

	if layer_idx >= cell_sprites.size() or y >= cell_sprites[layer_idx].size() or x >= cell_sprites[layer_idx][y].size():
		return

	var sprite = cell_sprites[layer_idx][y][x]
	var cell_color = grid_data.get_cell(layer_idx, x, y)

	if cell_color == null:
		# Boş hücre
		sprite.color = Color.TRANSPARENT
		sprite.color.a = 0.0
	else:
		# Dolu hücre
		sprite.color = cell_color
		sprite.color.a = 1.0

# Aktif parçayı güncelle
func update_active_piece(piece: Tetromino):
	if piece == null:
		_clear_active_piece_sprites()
		return

	# Önceki sprite'ları temizle
	_clear_active_piece_sprites()

	# Sprite'ları oluştur
	var shape = piece.shape
	var pos = piece.grid_position

	for y in range(shape.size()):
		for x in range(shape[0].size()):
			if shape[y][x] == 1:
				var sprite = ColorRect.new()
				sprite.size = cell_size
				sprite.position = Vector2(
					(pos.x + x) * cell_size.x,
					(pos.y + y) * cell_size.y
				)
				sprite.color = piece.color
				sprite.color.a = 1.0

				# Border ekle
				var border_color = piece.color.darkened(0.3)

				add_child(sprite)
				active_piece_sprites.append(sprite)

# Ghost piece'i güncelle
func update_ghost_piece(piece: Tetromino):
	if piece == null or not show_ghost:
		_clear_ghost_sprites()
		return

	var ghost_pos = piece.get_ghost_position(grid_data)

	# Önceki sprite'ları temizle
	_clear_ghost_sprites()

	# Sprite'ları oluştur
	var shape = piece.shape

	for y in range(shape.size()):
		for x in range(shape[0].size()):
			if shape[y][x] == 1:
				var sprite = ColorRect.new()
				sprite.size = cell_size
				sprite.position = Vector2(
					(ghost_pos.x + x) * cell_size.x,
					(ghost_pos.y + y) * cell_size.y
				)
				sprite.color = Color.TRANSPARENT
				sprite.color.a = 0.0

				# Border sadece

				add_child(sprite)
				ghost_sprites.append(sprite)

# Aktif katmanı vurgula
func highlight_layer(layer_idx: int, color: Color = Color.WHITE):
	if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
		if layer_highlight != null:
			layer_highlight.color = color
			layer_highlight.color.a = 0.3  # Şeffaf highlight
			layer_highlight.position = Vector2(
				layer_idx * (grid_size.x * cell_size.x + 20),  # 20px spacing
				0
			)
			layer_highlight.size = Vector2(
				grid_size.x * cell_size.x,
				grid_size.y * cell_size.y
			)
			layer_highlight.visible = true
	else:
		if layer_highlight != null:
			layer_highlight.visible = false

# Sprite temizleme fonksiyonları
func _clear_all_sprites():
	_clear_cell_sprites()
	_clear_active_piece_sprites()
	_clear_ghost_sprites()

func _clear_cell_sprites():
	for layer in cell_sprites:
		for row in layer:
			for sprite in row:
				if is_instance_valid(sprite):
					sprite.queue_free()
	cell_sprites.clear()

func _clear_active_piece_sprites():
	for sprite in active_piece_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	active_piece_sprites.clear()

func _clear_ghost_sprites():
	for sprite in ghost_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	ghost_sprites.clear()

func _update_ghost_visibility():
	for sprite in ghost_sprites:
		if is_instance_valid(sprite):
			sprite.visible = show_ghost
