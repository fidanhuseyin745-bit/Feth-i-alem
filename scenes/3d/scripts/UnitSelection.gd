extends Node
class_name UnitSelection

## Birim Seçim Sistemi - RTS Tarzı Seçim

signal unit_selected(unit)
signal units_selected(units: Array)
signal selection_cleared()

@export var selection_enabled: bool = true
@export var max_selection: int = 20

var selected_units: Array = []
var all_units: Array = []
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

func _ready():
	print("UnitSelection sistemi hazır")

func register_unit(unit: Node):
	if unit not in all_units:
		all_units.append(unit)

func unregister_unit(unit: Node):
	if unit in all_units:
		all_units.erase(unit)
	if unit in selected_units:
		selected_units.erase(unit)

func select_unit(unit: Node):
	if not selection_enabled:
		return
	
	# Clear previous selection if shift is not held
	if not Input.is_key_pressed(KEY_SHIFT):
		clear_selection()
	
	if unit not in selected_units and selected_units.size() < max_selection:
		selected_units.append(unit)
		emit_signal("unit_selected", unit)
		print("Birim seçildi")

func deselect_unit(unit: Node):
	if unit in selected_units:
		selected_units.erase(unit)
		print("Birim seçimi kaldırıldı")

func clear_selection():
	selected_units.clear()
	emit_signal("selection_cleared")

func select_all_of_type(unit_type: String):
	clear_selection()
	for unit in all_units:
		if unit.get("unit_type") == unit_type:
			selected_units.append(unit)
	
	if selected_units.size() > 0:
		emit_signal("units_selected", selected_units)

func get_selected_units() -> Array:
	return selected_units

func get_selected_count() -> int:
	return selected_units.size()

func is_unit_selected(unit: Node) -> bool:
	return unit in selected_units

func select_in_area(rect: Rect2):
	if not selection_enabled:
		return
	
	var units_in_area = []
	for unit in all_units:
		var screen_pos = _world_to_screen(unit.global_position)
		if rect.has_point(screen_pos):
			units_in_area.append(unit)
	
	clear_selection()
	for unit in units_in_area:
		if selected_units.size() < max_selection:
			selected_units.append(unit)
	
	if selected_units.size() > 0:
		emit_signal("units_selected", selected_units)

func _world_to_screen(world_pos: Vector3) -> Vector2:
	# Simple screen projection
	var camera = get_viewport().get_camera_3d()
	if camera:
		var screen_pos = camera.unproject_position(world_pos)
		return screen_pos
	return Vector2.ZERO

func move_selected_to(target: Vector3):
	for unit in selected_units:
		if unit.has_method("move_to"):
			unit.move_to(target)

func attack_selected(target):
	for unit in selected_units:
		if unit.has_method("attack_target"):
			unit.attack_target(target)

func hold_position():
	for unit in selected_units:
		if unit.has_method("hold_position"):
			unit.hold_position()