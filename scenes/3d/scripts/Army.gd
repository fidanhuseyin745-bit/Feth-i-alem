extends Node3D
class_name Army

## Ordu sınıfı - Birden fazla birimi yönetir

signal army_selected(army: Army)
signal army_deselected(army: Army)
signal unit_added(unit: Unit)
signal unit_removed(unit: Unit)
signal army_moved(army: Army, target: Vector3)
signal army_attacked(army: Army, enemy: Army)

enum Formation { LINE, COLUMN, SQUARE, FLANK }

@export var army_name: String = "Ordu"
@export var team: String = "player"
@export var current_formation: Formation = Formation.LINE
@export var move_speed: float = 3.0

var units: Array[Unit] = []
var selected_units: Array[Unit] = []
var is_selected: bool = false
var target_destination: Vector3 = Vector3.ZERO
var is_moving: bool = false

var total_units: int:
	get: return units.size()

var total_health: int:
	get:
		var total = 0
		for unit in units:
			if unit.current_state != Unit.UnitState.DEAD:
				total += unit.health
		return total

var total_damage: int:
	get:
		var total = 0
		for unit in units:
			if unit.current_state != Unit.UnitState.DEAD:
				total += unit.damage
		return total

func _ready():
	pass

func add_unit(unit: Unit):
	units.append(unit)
	unit.team = team
	unit.unit_selected.connect(_on_unit_selected)
	unit.unit_deselected.connect(_on_unit_deselected)
	unit.unit_died.connect(_on_unit_died)
	unit_added.emit(unit)

func remove_unit(unit: Unit):
	units.erase(unit)
	selected_units.erase(unit)
	unit_removed.emit(unit)

func _on_unit_selected(unit: Unit):
	if unit in units:
		selected_units.append(unit)

func _on_unit_deselected(unit: Unit):
	selected_units.erase(unit)

func _on_unit_died(unit: Unit):
	await get_tree().process_frame
	remove_unit(unit)

func select_all():
	is_selected = true
	for unit in units:
		if unit.current_state != Unit.UnitState.DEAD:
			unit.select_unit()
	army_selected.emit(self)

func deselect_all():
	is_selected = false
	selected_units.clear()
	for unit in units:
		unit.deselect_unit()
	army_deselected.emit(self)

func set_formation(formation: Formation):
	current_formation = formation
	_update_formation_positions()

func _update_formation_positions():
	match current_formation:
		Formation.LINE:
			_formation_line()
		Formation.COLUMN:
			_formation_column()
		Formation.SQUARE:
			_formation_square()
		Formation.FLANK:
			_formation_flank()

func _formation_line():
	var spacing = 2.0
	var start_x = -(units.size() * spacing) / 2
	for i in units.size():
		units[i].formation_position = global_position + Vector3(start_x + i * spacing, 0, 0)

func _formation_column():
	var spacing = 2.0
	var start_z = -(units.size() * spacing) / 2
	for i in units.size():
		units[i].formation_position = global_position + Vector3(0, 0, start_z + i * spacing)

func _formation_square():
	var side = ceil(sqrt(units.size()))
	var spacing = 2.0
	var start_x = -(side * spacing) / 2
	var start_z = -(side * spacing) / 2
	var index = 0
	for row in side:
		for col in side:
			if index < units.size():
				units[index].formation_position = global_position + Vector3(
					start_x + col * spacing, 0, start_z + row * spacing
				)
				index += 1

func _formation_flank():
	var half = units.size() / 2
	var spacing = 2.0
	for i in units.size():
		if i < half:
			units[i].formation_position = global_position + Vector3(-spacing * 2, 0, i * spacing)
		else:
			units[i].formation_position = global_position + Vector3(spacing * 2, 0, (i - half) * spacing)

func move_to(target_pos: Vector3):
	target_destination = target_pos
	is_moving = true
	
	# Formasyonu güncelle
	_update_formation_positions()
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 1.0 / move_speed)
	tween.tween_callback(_on_movement_complete)
	
	# Birimleri de hareket ettir
	for unit in units:
		var offset = unit.formation_position - global_position
		unit.set_target_position(target_pos + offset)
	
	army_moved.emit(self, target_pos)

func _on_movement_complete():
	is_moving = false

func attack_target(enemy: Army):
	if not enemy or not is_instance_valid(enemy):
		return
	
	army_attacked.emit(self, enemy)
	
	# Düşmana doğru hareket et
	var direction = (enemy.global_position - global_position).normalized()
	var distance = global_position.distance_to(enemy.global_position)
	
	if distance > 5:
		var attack_pos = enemy.global_position - direction * 5
		move_to(attack_pos)
	
	# Birimleri düşmana saldırmaya yönlendir
	for unit in units:
		if unit.current_state != Unit.UnitState.DEAD and enemy.units.size() > 0:
			var closest_enemy = _find_closest_enemy(unit, enemy.units)
			if closest_enemy:
				unit.target = closest_enemy
				unit.current_state = Unit.UnitState.ATTACKING

func _find_closest_enemy(from_unit: Unit, enemies: Array) -> Unit:
	var closest: Unit = null
	var min_distance = INF
	
	for enemy in enemies:
		if enemy.current_state == Unit.UnitState.DEAD:
			continue
		var distance = from_unit.global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			closest = enemy
	
	return closest

func hold_position():
	is_moving = false
	for unit in units:
		unit.current_state = Unit.UnitState.DEFENDING
		target_destination = global_position

func split_army(count: int) -> Array[Army]:
	var new_armies: Array[Army] = []
	var units_per_army = units.size() / count
	
	for i in count:
		var new_army = Army.new()
		new_army.army_name = army_name + "_" + str(i + 1)
		new_army.team = team
		add_child(new_army)
		
		for j in units_per_army:
			var index = i * units_per_army + j
			if index < units.size():
				new_army.add_unit(units[index])
		
		new_armies.append(new_army)
	
	return new_armies

func merge_with(other: Army):
	for unit in other.units:
		add_unit(unit)
	other.queue_free()

func get_units_by_type(type: Unit.UnitType) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit in units:
		if unit.unit_type == type and unit.current_state != Unit.UnitState.DEAD:
			result.append(unit)
	return result

func get_all_alive_units() -> Array[Unit]:
	var result: Array[Unit] = []
	for unit in units:
		if unit.current_state != Unit.UnitState.DEAD:
			result.append(unit)
	return result

func is_defeated() -> bool:
	return get_all_alive_units().size() == 0

func get_army_strength() -> float:
	var strength = 0.0
	for unit in units:
		if unit.current_state != Unit.UnitState.DEAD:
			strength += unit.damage * (unit.health / float(unit.max_health))
	return strength