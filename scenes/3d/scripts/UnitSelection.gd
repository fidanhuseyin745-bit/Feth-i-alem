extends Node
class_name UnitSelection

## Birim seçimi ve ordu yönetimi - RTS tarzı

signal selection_changed(selected_units: Array[Unit])
signal action_commandIssued(action: String, target: Vector3)

@export var max_selection: int = 20
@export var selection_radius: float = 50.0

var selected_units: Array[Unit] = []
var player_army: Army
var drag_start_pos: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var drag_current_pos: Vector2 = Vector2.ZERO

@onready var camera: RTSCamera
@onready var selection_box: Control  # UI'da gösterilecek seçim kutusu

var units_group: Array[Unit] = []

func _ready():
	player_army = Army.new()
	player_army.army_name = "Oyuncu Ordusu"
	player_army.team = "player"
	add_child(player_army)

func _input(event):
	_handle_selection_input(event)
	_handle_command_input(event)

func _handle_selection_input(event: InputEvent):
	# Mouse/touch ile seçim
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_selection(event.position)
			else:
				_end_selection(event.position)
	
	elif event is InputEventMouseMotion:
		if is_dragging:
			drag_current_pos = event.position
			_update_selection_box()
	
	# Touch için
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_selection(event.position)
		else:
			_end_selection(event.position)

func _start_selection(pos: Vector2):
	drag_start_pos = pos
	is_dragging = true
	
	# Ctrl tuşu basılı değilse önceki seçimi temizle
	if not Input.is_key_pressed(KEY_CTRL):
		clear_selection()

func _end_selection(pos: Vector2):
	if not is_dragging:
		return
	
	var drag_distance = pos.distance_to(drag_start_pos)
	
	if drag_distance < 10:
		# Tıklama - tek birim seç
		var world_pos = camera.screen_to_world(pos) if camera else Vector3.ZERO
		var clicked_unit = _find_unit_at_position(world_pos)
		
		if clicked_unit:
			if clicked_unit in selected_units:
				_deselect_unit(clicked_unit)
			else:
				_select_unit(clicked_unit)
		else:
			# Boş alana tıklandı - seçimi temizle
			clear_selection()
	else:
		# Sürükleme - alan seçimi
		var units_in_rect = _get_units_in_rect(drag_start_pos, pos)
		for unit in units_in_rect:
			if unit.team == "player":
				_select_unit(unit)
	
	is_dragging = false
	_update_selection_box_visibility(false)

func _find_unit_at_position(world_pos: Vector3) -> Unit:
	var closest_unit: Unit = null
	var min_distance = selection_radius
	
	for unit in units_group:
		if unit.team != "player" or unit.current_state == Unit.UnitState.DEAD:
			continue
		
		var distance = unit.global_position.distance_to(world_pos)
		if distance < min_distance:
			min_distance = distance
			closest_unit = unit
	
	return closest_unit

func _get_units_in_rect(start_pos: Vector2, end_pos: Vector2) -> Array[Unit]:
	var units: Array[Unit] = []
	var rect = Rect2(start_pos, end_pos - start_pos).abs()
	
	# Kamera üzerinden dünya pozisyonuna çevir
	for unit in units_group:
		if unit.team != "player" or unit.current_state == Unit.UnitState.DEAD:
			continue
		
		var screen_pos = _world_to_screen(unit.global_position)
		if rect.has_point(screen_pos):
			units.append(unit)
			if units.size() >= max_selection:
				break
	
	return units

func _world_to_screen(world_pos: Vector3) -> Vector2:
	if not camera:
		return Vector2.ZERO
	
	var from = camera.global_position
	var to = world_pos
	var screen_pos = Vector2.ZERO
	
	# Basit projeksiyon
	var relative = to - from
	var angle = atan2(relative.x, relative.z)
	var distance = relative.length()
	
	screen_pos.x = sin(angle) * distance
	screen_pos.y = cos(angle) * distance
	
	return screen_pos + get_viewport().get_visible_rect().size / 2

func _select_unit(unit: Unit):
	if selected_units.size() >= max_selection:
		return
	
	selected_units.append(unit)
	unit.select_unit()
	_update_army_selection()
	selection_changed.emit(selected_units)

func _deselect_unit(unit: Unit):
	selected_units.erase(unit)
	unit.deselect_unit()
	_update_army_selection()
	selection_changed.emit(selected_units)

func clear_selection():
	for unit in selected_units:
		if is_instance_valid(unit):
			unit.deselect_unit()
	selected_units.clear()
	_update_army_selection()
	selection_changed.emit(selected_units)

func select_all_units():
	clear_selection()
	for unit in units_group:
		if unit.team == "player" and unit.current_state != Unit.UnitState.DEAD:
			_select_unit(unit)

func _update_army_selection():
	player_army.selected_units = selected_units.duplicate()

func _handle_command_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Sağ tıklama - komut ver
		_give_move_command(event.position)
	elif event is InputEventScreenTap and event is InputEventScreenTouch:
		# Mobil - çift dokunma komut
		pass

func _give_move_command(target_pos: Vector2):
	if selected_units.size() == 0:
		return
	
	var world_target = camera.screen_to_world(target_pos) if camera else Vector3.ZERO
	
	# Formation dağıtımı
	var formation_positions = _calculate_formation(world_target, selected_units.size())
	
	for i in selected_units.size():
		if i < formation_positions.size():
			selected_units[i].set_target_position(formation_positions[i])
	
	action_commandIssued.emit("move", world_target)

func _calculate_formation(center: Vector3, unit_count: int) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	
	if unit_count <= 5:
		# Küçük grup - tek sıra
		var spacing = 2.5
		var start_x = -(unit_count * spacing) / 2
		for i in unit_count:
			positions.append(center + Vector3(start_x + i * spacing, 0, 0))
	else:
		# Büyük grup - kare formation
		var side = ceil(sqrt(unit_count))
		var spacing = 2.5
		var start_x = -(side * spacing) / 2
		var start_z = -(side * spacing) / 2
		var index = 0
		
		for row in side:
			for col in side:
				if index < unit_count:
					positions.append(center + Vector3(start_x + col * spacing, 0, start_z + row * spacing))
					index += 1
	
	return positions

func _update_selection_box():
	if not selection_box:
		return
	_update_selection_box_visibility(true)

func _update_selection_box_visibility(visible: bool):
	if selection_box:
		selection_box.visible = visible

func register_unit(unit: Unit):
	if not unit in units_group:
		units_group.append(unit)
		player_army.add_unit(unit)

func unregister_unit(unit: Unit):
	units_group.erase(unit)
	_deselect_unit(unit)
	player_army.remove_unit(unit)

func get_selected_count() -> int:
	return selected_units.size()

func get_selected_army() -> Array[Unit]:
	return selected_units.duplicate()