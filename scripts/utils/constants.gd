extends Node

# Game Setup Settings (Menüden gelen ayarlar)
var game_player_count: int = 1
var game_color_count: int = 2
var game_side_by_side: bool = false
var game_block_colors: Array = [Color.RED, Color.GREEN]
var game_player_colors: Array = [Color.RED]
var game_handicap: int = 0

# Grid Boyutları
const GRID_WIDTH = 10
const GRID_HEIGHT = 20

# Katman Renkleri (RGB ışık renkleri - additive color blending için)
const LAYER_COLORS = {
	1: [Color.RED],
	2: [Color.RED, Color.GREEN],
	3: [Color.RED, Color.GREEN, Color.BLUE]
}

# Oyun Sabitleri
const DEFAULT_FALL_SPEED = 1.0  # Saniye başına düşme sayısı
const FAST_FALL_SPEED = 0.1     # Hard drop hız çarpanı
const LOCK_DELAY = 0.5          # Blok lock bekleme süresi
const FIRST_INPUT_DELAY = 0.2  # İlk basışta bekleme süresi
const REPEAT_INPUT_DELAY = 0.017  # Tekrarlayan basışlar arası bekleme

# Score Sistemi
const SCORE_SINGLE = 100
const SCORE_DOUBLE = 300
const SCORE_TRIPLE = 500
const SCORE_TETRIS = 800
const SCORE_MULTIPLIER_BONUS = 1.5  # Birden fazla satır için bonus çarpan

# Hızlanma Sistemi (Klasik Tetris)
const SPEED_INCREASE_INTERVAL = 10.0  # Her 10 saniyede
const SPEED_INCREASE_RATE = 0.98       # %2 hızlanma
const MIN_FALL_SPEED = 0.1             # Maksimum hız

# Particle Ayarları
const PARTICLE_ENABLED_DEFAULT = true
const PARTICLE_COUNT_PER_BLOCK = 15
const PARTICLE_LIFETIME = 0.5
const PARTICLE_EXPLOSION_SPEED = 100.0
const PARTICLE_GRAVITY = 800.0  # Yer çekimi ivmesi (piksel/saniye²)

# Tetramino Tipleri
enum TetrominoType {
	I,
	O,
	T,
	S,
	Z,
	J,
	L
}

# Tetramino Rotasyonları (her blok için tüm rotasyon state'leri)
# Index arttıkça saat yönünde 90 derece dönmüş olur
# Her rotasyonda bloklar aşağı yaslı durur
const TETROMINO_ROTATIONS = {
	TetrominoType.I: [
		# Rotation 0 - Yatay
		[
			[0,0,0,0],
			[1,1,1,1],
			[0,0,0,0],
			[0,0,0,0]
		],
		# Rotation 1 - Dikey
		[
			[0,0,1,0],
			[0,0,1,0],
			[0,0,1,0],
			[0,0,1,0]
		]
	],
	TetrominoType.O: [
		# Rotation 0 (O bloğu dönmez)
		[
			[1,1],
			[1,1]
		]
	],
	TetrominoType.T: [
		# Rotation 0
		[
			[0,0,0],
			[1,1,1],
			[0,1,0]
		],
		# Rotation 1
		[
			[0,1,0],
			[1,1,0],
			[0,1,0]
		],
		# Rotation 2
		[
			[0,0,0],
			[0,1,0],
			[1,1,1]
		],
		# Rotation 3
		[
			[0,1,0],
			[0,1,1],
			[0,1,0]
		]
	],
	TetrominoType.S: [
		# Rotation 0
		[
			[0,0,0],
			[0,1,1],
			[1,1,0]
		],
		# Rotation 1
		[
			[1,0,0],
			[1,1,0],
			[0,1,0]
		]
	],
	TetrominoType.Z: [
		# Rotation 0
		[
			[0,0,0],
			[1,1,0],
			[0,1,1]
		],
		# Rotation 1
		[
			[0,0,1],
			[0,1,1],
			[0,1,0]
		]
	],
	TetrominoType.J: [
		# Rotation 0
		[
			[0,0,0],
			[1,1,1],
			[0,0,1]
		],
		# Rotation 1
		[
			[0,1,0],
			[0,1,0],
			[1,1,0]
		],
		# Rotation 2
		[
			[0,0,0],
			[1,0,0],
			[1,1,1]
		],
		# Rotation 3
		[
			[0,1,1],
			[0,1,0],
			[0,1,0]
		]
	],
	TetrominoType.L: [
		# Rotation 0
		[
			[0,0,0],
			[1,1,1],
			[1,0,0]
		],
		# Rotation 1
		[
			[1,1,0],
			[0,1,0],
			[0,1,0]
		],
		# Rotation 2
		[
			[0,0,0],
			[0,0,1],
			[1,1,1]
		],
		# Rotation 3
		[
			[0,1,0],
			[0,1,0],
			[0,1,1]
		]
	]
}

# Tetramino Şekilleri (backward compatibility için - ilk rotasyon)
const TETROMINO_SHAPES = {
	TetrominoType.I: TETROMINO_ROTATIONS[TetrominoType.I][0],
	TetrominoType.O: TETROMINO_ROTATIONS[TetrominoType.O][0],
	TetrominoType.T: TETROMINO_ROTATIONS[TetrominoType.T][0],
	TetrominoType.S: TETROMINO_ROTATIONS[TetrominoType.S][0],
	TetrominoType.Z: TETROMINO_ROTATIONS[TetrominoType.Z][0],
	TetrominoType.J: TETROMINO_ROTATIONS[TetrominoType.J][0],
	TetrominoType.L: TETROMINO_ROTATIONS[TetrominoType.L][0]
}

# Tetramino spawn pozisyonları (merkez noktaları)
const SPAWN_POSITIONS = {
	TetrominoType.I: Vector2i(3, 0),
	TetrominoType.O: Vector2i(4, 0),
	TetrominoType.T: Vector2i(4, 0),
	TetrominoType.S: Vector2i(4, 0),
	TetrominoType.Z: Vector2i(4, 0),
	TetrominoType.J: Vector2i(4, 0),
	TetrominoType.L: Vector2i(4, 0)
}

# Oyun Modları
enum ViewMode {
	OVERLAPPED,   # İç içe (tek grid, renk karışımı)
	SIDE_BY_SIDE  # Yan yana (ayrı grid'ler)
}

enum ScoreMode {
	SHARED,       # Ortak score
	SEPARATE      # Her oyuncu kendi score'u
}

enum SpeedMode {
	CLASSIC,      # Zamanla hızlanan
	CONSTANT      # Sabit hız
}

# Her tetromino için rotasyon sayısı (otomatik hesaplanan)
static func get_rotation_count(type: TetrominoType) -> int:
	return TETROMINO_ROTATIONS[type].size()


# Helper Functions

## Belirli bir sayıda katman için renkleri döndür
static func get_layer_colors(count: int) -> Array:
	if count >= 1 and count <= 3:
		return LAYER_COLORS[count]
	push_error("Invalid layer count: %d" % count)
	return []

## İki rengi karıştır (additive blending - ışık karışımı)
static func blend_colors(colors: Array) -> Color:
	if colors.is_empty():
		return Color.BLACK

	var result = Color(0, 0, 0)
	for c in colors:
		result.r = min(result.r + c.r, 1.0)
		result.g = min(result.g + c.g, 1.0)
		result.b = min(result.b + c.b, 1.0)

	return result

## Tetramino şeklinin boyutunu döndür
static func get_tetromino_size(type: TetrominoType) -> Vector2i:
	var shape = TETROMINO_SHAPES[type]
	return Vector2i(shape[0].size(), shape.size())

## Score'u hesapla (satır sayısına göre)
static func calculate_score(lines_cleared: int, use_multiplier: bool = false) -> int:
	var base_score = 0
	match lines_cleared:
		1: base_score = SCORE_SINGLE
		2: base_score = SCORE_DOUBLE
		3: base_score = SCORE_TRIPLE
		4: base_score = SCORE_TETRIS

	if use_multiplier and lines_cleared > 1:
		base_score = int(base_score * SCORE_MULTIPLIER_BONUS)

	return base_score

## Game setup ayarlarını kaydet (menüden çağrılır)
func set_game_settings(player_count: int, color_count: int, side_by_side: bool, block_colors: Array, player_colors: Array, handicap: int):
	game_player_count = player_count
	game_color_count = color_count
	game_side_by_side = side_by_side
	game_block_colors = block_colors.duplicate()
	game_player_colors = player_colors.duplicate()
	game_handicap = handicap

	print("Game settings saved to Constants:")
	print("  Players: ", game_player_count)
	print("  Colors: ", game_color_count)
	print("  Side by Side: ", game_side_by_side)
	print("  Block Colors: ", game_block_colors)
	print("  Player Colors: ", game_player_colors)
	print("  Handicap: ", game_handicap)
