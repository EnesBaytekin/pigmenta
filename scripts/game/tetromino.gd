# Tetromino Class
# Aktif düşen tetramino parçasını temsil eder
# Pozisyon, rotasyon, tip ve katman bilgisini tutar

class_name Tetromino
extends RefCounted

var type: Constants.TetrominoType
var shape: Array  # Mevcut rotasyondaki shape
var grid_position: Vector2i  # Grid koordinatları (sol üst)
var rotation_state: int  # 0-3, dört rotasyon durumu
var layer_index: int  # Hangi katmanda olduğu
var color: Color  # Bloğun rengi (katman rengi)

func _init(t: Constants.TetrominoType, layer_idx: int, layer_color: Color):
	type = t
	rotation_state = 0
	# İlk rotasyonu al
	shape = Constants.TETROMINO_ROTATIONS[type][rotation_state].duplicate(true)
	layer_index = layer_idx
	color = layer_color

	# Spawn pozisyonunu ayarla
	var spawn_pos = Constants.SPAWN_POSITIONS[type]
	grid_position = spawn_pos


# Hareket ettir
func move(direction: Vector2i) -> Vector2i:
	grid_position += direction
	return grid_position

# Sağa hareket
func move_right() -> Vector2i:
	return move(Vector2i(1, 0))

# Sola hareket
func move_left() -> Vector2i:
	return move(Vector2i(-1, 0))

# Aşağı hareket
func move_down() -> Vector2i:
	return move(Vector2i(0, 1))

# Hard drop (en dibine in)
func hard_drop(grid: GridData) -> int:
	var drop_distance = 0
	while can_move_to(grid, grid_position + Vector2i(0, 1)):
		grid_position.y += 1
		drop_distance += 1
	return drop_distance

# Ghost position (hard drop yapılacak yer) hesapla
func get_ghost_position(grid: GridData) -> Vector2i:
	var ghost_pos = grid_position
	while grid != null and _can_place_at(grid, shape, ghost_pos + Vector2i(0, 1)):
		ghost_pos.y += 1
	return ghost_pos

# Belirli bir pozisyonda bu shape yerleştirilebilir mi?
func can_move_to(grid: GridData, new_pos: Vector2i) -> bool:
	return _can_place_at(grid, shape, new_pos)

# Rotasyon uygula (basit wall kick dahil)
func apply_rotation(grid: GridData, direction: int = 1) -> bool:
	# direction: 1 = saat yönü, -1 = saat yönü tersi
	var rotation_count = Constants.get_rotation_count(type)
	if rotation_count <= 1:
		return false  # O bloğu dönmez

	# Yeni rotation state'i hesapla
	var new_rotation_state: int
	if direction == 1:
		new_rotation_state = (rotation_state + 1) % rotation_count
	else:
		new_rotation_state = (rotation_state + rotation_count - 1) % rotation_count

	# Yeni shape'i al
	var new_shape = Constants.TETROMINO_ROTATIONS[type][new_rotation_state].duplicate(true)

	# Basit wall kick: sadece yatayda offset dene
	var kick_offsets = _get_wall_kick_offsets(grid, new_shape)

	for offset_x in kick_offsets:
		var test_pos = grid_position + Vector2i(offset_x, 0)
		if _can_place_at(grid, new_shape, test_pos):
			# Başarılı rotasyon!
			shape = new_shape
			grid_position = test_pos
			rotation_state = new_rotation_state
			return true

	return false  # Hiçbir offset işe yaramadı

# Shape'in kapladığı grid hücrelerini al
func get_occupied_cells() -> Array:
	var cells = []  # Array of Vector2i
	for y in range(shape.size()):
		for x in range(shape[0].size()):
			if shape[y][x] == 1:
				cells.append(grid_position + Vector2i(x, y))
	return cells

# Clone (kopya oluştur)
func clone() -> Tetromino:
	var new_tetromino = Tetromino.new(type, layer_index, color)
	new_tetromino.shape = shape.duplicate(true)
	new_tetromino.grid_position = grid_position
	new_tetromino.rotation_state = rotation_state
	return new_tetromino

# Private helper fonksiyonlar

# Belirli bir pozisyonda shape yerleştirilebilir mi?
func _can_place_at(grid: GridData, test_shape: Array, test_pos: Vector2i) -> bool:
	if grid == null:
		return false

	for y in range(test_shape.size()):
		for x in range(test_shape[0].size()):
			if test_shape[y][x] == 1:
				var target_x = test_pos.x + x
				var target_y = test_pos.y + y

				# Grid sınırları kontrolü
				if target_x < 0 or target_x >= grid.width:
					return false
				if target_y < 0 or target_y >= grid.height:
					return false

				# Çarpışma kontrolü
				if grid.is_occupied_in_layer(layer_index, target_x, target_y):
					return false

	return true

# Wall kick offset'lerini hesapla (basit sistem)
func _get_wall_kick_offsets(grid: GridData, test_shape: Array) -> Array:
	# Grid genişliği
	var grid_width = grid.width if grid != null else 10

	# Shape genişliğini hesapla
	var shape_width = test_shape[0].size()

	# Grid dışına taşıyor mu kontrol et
	var right_edge = grid_position.x + shape_width
	var left_edge = grid_position.x

	# Offset listesi: önce 0, sonra içe doğru itme denemeleri
	var offsets = [0]  # Önce olduğu yerde dene

	if right_edge > grid_width:
		# Sağ kenarda - sola it
		offsets.append(-1)
		offsets.append(-2)
	elif left_edge < 0:
		# Sol kenarda - sağa it
		offsets.append(1)
		offsets.append(2)

	return offsets

# Tetromino'yu string olarak dön (debug için)
func _to_string() -> String:
	return "Tetromino[type=%s, pos=%s, rotation=%d, layer=%d]" % [
		Constants.TetrominoType.keys()[type],
		grid_position,
		rotation_state,
		layer_index
	]

# Shape'i yazdır (debug için)
func print_shape():
	print("Shape at ", grid_position, " (rotation ", rotation_state, "):")
	for row in shape:
		var line = ""
		for cell in row:
			line += "█" if cell else "·"
		print(line)
