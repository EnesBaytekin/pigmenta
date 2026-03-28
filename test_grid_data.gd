extends SceneTree

# Test script for GridData class

func _init():
	print("=== Testing GridData ===")

	# Test 1: Single layer grid
	print("\n--- Test 1: Single Layer Grid (10x20) ---")
	var grid1 = GridData.new(10, 20, 1)
	print("Created grid: %dx%dx%d" % [grid1.width, grid1.height, grid1.layer_count])
	assert(grid1.width == 10)
	assert(grid1.height == 20)
	assert(grid1.layer_count == 1)

	# Test 2: Three layer grid
	print("\n--- Test 2: Three Layer Grid (10x20x3) ---")
	var grid3 = GridData.new(10, 20, 3)
	print("Created grid: %dx%dx%d" % [grid3.width, grid3.height, grid3.layer_count])
	assert(grid3.width == 10)
	assert(grid3.height == 20)
	assert(grid3.layer_count == 3)

	# Test 3: Set and get cells
	print("\n--- Test 3: Set and Get Cells ---")
	grid3.set_cell(0, 5, 10, Color.RED)
	grid3.set_cell(1, 5, 10, Color.GREEN)
	grid3.set_cell(2, 5, 10, Color.BLUE)

	var c0 = grid3.get_cell(0, 5, 10)
	var c1 = grid3.get_cell(1, 5, 10)
	var c2 = grid3.get_cell(2, 5, 10)

	print("Layer 0 (5,10): ", c0)
	print("Layer 1 (5,10): ", c1)
	print("Layer 2 (5,10): ", c2)

	assert(c0 == Color.RED)
	assert(c1 == Color.GREEN)
	assert(c2 == Color.BLUE)

	# Test 4: Is occupied
	print("\n--- Test 4: Is Occupied ---")
	assert(grid3.is_occupied_in_layer(0, 5, 10) == true)
	assert(grid3.is_occupied_in_layer(0, 5, 11) == false)
	assert(grid3.is_occupied(5, 10) == true)  # Tüm katmanlarda
	assert(grid3.is_occupied(5, 11) == false)

	# Test 5: Place block (tetromino)
	print("\n--- Test 5: Place Block ---")
	var t_shape = Constants.TETROMINO_SHAPES[Constants.TetrominoType.T]
	var success = grid3.place_block(0, t_shape, 3, 5, Color.RED)
	print("Placed T shape at (3,5): ", success)
	assert(success == true)

	# Cannot place on top of existing block
	success = grid3.place_block(0, t_shape, 3, 5, Color.BLUE)
	print("Placed on top: ", success)
	assert(success == false)

	# Test 6: Row detection (fill a row)
	print("\n--- Test 6: Row Detection ---")
	var test_grid = GridData.new(10, 20, 2)
	# Fill row 15 in both layers
	for x in range(10):
		test_grid.set_cell(0, x, 15, Color.RED)
		test_grid.set_cell(1, x, 15, Color.GREEN)

	print("Row 15 full in layer 0: ", test_grid.is_row_full(0, 15))
	print("Row 15 full in layer 1: ", test_grid.is_row_full(1, 15))
	print("Row 15 full in ALL layers: ", test_grid.is_row_full_all_layers(15))

	assert(test_grid.is_row_full(0, 15) == true)
	assert(test_grid.is_row_full(1, 15) == true)
	assert(test_grid.is_row_full_all_layers(15) == true)

	# Test 7: Clear row
	print("\n--- Test 7: Clear Row ---")
	var cleared = test_grid.clear_row(15)
	print("Cleared row 15, got %d layers of colors" % cleared.size())
	assert(cleared.size() == 2)
	assert(test_grid.is_row_full_all_layers(15) == false)

	# Test 8: Get full rows
	print("\n--- Test 8: Get Full Rows ---")
	var multi_row_grid = GridData.new(10, 20, 2)
	# Fill rows 18 and 19 in both layers
	for x in range(10):
		multi_row_grid.set_cell(0, x, 18, Color.RED)
		multi_row_grid.set_cell(1, x, 18, Color.GREEN)
		multi_row_grid.set_cell(0, x, 19, Color.RED)
		multi_row_grid.set_cell(1, x, 19, Color.GREEN)

	var full_rows = multi_row_grid.get_full_rows()
	print("Full rows: ", full_rows)
	assert(full_rows.size() == 2)
	assert(18 in full_rows)
	assert(19 in full_rows)

	# Test 9: Get colors at position
	print("\n--- Test 9: Get Colors at Position ---")
	var test_pos_grid = GridData.new(10, 20, 3)
	test_pos_grid.set_cell(0, 3, 5, Color.RED)
	test_pos_grid.set_cell(1, 3, 5, Color.GREEN)
	test_pos_grid.set_cell(2, 3, 5, Color.BLUE)

	var colors = test_pos_grid.get_colors_at_position(3, 5)
	print("Colors at (3,5): ", colors)
	assert(colors.size() == 3)
	assert(Color.RED in colors)
	assert(Color.GREEN in colors)
	assert(Color.BLUE in colors)

	# Test 10: Clone
	print("\n--- Test 10: Clone Grid ---")
	var original = GridData.new(10, 20, 2)
	original.set_cell(0, 5, 10, Color.RED)
	var cloned = original.clone()
	cloned.set_cell(0, 5, 10, Color.BLUE)

	print("Original cell (0,5,10): ", original.get_cell(0, 5, 10))
	print("Cloned cell (0,5,10): ", cloned.get_cell(0, 5, 10))
	assert(original.get_cell(0, 5, 10) == Color.RED)
	assert(cloned.get_cell(0, 5, 10) == Color.BLUE)

	# Test 11: Serialize/Deserialize
	print("\n--- Test 11: Serialize/Deserialize ---")
	var save_grid = GridData.new(10, 20, 2)
	save_grid.set_cell(0, 1, 2, Color.RED)
	save_grid.set_cell(0, 3, 4, Color.GREEN)
	save_grid.set_cell(1, 5, 6, Color.BLUE)

	var data = save_grid.to_dict()
	print("Serialized grid: ", data.size(), " keys")

	var load_grid = GridData.from_dict(data)
	print("Loaded grid: %dx%dx%d" % [load_grid.width, load_grid.height, load_grid.layer_count])
	assert(load_grid.width == 10)
	assert(load_grid.height == 20)
	assert(load_grid.layer_count == 2)
	assert(load_grid.get_cell(0, 1, 2) == Color.RED)
	assert(load_grid.get_cell(0, 3, 4) == Color.GREEN)
	assert(load_grid.get_cell(1, 5, 6) == Color.BLUE)

	print("\n=== All GridData Tests Passed! ===")
	quit()
