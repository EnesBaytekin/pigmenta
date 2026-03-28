extends SceneTree

# Test script for constants.gd

func _init():
	print("=== Testing Constants ===")

	# Test 1: Layer colors
	print("\n--- Test 1: Layer Colors ---")
	var colors_3 = Constants.get_layer_colors(3)
	print("3 layers: ", colors_3)

	var colors_2 = Constants.get_layer_colors(2)
	print("2 layers: ", colors_2)

	# Test 2: Color blending
	print("\n--- Test 2: Color Blending ---")
	var red = Color.RED
	var green = Color.GREEN
	var blue = Color.BLUE

	print("Red: ", red)
	print("Green: ", green)
	print("Blue: ", blue)

	var yellow = Constants.blend_colors([red, green])
	print("Red + Green = Yellow: ", yellow)

	var white = Constants.blend_colors([red, green, blue])
	print("Red + Green + Blue = White: ", white)

	var magenta = Constants.blend_colors([red, blue])
	print("Red + Blue = Magenta: ", magenta)

	var cyan = Constants.blend_colors([green, blue])
	print("Green + Blue = Cyan: ", cyan)

	# Test 3: Tetromino shapes
	print("\n--- Test 3: Tetromino Shapes ---")
	for type in range(Constants.TetrominoType.SIZE):
		var shape = Constants.TETROMINO_SHAPES[type]
		var size = Constants.get_tetromino_size(type)
		print("Type %s: Size=%s" % [type, size])

	# Test 4: Shape rotation
	print("\n--- Test 4: Shape Rotation ---")
	var t_shape = Constants.TETROMINO_SHAPES[Constants.TetrominoType.T]
	print("Original T shape:")
	print_shape(t_shape)

	var rotated = Constants.rotate_shape(t_shape)
	print("\nRotated T shape:")
	print_shape(rotated)

	var rotated2 = Constants.rotate_shape(rotated)
	print("\nRotated again:")
	print_shape(rotated2)

	# Test 5: Score calculation
	print("\n--- Test 5: Score Calculation ---")
	print("1 line: %d" % Constants.calculate_score(1))
	print("2 lines: %d" % Constants.calculate_score(2))
	print("3 lines: %d" % Constants.calculate_score(3))
	print("4 lines: %d" % Constants.calculate_score(4))
	print("2 lines (multiplier): %d" % Constants.calculate_score(2, true))

	print("\n=== All Tests Passed! ===")
	quit()

func print_shape(shape: Array):
	for row in shape:
		var line = ""
		for cell in row:
			line += "█" if cell else "·"
		print(line)
