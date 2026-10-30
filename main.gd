extends Control

var current_player: String = "X"
var next_outer_target = null  # Vector2(row, col)

var board = []
var buttons = []
var sub_grid_panels = []
var scored_lines = []
var is_game_over = false

# UI Label & Button references
var turn_label: Label
var score_label: Label
var end_game_button: Button

func _ready():
	# 1. Main vertical stack layout
	var main_stack = VBoxContainer.new()
	main_stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_stack.add_theme_constant_override("separation", 25)
	add_child(main_stack)
	
	# 2. Sleek Scoreboard UI Header at the very top
	var ui_container = VBoxContainer.new()
	ui_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_stack.add_child(ui_container)
	
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 20)
	ui_container.add_child(top_spacer)
	
	score_label = Label.new()
	score_label.text = "Score  X: 0  |  O: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 24)
	ui_container.add_child(score_label)
	
	turn_label = Label.new()
	turn_label.text = "Player X's Turn"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.add_theme_font_size_override("font_size", 14)
	ui_container.add_child(turn_label)
	
	var button_center = CenterContainer.new()
	ui_container.add_child(button_center)
	
	end_game_button = Button.new()
	end_game_button.text = "End Match & Tally Score"
	end_game_button.custom_minimum_size = Vector2(180, 35)
	end_game_button.pressed.connect(self._on_end_game_pressed)
	button_center.add_child(end_game_button)

	# 3. Game Board Area Center Container
	var board_center_container = CenterContainer.new()
	board_center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_stack.add_child(board_center_container)

	# 4. Setup internal tracking arrays
	setup_internal_board()
	
	# 5. Build Grid Layout
	var master_grid = GridContainer.new()
	master_grid.columns = 3
	master_grid.add_theme_constant_override("h_separation", 15)
	master_grid.add_theme_constant_override("v_separation", 15)
	board_center_container.add_child(master_grid)
	
	for or_r in range(3):
		buttons.append([])
		sub_grid_panels.append([])
		for or_c in range(3):
			buttons[or_r].append([])
			
			var panel = PanelContainer.new()
			var style_box = StyleBoxFlat.new()
			style_box.bg_color = Color(0.2, 0.2, 0.25)
			style_box.set_corner_radius_all(4)
			style_box.set_content_margin_all(6)
			panel.add_theme_stylebox_override("panel", style_box)
			
			master_grid.add_child(panel)
			sub_grid_panels[or_r].append(panel)
			
			var sub_grid = GridContainer.new()
			sub_grid.columns = 3
			sub_grid.add_theme_constant_override("h_separation", 4)
			sub_grid.add_theme_constant_override("v_separation", 4)
			panel.add_child(sub_grid)
			
			for in_r in range(3):
				buttons[or_r][or_c].append([])
				for in_c in range(3):
					var btn = Button.new()
					btn.text = " "
					btn.custom_minimum_size = Vector2(45, 45)
					btn.pressed.connect(self._on_button_pressed.bind(or_r, or_c, in_r, in_c))
					sub_grid.add_child(btn)
					buttons[or_r][or_c][in_r].append(btn)
					
	highlight_target_grids()

func setup_internal_board():
	for or_r in range(3):
		board.append([])
		for or_c in range(3):
			board[or_r].append([])
			for in_r in range(3):
				board[or_r][or_c].append([])
				for in_c in range(3):
					board[or_r][or_c][in_r].append(" ")

func _on_button_pressed(or_r: int, or_c: int, in_r: int, in_c: int):
	if is_game_over:
		return
		
	if next_outer_target != null and next_outer_target != Vector2(or_r, or_c):
		if not is_grid_full(next_outer_target.x, next_outer_target.y):
			return
		
	if board[or_r][or_c][in_r][in_c] != " ":
		return
		
	# Update data matrix
	board[or_r][or_c][in_r][in_c] = current_player
	
	# Update visual button text directly
	buttons[or_r][or_c][in_r][in_c].text = current_player
	
	# Check for 3-in-a-row scoring
	check_line_cancel(or_r, or_c)
	
	next_outer_target = Vector2(in_r, in_c)
	current_player = "O" if current_player == "X" else "X"
	
	update_ui()
	
	if is_board_completely_full():
		declare_final_winner()
	else:
		highlight_target_grids()

func _on_end_game_pressed():
	if is_game_over:
		return
	declare_final_winner()

func is_grid_full(or_r: int, or_c: int) -> bool:
	for r in range(3):
		for c in range(3):
			if board[or_r][or_c][r][c] == " ":
				return false
	return true

func is_board_completely_full() -> bool:
	for r in range(3):
		for c in range(3):
			if not is_grid_full(r, c):
				return false
	return true

func check_line_cancel(or_r: int, or_c: int):
	var grid = board[or_r][or_c]
	var lines = [
		[Vector2(0,0), Vector2(0,1), Vector2(0,2)], [Vector2(1,0), Vector2(1,1), Vector2(1,2)], [Vector2(2,0), Vector2(2,1), Vector2(2,2)],
		[Vector2(0,0), Vector2(1,0), Vector2(2,0)], [Vector2(0,1), Vector2(1,1), Vector2(2,1)], [Vector2(0,2), Vector2(1,2), Vector2(2,2)],
		[Vector2(0,0), Vector2(1,1), Vector2(2,2)], [Vector2(0,2), Vector2(1,1), Vector2(2,0)]
	]
	
	for line in lines:
		var p1 = line[0]
		var p2 = line[1]
		var p3 = line[2]
		
		var v1 = grid[p1.x][p1.y]
		var v2 = grid[p2.x][p2.y]
		var v3 = grid[p3.x][p3.y]
		
		if v1 != " " and v1 == v2 and v2 == v3:
			# Verify uniqueness without complex formatting arrays
			var match_key = str(or_r) + "_" + str(or_c) + "_" + str(p1) + str(p2) + str(p3)
			if not scored_lines.has(match_key):
				scored_lines.append(match_key)
				
				# Strike out the completed values using character wrappers
				for pt in line:
					var b = buttons[or_r][or_c][pt.x][pt.y]
					if not b.text.begins_with("-"):
						b.text = "-" + b.text + "-"

func highlight_target_grids():
	var target_is_full = false
	if next_outer_target != null:
		target_is_full = is_grid_full(next_outer_target.x, next_outer_target.y)
		
	for r in range(3):
		for c in range(3):
			var panel = sub_grid_panels[r][c]
			var sb = panel.get_theme_stylebox("panel").duplicate()
			
			if next_outer_target == Vector2(r, c) and not target_is_full:
				sb.bg_color = Color(0.15, 0.35, 0.2) # Active highlighted green
			elif next_outer_target == null or target_is_full:
				sb.bg_color = Color(0.2, 0.2, 0.25) # Open board neutral layout
			else:
				sb.bg_color = Color(0.1, 0.1, 0.12) # Locked grid background tint
				
			panel.add_theme_stylebox_override("panel", sb)

func update_ui():
	var score_x = 0
	var score_o = 0
	
	# Evaluate simple counts
	for match_key in scored_lines:
		if match_key.contains("X"):
			score_x += 1
		else:
			score_o += 1
			
	score_label.text = "Score  X: " + str(score_x) + "  |  O: " + str(score_o)
	if not is_game_over:
		turn_label.text = "Player " + current_player + "'s Turn"

func declare_final_winner():
	is_game_over = true
	end_game_button.disabled = true
	
	var score_x = 0
	var score_o = 0
	for match_key in scored_lines:
		if match_key.contains("X"): score_x += 1
		else: score_o += 1
			
	if score_x > score_o:
		turn_label.text = "MATCH TERMINATED: PLAYER X WINS!"
	elif score_o > score_x:
		turn_label.text = "MATCH TERMINATED: PLAYER O WINS!"
	else:
		turn_label.text = "MATCH TERMINATED: IT'S A DRAW!"
