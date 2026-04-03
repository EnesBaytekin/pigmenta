# Grid Renderer
# Oyun grid'ini ekranda render eder
# Overlapped ve Side-by-side modları destekler

class_name GridRenderer
extends Node2D

# Grid boyutları
var cell_size: Vector2 = Vector2(32, 32)  # Her hücrenin piksel boyutu (8x8 texture, 4x scale)
var grid_size: Vector2i = Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)

# Grid verisi
var grid_data: GridData

# Render ayarları
var view_mode: Constants.ViewMode = Constants.ViewMode.OVERLAPPED
var show_ghost: bool = true  # Ghost piece göster

# Sprite sheet loader
var sprite_loader: SpriteSheetLoader

# Texture'lar
var block_texture: Texture2D
var grid_background: ColorRect  # Overlapped mod için tek background
var grid_backgrounds: Array = []  # Side-by-side mod için her layer'a bir background

# Sprite container (her hücre için)
var cell_sprites: Array = []  # 3D array: [layer][y][x]

# Next piece preview
var preview_cell_sprites: Array = []  # 3D array: [layer][y][x]
var preview_grid_size: Vector2i = Vector2i(4, 4)  # Preview grid boyutu
var preview_cell_size: Vector2 = Vector2(4, 4)  # Preview hücre boyutu (ana gridden daha küçük)
var preview_backgrounds: Array = []  # Her preview için arka plan ColorRect

# Ghost piece
var ghost_sprites: Array = []

# Aktif piece
var active_piece_sprites: Array = []  # Mevcut sprite'lar
var target_positions: Array = []  # Hedef pozisyonlar

# Layer colors (highlight için)
var layer_colors: Array = []

# Aktif katman (side-by-side modda piece positioning için)
var current_layer_idx: int = 0

# Highlight (aktif katman için) - çerçeve
var layer_highlight: Node2D
var layer_highlight_color: Color = Color.WHITE
var layer_highlight_rect: Rect2 = Rect2()

func _ready():
	# Sprite sheet loader oluştur
	sprite_loader = SpriteSheetLoader.new()
	add_child(sprite_loader)

	_create_grid_background()
	_create_layer_highlight()

func _draw():
	# Layer highlight çerçevesini çiz
	if layer_highlight != null and layer_highlight.visible:
		var rect = layer_highlight_rect
		# 1 pixel çizgilerle çerçeve çiz
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), layer_highlight_color, 1.0)  # Üst
		draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + rect.size, layer_highlight_color, 1.0)  # Sağ
		draw_line(rect.position + rect.size, rect.position + Vector2(0, rect.size.y), layer_highlight_color, 1.0)  # Alt
		draw_line(rect.position + Vector2(0, rect.size.y), rect.position, layer_highlight_color, 1.0)  # Sol

func _process(delta):
	# Smooth animasyon - hedef pozisyonlara lerp
	for i in range(active_piece_sprites.size()):
		if i < target_positions.size():
			var sprite = active_piece_sprites[i]
			var target = target_positions[i]
			if is_instance_valid(sprite):
				# Hedefe yeterince yakınsa direkt at (jiggle önlemek için)
				var distance = sprite.position.distance_to(target)
				if distance < 1.0:  # 1 pikselden yakınsa
					sprite.position = target
				else:
					# Mesafe kadar dinamik lerp (uzaksa daha hızlı)
					var lerp_factor = clamp(0.4 + distance * 0.1, 0.4, 0.8)
					sprite.position = sprite.position.lerp(target, lerp_factor)

# Grid verisini ayarla
func set_grid_data(data: GridData):
	grid_data = data
	grid_size = Vector2i(data.width, data.height)
	_create_cell_sprites()  # Grid verisi geldiğinde sprite'ları oluştur
	_create_preview_sprites()  # Preview sprite'larını oluştur
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

# Aktif katmanı ayarla (side-by-side modda piece positioning için)
func set_current_layer(layer_idx: int):
	current_layer_idx = layer_idx

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
	layer_highlight = Node2D.new()
	layer_highlight.z_index = 100
	add_child(layer_highlight)

# Hücre sprite'larını oluştur
func _create_cell_sprites():
	# Önceki sprite'ları temizle
	_clear_cell_sprites()

	cell_sprites.clear()
	grid_backgrounds.clear()

	if grid_data == null:
		return

	var total_layers = grid_data.layer_count

	for layer_idx in range(total_layers):
		# Her layer için background oluştur
		var bg = ColorRect.new()
		bg.color = Color(0.1, 0.1, 0.1, 0.8)
		bg.z_index = -10
		add_child(bg)
		grid_backgrounds.append(bg)

		# Cell sprite'ları
		var layer_array = []
		for y in range(grid_size.y):
			var row_array = []
			for x in range(grid_size.x):
				var sprite = Sprite2D.new()
				sprite.centered = false
				sprite.visible = false
				add_child(sprite)
				row_array.append(sprite)
			layer_array.append(row_array)
		cell_sprites.append(layer_array)

# Preview sprite'larını oluştur
func _create_preview_sprites():
	# Önceki sprite'ları temizle
	_clear_preview_sprites()

	preview_cell_sprites.clear()
	preview_backgrounds.clear()

	if grid_data == null:
		return

	var total_layers = grid_data.layer_count

	for layer_idx in range(total_layers):
		# Her layer için preview arka planı oluştur
		var bg = ColorRect.new()
		bg.color = Color(0.05, 0.05, 0.05, 0.9)  # Daha koyu arka plan
		bg.z_index = -9  # Cell sprite'larının altında
		add_child(bg)
		preview_backgrounds.append(bg)

		# Preview sprite'ları oluştur
		var layer_array = []
		for y in range(preview_grid_size.y):
			var row_array = []
			for x in range(preview_grid_size.x):
				var sprite = Sprite2D.new()
				sprite.centered = false
				sprite.visible = false
				sprite.z_index = 5  # Normal cell'lerin üstünde
				add_child(sprite)
				row_array.append(sprite)
			layer_array.append(row_array)
		preview_cell_sprites.append(layer_array)

# Layout'u güncelle
func _update_layout():
	# Grid boyutunu hesapla
	var grid_width = grid_size.x * cell_size.x
	var grid_height = grid_size.y * cell_size.y
	var preview_width = preview_grid_size.x * preview_cell_size.x

	# Her "unit" = grid + spacing + preview
	var unit_width = grid_width + 4 + preview_width  # 4px spacing between grid and preview

	# Layer sayısına göre toplam genişliği ve spacing'i hesapla
	var total_layers = 1  # Overlapped modda her zaman 1
	if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
		total_layers = grid_data.layer_count if grid_data != null else 1

	var grid_spacing = 20  # Gridler arası spacing (side-by-side modda)

	# Layer sayısına göre spacing'i ayarla (3 layer için daha dar)
	if total_layers == 3:
		grid_spacing = 8  # Daha dar spacing
	elif total_layers == 2:
		grid_spacing = 20

	# Toplam genişlik hesapla
	var total_width = total_layers * unit_width + (total_layers - 1) * grid_spacing

	# Ortalamak için base offset hesapla (parent node pozisyonu zaten (120, 10), onu dikkate al)
	# Ekran genişliği 320, parent (120, 10) konumunda
	var ideal_start = (320 - total_width) / 2.0  # Ekranda ideal başlangıç
	var current_parent = 120.0  # Parent pozisyonu (scene'den)
	var base_offset_x = ideal_start - current_parent

	# Arkaplanları ayarla
	if grid_background != null:
		if view_mode == Constants.ViewMode.OVERLAPPED:
			grid_background.size = Vector2(grid_width, grid_height)
			grid_background.position = Vector2(base_offset_x, 0)
			grid_background.visible = true
		else:
			grid_background.visible = false

	# Side-by-side modda her grid için background
	if grid_data != null:
		for layer_idx in range(grid_data.layer_count):
			if layer_idx < grid_backgrounds.size():
				var bg = grid_backgrounds[layer_idx]
				if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
					var layer_offset_x = base_offset_x + layer_idx * (unit_width + grid_spacing)
					bg.position = Vector2(layer_offset_x, 0)
					bg.size = Vector2(grid_width, grid_height)
					bg.visible = true
				else:
					bg.visible = false

	# Hücreleri konumlandır ve görünürlük ayarla
	if grid_data != null:
		for layer_idx in range(grid_data.layer_count):
			var is_visible = (view_mode == Constants.ViewMode.SIDE_BY_SIDE) or (view_mode == Constants.ViewMode.OVERLAPPED and layer_idx == 0)

			# Bu layer için offset hesapla
			var layer_offset_x = base_offset_x
			if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
				layer_offset_x = base_offset_x + layer_idx * (unit_width + grid_spacing)

			for y in range(grid_size.y):
				for x in range(grid_size.x):
					if layer_idx < cell_sprites.size() and y < cell_sprites[layer_idx].size() and x < cell_sprites[layer_idx][y].size():
						var sprite: Sprite2D = cell_sprites[layer_idx][y][x]

						# Pixel art için texture filter'ı kapat
						sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

						# Pozisyon ayarla
						sprite.position = Vector2(
							layer_offset_x + x * cell_size.x,
							y * cell_size.y
						)

						# Görünürlük ayarla
						if layer_idx == 0 or view_mode == Constants.ViewMode.SIDE_BY_SIDE:
							sprite.visible = is_visible
						else:
							sprite.visible = false  # Overlapped modda sadece ilk katman

	# Preview grid'lerini konumlandır
	if grid_data != null:
		for layer_idx in range(grid_data.layer_count):
			# Bu layer için offset hesapla
			var layer_offset_x = base_offset_x
			if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
				layer_offset_x = base_offset_x + layer_idx * (unit_width + grid_spacing)

			var preview_x = layer_offset_x + grid_width + 4  # Ana grid'in sağında, 4px boşluk
			var preview_y = 0

			# Preview arka planı
			if layer_idx < preview_backgrounds.size():
				var bg = preview_backgrounds[layer_idx]
				bg.position = Vector2(preview_x, preview_y)
				bg.size = Vector2(preview_grid_size.x * preview_cell_size.x, preview_grid_size.y * preview_cell_size.y)
				bg.visible = (view_mode == Constants.ViewMode.SIDE_BY_SIDE) or (view_mode == Constants.ViewMode.OVERLAPPED and layer_idx == 0)

			# Preview sprite'ları
			if layer_idx < preview_cell_sprites.size():
				for y in range(preview_grid_size.y):
					for x in range(preview_grid_size.x):
						if y < preview_cell_sprites[layer_idx].size() and x < preview_cell_sprites[layer_idx][y].size():
							var sprite: Sprite2D = preview_cell_sprites[layer_idx][y][x]
							sprite.position = Vector2(
								preview_x + x * preview_cell_size.x,
								preview_y + y * preview_cell_size.y
							)
							sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

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
	if grid_data == null or cell_sprites.is_empty() or sprite_loader == null:
		return

	if y >= cell_sprites[0].size() or x >= cell_sprites[0][y].size():
		return

	var sprite: Sprite2D = cell_sprites[0][y][x]

	# Tüm katmanlardaki renkleri topla
	var colors_at_pos = grid_data.get_colors_at_position(x, y)

	if colors_at_pos.is_empty():
		# Hiçbir katmanda blok yok - arkaplan siyah blok göster
		sprite.texture = sprite_loader.get_background_sprite()
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2(1, 1)  # 1:1 çizim
		sprite.visible = true
	else:
		# Renkleri karıştır (RGB additive blending)
		var blended_color = Constants.blend_colors(colors_at_pos)
		# Solid sprite kullan (satır 2 veya 3)
		sprite.texture = sprite_loader.get_solid_sprite(blended_color)
		sprite.modulate = Color.WHITE  # Her zaman beyaz, texture'ın kendi rengi
		sprite.scale = Vector2(1, 1)  # 1:1 çizim
		sprite.visible = true

# Side-by-side modda hücre güncelle (tek katman)
func _update_cell_separated(layer_idx: int, x: int, y: int):
	if grid_data == null or sprite_loader == null:
		return

	if layer_idx >= cell_sprites.size() or y >= cell_sprites[layer_idx].size() or x >= cell_sprites[layer_idx][y].size():
		return

	var sprite: Sprite2D = cell_sprites[layer_idx][y][x]
	var cell_color = grid_data.get_cell(layer_idx, x, y)

	if cell_color == null:
		# Boş hücre - arkaplan siyah blok göster
		sprite.texture = sprite_loader.get_background_sprite()
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2(1, 1)  # 1:1 çizim
		sprite.visible = true
	else:
		# Dolu hücre
		sprite.texture = sprite_loader.get_solid_sprite(cell_color)
		sprite.modulate = Color.WHITE  # Modulate'ı resetle
		sprite.scale = Vector2(1, 1)  # 1:1 çizim
		sprite.visible = true

# Aktif parçayı güncelle
func update_active_piece(piece: Tetromino):
	if piece == null:
		_clear_active_piece_sprites()
		target_positions.clear()
		return

	var shape = piece.shape
	var pos = piece.grid_position

	# İhtiyaç duyulan sprite sayısı
	var needed_sprites = 0
	for y in range(shape.size()):
		for x in range(shape[0].size()):
			if shape[y][x] == 1:
				needed_sprites += 1

	# Fazla sprite'ları temizle
	while active_piece_sprites.size() > needed_sprites:
		var extra = active_piece_sprites.pop_back()
		if is_instance_valid(extra):
			extra.queue_free()

	target_positions.clear()

	# Layer offset hesapla (layout ile tutarlı)
	var grid_width = grid_size.x * cell_size.x
	var preview_width = preview_grid_size.x * preview_cell_size.x
	var unit_width = grid_width + 4 + preview_width

	var grid_spacing = 20
	if grid_data != null:
		if grid_data.layer_count == 3:
			grid_spacing = 8
		elif grid_data.layer_count == 2:
			grid_spacing = 20

	var total_layers = 1
	if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
		total_layers = grid_data.layer_count if grid_data != null else 1

	var total_width = total_layers * unit_width + (total_layers - 1) * grid_spacing
	var ideal_start = (320 - total_width) / 2.0
	var current_parent = 120.0
	var base_offset_x = ideal_start - current_parent

	var layer_offset = base_offset_x
	if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
		layer_offset = base_offset_x + current_layer_idx * (unit_width + grid_spacing)

	# Sprite'ları güncelle veya oluştur
	var sprite_index = 0
	for y in range(shape.size()):
		for x in range(shape[0].size()):
			if shape[y][x] == 1:
				var target_pos = Vector2(
					layer_offset + (pos.x + x) * cell_size.x,
					(pos.y + y) * cell_size.y
				)
				target_positions.append(target_pos)

				var sprite: Sprite2D
				if sprite_index < active_piece_sprites.size():
					# Mevcut sprite'ı yeniden kullan
					sprite = active_piece_sprites[sprite_index]
					# Sadece hedefe çok uzaksa güncelle (hareket halindeyse güncelleme)
					var distance = sprite.position.distance_to(target_pos)
					if distance > 1.0:  # 1 pikseden uzaktaysa güncelle
						# Texture'ı güncelle
						if sprite_loader != null:
							sprite.texture = sprite_loader.get_active_sprite(piece.color)
				else:
					# Yeni sprite oluştur
					sprite = Sprite2D.new()
					sprite.centered = false
					sprite.position = target_pos  # Başlangıçta hedefte
					sprite.scale = Vector2(1, 1)  # 1:1 çizim
					sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Pixel art
					add_child(sprite)
					active_piece_sprites.append(sprite)

					# Aktif sprite kullan (üst 2 satır)
					if sprite_loader != null:
						sprite.texture = sprite_loader.get_active_sprite(piece.color)

				sprite_index += 1

# Ghost piece'i güncelle
func update_ghost_piece(piece: Tetromino):
	if piece == null or not show_ghost:
		_clear_ghost_sprites()
		return

	var ghost_pos = piece.get_ghost_position(grid_data)

	# Önceki sprite'ları temizle
	_clear_ghost_sprites()

	# Layer offset hesapla (layout ile tutarlı)
	var grid_width = grid_size.x * cell_size.x
	var preview_width = preview_grid_size.x * preview_cell_size.x
	var unit_width = grid_width + 4 + preview_width

	var grid_spacing = 20
	if grid_data != null:
		if grid_data.layer_count == 3:
			grid_spacing = 8
		elif grid_data.layer_count == 2:
			grid_spacing = 20

	var total_layers = 1
	if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
		total_layers = grid_data.layer_count if grid_data != null else 1

	var total_width = total_layers * unit_width + (total_layers - 1) * grid_spacing
	var ideal_start = (320 - total_width) / 2.0
	var current_parent = 120.0
	var base_offset_x = ideal_start - current_parent

	var layer_offset = base_offset_x
	if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
		layer_offset = base_offset_x + current_layer_idx * (unit_width + grid_spacing)

	# Sprite'ları oluştur
	var shape = piece.shape

	for y in range(shape.size()):
		for x in range(shape[0].size()):
			if shape[y][x] == 1:
				var sprite = Sprite2D.new()
				sprite.centered = false
				sprite.position = Vector2(
					layer_offset + (ghost_pos.x + x) * cell_size.x,
					(ghost_pos.y + y) * cell_size.y
				)
				sprite.scale = Vector2(1, 1)  # 1:1 çizim
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Pixel art
				sprite.modulate = Color.WHITE
				sprite.modulate.a = 0.3  # Şeffaf

				# Aktif sprite kullan (üst 2 satır)
				if sprite_loader != null:
					sprite.texture = sprite_loader.get_active_sprite(piece.color)

				add_child(sprite)
				ghost_sprites.append(sprite)

# Next piece preview'ı güncelle
func update_next_preview(layer_idx: int, piece_type: Constants.TetrominoType, piece_color: Color):
	if layer_idx < 0 or layer_idx >= preview_cell_sprites.size():
		return

	if sprite_loader == null:
		return

	# Önce tüm preview sprite'larını temizle (görünmez yap)
	for y in range(preview_grid_size.y):
		for x in range(preview_grid_size.x):
			if y < preview_cell_sprites[layer_idx].size() and x < preview_cell_sprites[layer_idx][y].size():
				var sprite: Sprite2D = preview_cell_sprites[layer_idx][y][x]
				sprite.visible = false

	# Piece shape'i al
	var shape = Constants.TETROMINO_SHAPES[piece_type]

	# Ortalama için offset hesapla
	var shape_width = shape[0].size()
	var shape_height = shape.size()
	var offset_x = (preview_grid_size.x - shape_width) / 2
	var offset_y = (preview_grid_size.y - shape_height) / 2

	# Preview sprite'larını güncelle
	for y in range(shape_height):
		for x in range(shape_width):
			if shape[y][x] == 1:
				var preview_x = int(offset_x) + x
				var preview_y = int(offset_y) + y

				if preview_y >= 0 and preview_y < preview_grid_size.y and preview_x >= 0 and preview_x < preview_grid_size.x:
					if preview_y < preview_cell_sprites[layer_idx].size() and preview_x < preview_cell_sprites[layer_idx][preview_y].size():
						var sprite: Sprite2D = preview_cell_sprites[layer_idx][preview_y][preview_x]
						sprite.texture = sprite_loader.get_solid_sprite(piece_color)
						sprite.modulate = Color.WHITE
						sprite.scale = Vector2(0.5, 0.5)  # 4x4 için 8x8 texture'ı küçült
						sprite.visible = true

# Aktif katmanı vurgula
func highlight_layer(layer_idx: int, color: Color = Color.WHITE):
	if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
		if layer_highlight != null:
			# Layout hesaplamaları (tutarlı olması için)
			var grid_width = grid_size.x * cell_size.x
			var grid_height = grid_size.y * cell_size.y
			var preview_width = preview_grid_size.x * preview_cell_size.x
			var unit_width = grid_width + 4 + preview_width

			var grid_spacing = 20
			if grid_data != null:
				if grid_data.layer_count == 3:
					grid_spacing = 8
				elif grid_data.layer_count == 2:
					grid_spacing = 20

			var total_layers = 1
			if view_mode == Constants.ViewMode.SIDE_BY_SIDE:
				total_layers = grid_data.layer_count if grid_data != null else 1

			var total_width = total_layers * unit_width + (total_layers - 1) * grid_spacing
			var ideal_start = (320 - total_width) / 2.0
			var current_parent = 120.0
			var base_offset_x = ideal_start - current_parent

			# Çerçeve rengi ve pozisyonu ayarla
			layer_highlight_color = color
			layer_highlight_rect = Rect2(
				Vector2(base_offset_x + layer_idx * (unit_width + grid_spacing), 0),
				Vector2(grid_width, grid_height)
			)
			layer_highlight.visible = true
			queue_redraw()  # Çerçeveyi yeniden çiz
	else:
		if layer_highlight != null:
			layer_highlight.visible = false
			queue_redraw()

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

	for bg in grid_backgrounds:
		if is_instance_valid(bg):
			bg.queue_free()
	grid_backgrounds.clear()

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

func _clear_preview_sprites():
	for layer in preview_cell_sprites:
		for row in layer:
			for sprite in row:
				if is_instance_valid(sprite):
					sprite.queue_free()
	preview_cell_sprites.clear()

	for bg in preview_backgrounds:
		if is_instance_valid(bg):
			bg.queue_free()
	preview_backgrounds.clear()

func _update_ghost_visibility():
	for sprite in ghost_sprites:
		if is_instance_valid(sprite):
			sprite.visible = show_ghost
