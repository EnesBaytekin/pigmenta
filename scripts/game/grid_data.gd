# Grid Data Class
# 10x20xN boyutunda çok katmanlı oyun grid'ini tutar
# Her hücre o katmanın rengini tutar veya null (boş)

class_name GridData
extends RefCounted

var width: int
var height: int
var layer_count: int
var layers: Array = []  # Array of 2D arrays

# Signal olmadan çünkü RefCounted kullanıyoruz
# Bunun yerine işlemler sonucu return değerleri kullanacağız

func _init(w: int = Constants.GRID_WIDTH, h: int = Constants.GRID_HEIGHT, num_layers: int = 1):
	width = w
	height = h
	layer_count = clamp(num_layers, 1, 3)
	_initialize_layers()

# Tüm katmanları başlat
func _initialize_layers():
	layers.clear()
	for layer_idx in range(layer_count):
		var layer = []
		for y in range(height):
			var row = []
			for x in range(width):
				row.append(null)  # null = boş hücre
			layer.append(row)
		layers.append(layer)

# Grid'i tamamen temizle
func clear():
	for layer in layers:
		for y in range(height):
			for x in range(width):
				layer[y][x] = null

# Belirli bir katmandaki hücreyi al
func get_cell(layer_idx: int, x: int, y: int):
	if _is_valid_pos(layer_idx, x, y):
		return layers[layer_idx][y][x]
	return null

# Belirli bir katmandaki hücreyi ayarla
func set_cell(layer_idx: int, x: int, y: int, color: Color):
	if _is_valid_pos(layer_idx, x, y):
		layers[layer_idx][y][x] = color

# Belirli bir katmandaki hücreyi temizle
func clear_cell(layer_idx: int, x: int, y: int):
	if _is_valid_pos(layer_idx, x, y):
		layers[layer_idx][y][x] = null

# Tüm katmanlarda belirli bir pozisyonun dolu olup olmadığını kontrol et
func is_occupied(x: int, y: int) -> bool:
	for layer in layers:
		if _is_valid_pos_any_layer(x, y) and layer[y][x] != null:
			return true
	return false

# Belirli bir katmanda belirli bir pozisyonun dolu olup olmadığını kontrol et
func is_occupied_in_layer(layer_idx: int, x: int, y: int) -> bool:
	if _is_valid_pos(layer_idx, x, y):
		return layers[layer_idx][y][x] != null
	return false

# Belirli bir katman için blok yerleştirme (shape - tetromino)
# shape: 2D array of 0/1
# grid_x, grid_y: sol üst koordinat
# color: blok rengi
# return: başarılı mı
func place_block(layer_idx: int, shape: Array, grid_x: int, grid_y: int, color: Color) -> bool:
	if not _can_place_block(layer_idx, shape, grid_x, grid_y):
		return false

	for y in range(shape.size()):
		for x in range(shape[0].size()):
			if shape[y][x] == 1:
				set_cell(layer_idx, grid_x + x, grid_y + y, color)

	return true

# Blok yerleştirilebilir mi (collision check)
func _can_place_block(layer_idx: int, shape: Array, grid_x: int, grid_y: int) -> bool:
	for y in range(shape.size()):
		for x in range(shape[0].size()):
			if shape[y][x] == 1:
				var target_x = grid_x + x
				var target_y = grid_y + y
				if not _is_valid_pos(layer_idx, target_x, target_y):
					return false
				if is_occupied_in_layer(layer_idx, target_x, target_y):
					return false
	return true

# Belirli bir satırın belirli bir katmanda tamamen dolu olup olmadığını kontrol et
func is_row_full(layer_idx: int, row_y: int) -> bool:
	if layer_idx < 0 or layer_idx >= layers.size():
		return false
	if row_y < 0 or row_y >= height:
		return false

	for x in range(width):
		if layers[layer_idx][row_y][x] == null:
			return false
	return true

# Bir satırın TÜM katmanlarda dolu olup olmadığını kontrol et
func is_row_full_all_layers(row_y: int) -> bool:
	if row_y < 0 or row_y >= height:
		return false

	for layer in layers:
		for x in range(width):
			if layer[row_y][x] == null:
				return false
	return true

# Satır sil (tüm katmanlardan)
# Silinen satırdaki renkleri array olarak döndür (particle için)
func clear_row(row_y: int) -> Array:
	var cleared_colors = []

	for layer_idx in range(layers.size()):
		var layer = layers[layer_idx]
		var row_colors = []
		# Silinecek satırdaki renkleri topla
		for x in range(width):
			row_colors.append(layer[row_y][x])
		cleared_colors.append(row_colors)

		# Satırları yukarı kaydır
		for y in range(row_y, 0, -1):
			for x in range(width):
				layer[y][x] = layer[y - 1][x]

		# En üst satırı boşalt
		for x in range(width):
			layer[0][x] = null

	return cleared_colors

# Birden fazla satırı sil (sırayla)
# Silinen satırları ve renkleri döndür
func clear_rows(row_indices: Array) -> Array:
	# row_indices: Array of int, sorted ascending
	var cleared_data = []

	# En alttaki satırdan başlayarak sil
	for row_y in row_indices:
		var row_colors = clear_row(row_y)
		cleared_data.append({y = row_y, colors = row_colors})

	return cleared_data

# Tamamen dolu satırları bul (tüm katmanlarda)
func get_full_rows() -> Array:
	var full_rows = []

	for y in range(height):
		if is_row_full_all_layers(y):
			full_rows.append(y)

	return full_rows

# Belirli bir katmandaki tüm dolu hücreleri al
func get_filled_cells_in_layer(layer_idx: int) -> Array:
	var cells = []  # Array of {x, y, color}

	if layer_idx < 0 or layer_idx >= layers.size():
		return cells

	var layer = layers[layer_idx]
	for y in range(height):
		for x in range(width):
			if layer[y][x] != null:
				cells.append({x = x, y = y, color = layer[y][x]})

	return cells

# Tüm katmanlardaki dolu hücreleri al
func get_all_filled_cells() -> Dictionary:
	var result = {}
	for layer_idx in range(layers.size()):
		result[layer_idx] = get_filled_cells_in_layer(layer_idx)
	return result

# Belirli bir pozisyondaki tüm katmanlardaki renkleri al
func get_colors_at_position(x: int, y: int) -> Array:
	var colors = []

	if not _is_valid_pos_any_layer(x, y):
		return colors

	for layer in layers:
		var color = layer[y][x]
		if color != null:
			colors.append(color)

	return colors

# Grid'deki blok sayısını al (belirli katman için)
func get_block_count(layer_idx: int) -> int:
	var count = 0
	if layer_idx >= 0 and layer_idx < layers.size():
		var layer = layers[layer_idx]
		for y in range(height):
			for x in range(width):
				if layer[y][x] != null:
					count += 1
	return count

# Grid'i kopyala
func clone() -> GridData:
	var new_grid = GridData.new(width, height, layer_count)
	for layer_idx in range(layers.size()):
		for y in range(height):
			for x in range(width):
				new_grid.layers[layer_idx][y][x] = layers[layer_idx][y][x]
	return new_grid

# JSON'a serialize (save/load için)
func to_dict() -> Dictionary:
	var layer_data = []
	for layer in layers:
		var serialized_layer = []
		for y in range(height):
			var row = []
			for x in range(width):
				var cell = layer[y][x]
				if cell == null:
					row.append(null)
				else:
					row.append({r = cell.r, g = cell.g, b = cell.b, a = cell.a})
			serialized_layer.append(row)
		layer_data.append(serialized_layer)

	return {
		width = width,
		height = height,
		layer_count = layer_count,
		layers = layer_data
	}

# Dict'ten yükle (static factory method)
static func from_dict(data: Dictionary) -> GridData:
	var grid = GridData.new(data.width, data.height, data.layer_count)

	for layer_idx in range(data.layers.size()):
		var layer_data = data.layers[layer_idx]
		for y in range(grid.height):
			for x in range(grid.width):
				var cell_data = layer_data[y][x]
				if cell_data != null:
					grid.layers[layer_idx][y][x] = Color(cell_data.r, cell_data.g, cell_data.b, cell_data.a)
				else:
					grid.layers[layer_idx][y][x] = null

	return grid

# Yardımcı fonksiyonlar
func _is_valid_pos(layer_idx: int, x: int, y: int) -> bool:
	return layer_idx >= 0 and layer_idx < layers.size() and x >= 0 and x < width and y >= 0 and y < height

func _is_valid_pos_any_layer(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

# Grid bilgisini yazdır (debug)
func print_grid(layer_idx: int = 0):
	if layer_idx < 0 or layer_idx >= layers.size():
		print("Invalid layer index: %d" % layer_idx)
		return

	print("=== Layer %d ===" % layer_idx)
	var layer = layers[layer_idx]
	for y in range(height):
		var line = ""
		for x in range(width):
			if layer[y][x] != null:
				line += "█"
			else:
				line += "·"
		print(line)
	print("================")
