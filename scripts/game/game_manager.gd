# Game Manager
# Tüm oyun state'ini yönetir
# Çoklu katman, oyuncu, score sistemi kontrol eder

class_name GameManager
extends Node

# Signal'lar
signal piece_placed(player_id: int, layer_index: int, piece: Tetromino)
signal piece_locked(positions: Array, colors: Array)  # Yeni: Particle için
signal rows_cleared(row_indices: Array, score_gained: int)
signal layer_changed(player_id: int, old_layer: int, new_layer: int)
signal game_over()
signal player_score_changed(player_id: int, new_score: int)
signal current_player_changed(player_id: int)

# Oyun ayarları
var layer_count: int = 3
var player_count: int = 1
var view_mode: Constants.ViewMode = Constants.ViewMode.OVERLAPPED
var score_mode: Constants.ScoreMode = Constants.ScoreMode.SHARED
var speed_mode: Constants.SpeedMode = Constants.SpeedMode.CLASSIC

# Oyun state
var grid: GridData
var current_piece: Tetromino
var current_player_id: int = 0
var current_layer_index: int = 0

# Oyuncu verileri
var player_scores: Array = []  # Her oyuncunun score'u
var player_layers: Array = []  # Her oyuncunun katmanı (2 player, 2 layer ise)

# Katman kuyruğu (boş katmanlar için)
var available_layers: Array = []

# Score (paylaşılıyor ise)
var shared_score: int = 0

# Oyun durumu
var is_paused: bool = false
var is_game_over: bool = false

# Hız sistemi
var current_fall_speed: float = Constants.DEFAULT_FALL_SPEED
var speed_timer: float = 0.0

# Particle ayarı
var particles_enabled: bool = Constants.PARTICLE_ENABLED_DEFAULT

# Bag system (7-bag randomizer) - her layer için ayrı bag
var piece_bags: Array = []  # Array of Arrays - her layer'ın kendi bag'i

# Renk sırası (döngüsel)
var color_sequence: Array = []
var color_sequence_index: int = 0

# Random generator
var rng: RandomNumberGenerator

func _init():
	rng = RandomNumberGenerator.new()
	rng.randomize()

# Oyunu başlat
func start_game(layers: int, players: int):
	layer_count = clamp(layers, 1, 3)
	player_count = clamp(players, 1, 3)

	# Grid oluştur
	grid = GridData.new(Constants.GRID_WIDTH, Constants.GRID_HEIGHT, layer_count)

	# Skorları sıfırla
	player_scores.clear()
	for i in range(player_count):
		player_scores.append(0)
	shared_score = 0

	# Katman ataması yap
	_setup_layer_assignment()

	# Renk sırasını başlat (döngüsel: 0, 1, 2, 0, 1, 2...)
	_setup_color_sequence()

	# Bag system'i başlat - her layer için ayrı
	_setup_piece_bags()

	# Hız sistemini sıfırla
	current_fall_speed = Constants.DEFAULT_FALL_SPEED
	speed_timer = 0.0

	# Oyun durumunu ayarla
	is_paused = false
	is_game_over = false

	# İlk parçayı spawn et (lock olmadan)
	_spawn_first_piece()

# İlk parçayı spawn et (lock olmadan)
func _spawn_first_piece():
	# Sıradaki katman index ve rengini al
	var layer_idx = color_sequence[color_sequence_index]
	var layer_color = _get_layer_color(layer_idx)
	color_sequence_index = (color_sequence_index + 1) % color_sequence.size()

	# O layer'ın bag'inden piece çek
	var piece_type = _get_piece_from_bag(layer_idx)

	current_piece = Tetromino.new(piece_type, layer_idx, layer_color)

	# Aktif katmanı güncelle
	current_layer_index = layer_idx

	if not _can_spawn_piece():
		is_game_over = true
		game_over.emit()
		return

	piece_placed.emit(current_player_id, current_layer_index, current_piece)

# Katman atamasını kur
func _setup_layer_assignment():
	player_layers.clear()
	available_layers.clear()

	if player_count == 1:
		# Tek oyuncu - tüm katmanları sırayla kullanır
		for i in range(layer_count):
			available_layers.append(i)
		current_layer_index = 0

	elif player_count == layer_count:
		# Oyuncu sayısı = katman sayısı (2-2 veya 3-3)
		# Her oyuncu kendi katmanında sabit oynar
		for i in range(player_count):
			player_layers.append(i)
		current_layer_index = 0

	elif player_count == 2 and layer_count == 3:
		# 2 oyuncu, 3 katman - boş katman kuyrukta döner
		# Oyuncu 0 -> Katman 0, Oyuncu 1 -> Katman 1
		# Boş katman (2) kuyrukta
		player_layers = [0, 1]
		available_layers = [2]

	current_player_id = 0

# Bir sonraki parçayı spawn et
func spawn_piece():
	# Önceki piece'i lock'la (yeni bir piece başlatmadan önce)
	if current_piece != null:
		_lock_piece()

	# Sıradaki katman index ve rengini al
	var layer_idx = color_sequence[color_sequence_index]
	var layer_color = _get_layer_color(layer_idx)
	color_sequence_index = (color_sequence_index + 1) % color_sequence.size()

	# O layer'ın bag'inden piece çek
	var piece_type = _get_piece_from_bag(layer_idx)

	current_piece = Tetromino.new(piece_type, layer_idx, layer_color)

	# Aktif katmanı güncelle
	current_layer_index = layer_idx

	# Spawn pozisyonu dolu olabilir (game over)
	if not _can_spawn_piece():
		# Game over
		is_game_over = true
		game_over.emit()
		return false

	piece_placed.emit(current_player_id, current_layer_index, current_piece)
	return true

# Piece spawn edilebilir mi?
func _can_spawn_piece() -> bool:
	if current_piece == null:
		return true

	# Spawn pozisyonunda çarpışma var mı?
	var spawn_pos = Constants.SPAWN_POSITIONS[current_piece.type]
	var shape = Constants.TETROMINO_SHAPES[current_piece.type]

	for y in range(shape.size()):
		for x in range(shape[0].size()):
			if shape[y][x] == 1:
				var target_x = spawn_pos.x + x
				var target_y = spawn_pos.y + y

				if target_x < 0 or target_x >= grid.width:
					return false
				if target_y >= grid.height:
					return false
				# current_piece'in kendi katmanını kontrol et
				if grid.is_occupied_in_layer(current_piece.layer_index, target_x, target_y):
					return false

	return true

# Piece'i grid'e lock et
func _lock_piece():
	if current_piece == null:
		return

	var shape = current_piece.shape
	var pos = current_piece.grid_position
	var color = current_piece.color

	# Particle'lar için pozisyonları ve renkleri topla
	var particle_positions = []
	var particle_colors = []

	# Grid'e yerleştir
	for y in range(shape.size()):
		for x in range(shape[0].size()):
			if shape[y][x] == 1:
				grid.set_cell(current_layer_index, pos.x + x, pos.y + y, color)

				# Particle için pozisyon hesapla (sol üst köşe)
				var particle_pos = Vector2(
					(pos.x + x) * 8,  # Hücre sol üst köşe
					(pos.y + y) * 8
				)
				particle_positions.append(particle_pos)
				particle_colors.append(color)

	# Particle signal'i emit et
	piece_locked.emit(particle_positions, particle_colors)

	# Satırları kontrol et ve sil
	_check_and_clear_lines()

	# Bir sonraki katmana/oyuncuya geç
	_advance_to_next()

# Satırları kontrol et ve sil
func _check_and_clear_lines():
	var full_rows = grid.get_full_rows()

	if not full_rows.is_empty():
		# Satırları sil
		grid.clear_rows(full_rows)

		# Score hesapla
		var score_gained = Constants.calculate_score(full_rows.size(), full_rows.size() > 1)
		_add_score(score_gained)

		rows_cleared.emit(full_rows, score_gained)

# Score ekle
func _add_score(amount: int):
	if score_mode == Constants.ScoreMode.SHARED:
		shared_score += amount
	else:
		if current_player_id >= 0 and current_player_id < player_scores.size():
			player_scores[current_player_id] += amount
			player_score_changed.emit(current_player_id, player_scores[current_player_id])

# Bir sonraki katmana/oyuncuya geç
func _advance_to_next():
	var old_layer = current_layer_index

	if player_count == 1:
		# Tek oyuncu - bir sonraki boş katmana geç
		if not available_layers.is_empty():
			# Mevcut katmanı kuyruğun sonuna ekle
			available_layers.append(current_layer_index)
			# Kuyruğun başındaki katmana geç
			current_layer_index = available_layers[0]
			available_layers.pop_front()

	elif player_count == layer_count:
		# Her oyuncu kendi katmanında - sıradaki oyuncuya geç
		current_player_id = (current_player_id + 1) % player_count
		current_layer_index = player_layers[current_player_id]

	elif player_count == 2 and layer_count == 3:
		# 2 oyuncu, 3 katman
		# Önceki katmanı available_layers'a ekle (oynamak için)
		if current_layer_index not in available_layers:
			available_layers.append(current_layer_index)

		# Sıradaki oyuncuya geç
		current_player_id = (current_player_id + 1) % player_count

		# Oyuncunun katmanını kontrol et
		var target_layer = player_layers[current_player_id]

		# Eğer hedef katman kullanılamıyorsa (başka bir yerdeyse), boş katman kullan
		if target_layer in available_layers:
			current_layer_index = target_layer
			available_layers.erase(target_layer)
		else:
			# Boş katmanlardan birini kullan
			if not available_layers.is_empty():
				current_layer_index = available_layers[0]
				available_layers.pop_front()

	current_player_changed.emit(current_player_id)

	if old_layer != current_layer_index:
		layer_changed.emit(current_player_id, old_layer, current_layer_index)

# Hareket fonksiyonları (external call)

func move_left() -> bool:
	if is_paused or is_game_over or current_piece == null:
		return false

	var new_pos = current_piece.grid_position + Vector2i(-1, 0)
	if current_piece.can_move_to(grid, new_pos):
		current_piece.move_left()
		return true
	return false

func move_right() -> bool:
	if is_paused or is_game_over or current_piece == null:
		return false

	var new_pos = current_piece.grid_position + Vector2i(1, 0)
	if current_piece.can_move_to(grid, new_pos):
		current_piece.move_right()
		return true
	return false

func move_down() -> bool:
	if is_paused or is_game_over or current_piece == null:
		return false

	var new_pos = current_piece.grid_position + Vector2i(0, 1)
	if current_piece.can_move_to(grid, new_pos):
		current_piece.move_down()
		return true
	return false

func rotate_cw() -> bool:
	if is_paused or is_game_over or current_piece == null:
		return false

	return current_piece.apply_rotation(grid, 1)

func rotate_ccw() -> bool:
	if is_paused or is_game_over or current_piece == null:
		return false

	return current_piece.apply_rotation(grid, -1)

func hard_drop() -> int:
	if is_paused or is_game_over or current_piece == null:
		return 0

	var drop_distance = current_piece.hard_drop(grid)
	# Lock'la ve yeni piece spawn et
	spawn_piece()
	return drop_distance

# Soft drop (manuel hızlı düşürme)
func soft_drop() -> bool:
	if is_paused or is_game_over or current_piece == null:
		return false

	return move_down()

# Oyun döngüsü update (delta_time ile)
func update(delta_time: float):
	if is_paused or is_game_over:
		return

	# Hız sistemi (klasik mod)
	if speed_mode == Constants.SpeedMode.CLASSIC:
		speed_timer += delta_time
		if speed_timer >= Constants.SPEED_INCREASE_INTERVAL:
			speed_timer = 0.0
			_increase_speed()

# Hızı artır (klasik mod için)
func _increase_speed():
	current_fall_speed = max(
		current_fall_speed * Constants.SPEED_INCREASE_RATE,
		Constants.MIN_FALL_SPEED
	)

# Oyunu durdur
func pause():
	is_paused = true

# Oyunu devam ettir
func resume():
	is_paused = false

# Score getterları
func get_score(player_id: int = -1) -> int:
	if score_mode == Constants.ScoreMode.SHARED:
		return shared_score
	else:
		if player_id >= 0 and player_id < player_scores.size():
			return player_scores[player_id]
		return 0

func get_all_scores() -> Array:
	if score_mode == Constants.ScoreMode.SHARED:
		return [shared_score]
	else:
		return player_scores.duplicate()

# Aktif oyuncu ve katman bilgisi
func get_current_player_id() -> int:
	return current_player_id

func get_current_layer_index() -> int:
	return current_layer_index

func get_current_piece() -> Tetromino:
	return current_piece

# Belirli bir layer için bir sonraki parça tipini al (preview için)
func get_next_piece_type(layer_idx: int) -> Constants.TetrominoType:
	if layer_idx < 0 or layer_idx >= piece_bags.size():
		return Constants.TetrominoType.I  # Fallback

	if piece_bags[layer_idx].is_empty():
		# Bag boşsa, yeni bag oluştur ve ilkini döndür
		_refill_piece_bag(layer_idx)

	if not piece_bags[layer_idx].is_empty():
		return piece_bags[layer_idx][0]

	# Fallback (asla olmamalı)
	return Constants.TetrominoType.I

# Grid'i al (readonly)
func get_grid() -> GridData:
	return grid

# ==================== BAG SYSTEM & COLOR SEQUENCE ====================

# Renk sırasını kur (0, 1, 2, 0, 1, 2... döngüsü)
func _setup_color_sequence():
	color_sequence.clear()
	for i in range(layer_count):
		color_sequence.append(i)
	color_sequence_index = 0

# Katman rengini al (yardımcı fonksiyon)
func _get_layer_color(layer_idx: int) -> Color:
	var colors = Constants.get_layer_colors(layer_count)
	if layer_idx >= 0 and layer_idx < colors.size():
		return colors[layer_idx]
	return Color.WHITE

# Her layer için piece bag'lerini başlat
func _setup_piece_bags():
	piece_bags.clear()
	for i in range(layer_count):
		piece_bags.append([])
		_refill_piece_bag(i)

# Belirli bir layer için bag'ı doldur (7-bag system)
func _refill_piece_bag(layer_idx: int):
	if layer_idx < 0 or layer_idx >= piece_bags.size():
		return

	piece_bags[layer_idx].clear()
	var all_types = [
		Constants.TetrominoType.I,
		Constants.TetrominoType.O,
		Constants.TetrominoType.T,
		Constants.TetrominoType.S,
		Constants.TetrominoType.Z,
		Constants.TetrominoType.J,
		Constants.TetrominoType.L
	]

	# Tüm tipleri ekle
	piece_bags[layer_idx].append_array(all_types)

	# Karıştır
	var bag = piece_bags[layer_idx]
	for i in range(bag.size() - 1):
		var j = rng.randi_range(i, bag.size() - 1)
		var temp = bag[i]
		bag[i] = bag[j]
		bag[j] = temp

# Belirli bir layer'ın bag'inden parça tipi çek
func _get_piece_from_bag(layer_idx: int) -> Constants.TetrominoType:
	if layer_idx < 0 or layer_idx >= piece_bags.size():
		return Constants.TetrominoType.I  # Fallback

	if piece_bags[layer_idx].is_empty():
		_refill_piece_bag(layer_idx)

	return piece_bags[layer_idx].pop_front()

# Rastgele bir tetromino tipi döndür (artık kullanılmıyor, bag system kullanılıyor)
func _get_random_piece_type() -> Constants.TetrominoType:
	var types = [
		Constants.TetrominoType.I,
		Constants.TetrominoType.O,
		Constants.TetrominoType.T,
		Constants.TetrominoType.S,
		Constants.TetrominoType.Z,
		Constants.TetrominoType.J,
		Constants.TetrominoType.L
	]
	return types[rng.randi() % types.size()]
