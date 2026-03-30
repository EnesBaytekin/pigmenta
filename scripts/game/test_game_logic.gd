extends Node2D

# Test Game Logic
# GameManager ve GridRenderer arasındaki bağlantıyı yönetir

var game_manager: GameManager
var grid_renderer: GridRenderer
var particle_manager: ParticleManager
var camera: Camera2D

var fall_timer: float = 0.0

# Internal resolution (16:9 aspect ratio)
const INTERNAL_WIDTH = 320
const INTERNAL_HEIGHT = 180

# Input kontrol
var move_left_timer: float = 0.0
var move_right_timer: float = 0.0
var move_down_timer: float = 0.0

func _ready():
	# Camera referansı al
	camera = $Camera2D

	# Ekran boyutuna göre camera zoom ayarla
	_update_camera_zoom()

	# Window resize eventi için bağlantı kur
	get_tree().root.size_changed.connect(_on_window_resize)

	# GameManager oluştur
	game_manager = GameManager.new()
	game_manager.start_game(3, 1)  # 3 katman, 1 oyuncu

	# Signal'ları bağla
	game_manager.piece_placed.connect(_on_piece_placed)
	game_manager.piece_locked.connect(_on_piece_locked)  # Yeni: Particle için
	game_manager.rows_cleared.connect(_on_rows_cleared)
	game_manager.layer_changed.connect(_on_layer_changed)
	game_manager.game_over.connect(_on_game_over)
	game_manager.player_score_changed.connect(_on_score_changed)
	game_manager.current_player_changed.connect(_on_player_changed)

	# GridRenderer oluştur
	var renderer_node = $GridRenderer
	grid_renderer = GridRenderer.new()
	grid_renderer.set_grid_data(game_manager.get_grid())
	grid_renderer.set_cell_size(Vector2(8, 8))  # 1:1 çizim, scale yok
	grid_renderer.set_view_mode(Constants.ViewMode.OVERLAPPED)
	grid_renderer.set_layer_colors(Constants.get_layer_colors(3))

	renderer_node.add_child(grid_renderer)

	# ParticleManager oluştur
	particle_manager = ParticleManager.new()
	add_child(particle_manager)

	# İlk parçayı göster
	_update_renderer()

	print("Test Game Started!")
	print("Controls: Arrow Keys to move, Up to rotate CW, PageDown to rotate CCW")
	print("Space: Hard drop, P: Pause, R: Restart")

# Camera zoom ayarla (ekran boyutuna göre)
func _update_camera_zoom():
	if camera == null:
		return

	var viewport_size = get_viewport().get_visible_rect().size

	# Zoom faktörünü hesapla (ekran boyutuna göre)
	var zoom_x = viewport_size.x / INTERNAL_WIDTH
	var zoom_y = viewport_size.y / INTERNAL_HEIGHT

	# Daha küçük zoom'ı seç (aspect ratio'yu korumak için)
	var zoom_factor = min(zoom_x, zoom_y)

	camera.zoom = Vector2(zoom_factor, zoom_factor)
	print("Viewport: ", viewport_size, " Zoom: ", camera.zoom)

# Window resize callback
func _on_window_resize():
	_update_camera_zoom()

func _process(delta):
	if game_manager == null or game_manager.is_game_over:
		return

	if game_manager.is_paused:
		return

	# Otomatik düşme
	fall_timer += delta
	if fall_timer >= game_manager.current_fall_speed:
		fall_timer = 0.0
		if not game_manager.move_down():
			# Aşağı hareket edemez -> lock et ve yeni piece spawn et
			game_manager.spawn_piece()

	# Input timers
	if move_left_timer > 0:
		move_left_timer -= delta
	if move_right_timer > 0:
		move_right_timer -= delta
	if move_down_timer > 0:
		move_down_timer -= delta

	# Update oyun mantığı
	game_manager.update(delta)

	# Renderer'ı güncelle
	_update_renderer()

func _input(event):
	if game_manager == null:
		return

	# Pause
	if event.is_action_pressed("ui_cancel"):
		game_manager.pause()
		print("Game Paused")
		return

	# Restart
	if event.is_action_pressed("ui_text_backspace"):
		_restart_game()
		return

	if game_manager.is_paused or game_manager.is_game_over:
		if event.is_action_pressed("ui_cancel"):
			game_manager.resume()
			print("Game Resumed")
		return

	# Movement input
	if event.is_action("ui_left"):
		if event.is_pressed():
			if move_left_timer <= 0:
				if game_manager.move_left():
					_update_renderer()
				move_left_timer = Constants.MOVE_DELAY

	elif event.is_action("ui_right"):
		if event.is_pressed():
			if move_right_timer <= 0:
				if game_manager.move_right():
					_update_renderer()
				move_right_timer = Constants.MOVE_DELAY

	elif event.is_action("ui_down"):
		if event.is_pressed():
			if move_down_timer <= 0:
				if not game_manager.move_down():
					# Aşağı hareket edemez -> lock et ve yeni piece spawn et
					game_manager.spawn_piece()
				_update_renderer()
				move_down_timer = Constants.SOFT_DROP_SPEED

	# Rotation
	elif event.is_action_pressed("ui_up"):
		# Saat yönü döndür
		if game_manager.rotate_cw():
			_update_renderer()

	# Ters yöne döndür (Page Down tuşu)
	elif event.is_action_pressed("ui_page_down"):
		# Saat yönü tersine döndür
		if game_manager.rotate_ccw():
			_update_renderer()

	# Hard drop
	elif event.is_action_pressed("ui_select"):
		var drop_distance = game_manager.hard_drop()
		print("Hard drop: %d cells" % drop_distance)
		_update_renderer()

func _update_renderer():
	if grid_renderer == null or game_manager == null:
		return

	# Grid'i güncelle
	grid_renderer._update_all_cells()

	# Aktif parçayı güncelle
	var piece = game_manager.get_current_piece()
	grid_renderer.update_active_piece(piece)
	grid_renderer.update_ghost_piece(piece)

	# Aktif katmanı vurgula
	var layer_idx = game_manager.get_current_layer_index()
	var layer_colors = Constants.get_layer_colors(game_manager.layer_count)
	if layer_idx < layer_colors.size():
		grid_renderer.highlight_layer(layer_idx, layer_colors[layer_idx])

# Signal handlers

func _on_piece_locked(positions: Array, colors: Array):
	print("Piece locked! Spawning particles at ", positions.size(), " positions")

	# Particle efekti
	if particle_manager != null:
		var grid_offset = grid_renderer.global_position if grid_renderer != null else Vector2.ZERO
		var adjusted_positions = []
		var particle_colors = []

		# Overlapped modda karışık renkleri hesapla
		var is_overlapped = (grid_renderer.view_mode == Constants.ViewMode.OVERLAPPED)

		for i in range(positions.size()):
			var pos = positions[i]
			adjusted_positions.append(pos + grid_offset)

			if is_overlapped:
				# Grid pozisyonunu hesapla
				var grid_x = int(pos.x / 32.0)
				var grid_y = int(pos.y / 32.0)

				# O pozisyondaki karışık rengi al
				var colors_at_pos = game_manager.get_grid().get_colors_at_position(grid_x, grid_y)
				var blended_color = Constants.blend_colors(colors_at_pos)
				particle_colors.append(blended_color)
			else:
				# Side-by-side modda normal renk
				particle_colors.append(colors[i])

		particle_manager.spawn_block_place_particles(adjusted_positions, particle_colors)

func _on_piece_placed(player_id: int, layer_index: int, piece: Tetromino):
	print("Piece placed by player %d in layer %d" % [player_id, layer_index])
	_update_renderer()

func _on_rows_cleared(row_indices: Array, score_gained: int):
	print("Rows cleared: %s, Score: %d" % [row_indices, score_gained])

	# Particle efekti (beyaz)
	if particle_manager != null:
		var grid_offset = grid_renderer.global_position if grid_renderer != null else Vector2.ZERO

		for row_y in row_indices:
			particle_manager.spawn_line_clear_particles(row_y, grid_offset)

func _on_layer_changed(player_id: int, old_layer: int, new_layer: int):
	print("Player %d: Layer %d -> %d" % [player_id, old_layer, new_layer])
	print("Now playing in layer: ", Constants.get_layer_colors(game_manager.layer_count)[new_layer])

func _on_game_over():
	print("GAME OVER!")
	print("Final Score: %d" % game_manager.get_score())

func _on_score_changed(player_id: int, new_score: int):
	print("Player %d score: %d" % [player_id, new_score])

func _on_player_changed(player_id: int):
	print("Current player: %d" % player_id)

func _restart_game():
	print("Restarting game...")
	if game_manager != null:
		game_manager.start_game(game_manager.layer_count, game_manager.player_count)
		_update_renderer()

# Debug çizim
func _draw():
	if game_manager == null:
		return

	# Score çiz
	var score = game_manager.get_score()
	draw_string(
		ThemeDB.fallback_font,
		Vector2(400, 50),
		"Score: %d" % score,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20
	)

	# Katman bilgisini çiz
	var layer_idx = game_manager.get_current_layer_index()
	var layer_colors = Constants.get_layer_colors(game_manager.layer_count)
	var layer_name = ""
	match layer_idx:
		0: layer_name = "RED"
		1: layer_name = "GREEN"
		2: layer_name = "BLUE"

	draw_string(
		ThemeDB.fallback_font,
		Vector2(400, 80),
		"Layer: %s" % layer_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16
	)
