extends Node

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
const FIRST_INPUT_DELAY = 0.3  # İlk basışta bekleme süresi
const REPEAT_INPUT_DELAY = 0.04  # Tekrarlayan basışlar arası bekleme

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

# Tetramino Şekilleri (her shape 4x4 grid'de tanımlı)
const TETROMINO_SHAPES = {
	TetrominoType.I: [
		[0,0,0,0],
		[1,1,1,1],
		[0,0,0,0],
		[0,0,0,0]
	],
	TetrominoType.O: [
		[1,1],
		[1,1]
	],
	TetrominoType.T: [
		[0,1,0],
		[1,1,1],
		[0,0,0]
	],
	TetrominoType.S: [
		[0,1,1],
		[1,1,0],
		[0,0,0]
	],
	TetrominoType.Z: [
		[1,1,0],
		[0,1,1],
		[0,0,0]
	],
	TetrominoType.J: [
		[1,0,0],
		[1,1,1],
		[0,0,0]
	],
	TetrominoType.L: [
		[0,0,1],
		[1,1,1],
		[0,0,0]
	]
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

# Her tetromino için rotasyon sayısı
const ROTATION_COUNTS = {
	TetrominoType.I: 4,
	TetrominoType.O: 1,
	TetrominoType.T: 4,
	TetrominoType.S: 2,
	TetrominoType.Z: 2,
	TetrominoType.J: 4,
	TetrominoType.L: 4
}

# SRS Wall Kick Data (basitleştirilmiş)
# Format: [rotation_offset, kick_tests]
# kick_tests: [x_offset, y_offset] pairs to try
const WALL_KICK_DATA = {
	"normal": [
		[Vector2i(0,0), Vector2i(-1,0), Vector2i(-1,1), Vector2i(0,-2), Vector2i(-1,-2)],  # 0->R
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,-1), Vector2i(0,2), Vector2i(1,2)],       # R->2
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(0,-2), Vector2i(1,-2)],      # 2->L
		[Vector2i(0,0), Vector2i(-1,0), Vector2i(-1,-1), Vector2i(0,2), Vector2i(-1,2)]      # L->0
	],
	"I": [
		[Vector2i(0,0), Vector2i(-2,0), Vector2i(1,0), Vector2i(-2,-1), Vector2i(1,2)],
		[Vector2i(0,0), Vector2i(-1,0), Vector2i(2,0), Vector2i(-1,2), Vector2i(2,-1)],
		[Vector2i(0,0), Vector2i(2,0), Vector2i(-1,0), Vector2i(2,1), Vector2i(-1,-2)],
		[Vector2i(0,0), Vector2i(1,0), Vector2i(-2,0), Vector2i(1,-2), Vector2i(-2,1)]
	]
}

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

## Tetramino şeklini döndür (90 derece saat yönü)
static func rotate_shape(shape: Array) -> Array:
	var n = shape.size()
	var m = shape[0].size()
	var rotated = []

	for i in range(m):
		var row = []
		for j in range(n - 1, -1, -1):
			row.append(shape[j][i])
		rotated.append(row)

	return rotated

## Belirli bir rotasyon için wall kick testlerini döndür
static func get_wall_kicks(type: TetrominoType, rotation_state: int) -> Array:
	var key = "normal" if type != TetrominoType.I else "I"
	var kicks = WALL_KICK_DATA[key]
	return kicks[rotation_state] if rotation_state < kicks.size() else []

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
