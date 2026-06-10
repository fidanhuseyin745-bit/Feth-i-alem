extends CharacterBody3D
class_name Unit

## Temel birim sınıfı - Tüm birimler bu sınıftan türetilir

signal unit_selected(unit: Unit)
signal unit_deselected(unit: Unit)
signal unit_moved(unit: Unit, target_pos: Vector3)
signal unit_attacked(unit: Unit, target: Unit)
signal unit_died(unit: Unit)

enum UnitType { INFANTRY, CAVALRY, ARCHER, SPECIAL }
enum UnitState { IDLE, MOVING, ATTACKING, DEFENDING, DEAD }

@export var unit_name: String = "Asker"
@export var unit_type: UnitType = UnitType.INFANTRY
@export var health: int = 100
@export var max_health: int = 100
@export var damage: int = 15
@export var defense: int = 5
@export var speed: float = 5.0
@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.0
@export var cost: int = 50

var current_state: UnitState = UnitState.IDLE
var team: String = "player"  # "player", "enemy", "neutral"
var target: Unit = null
var is_selected: bool = false
var formation_position: Vector3 = Vector3.ZERO

var attack_timer: float = 0.0
var is_visible: bool = true

@onready var mesh: MeshInstance3D = $Mesh
@onready var health_bar: ProgressBar = $HealthBar
@onready var selection_indicator: MeshInstance3D = $SelectionIndicator

func _ready():
	_setup_unit()
	_update_health_bar()

func _setup_unit():
	# Birim tipine göre görsel ayarları
	match unit_type:
		UnitType.INFANTRY:
			mesh.material.albedo_color = Color(0.2, 0.5, 0.2) if team == "player" else Color(0.8, 0.2, 0.2)
		UnitType.CAVALRY:
			mesh.material.albedo_color = Color(0.6, 0.4, 0.1) if team == "player" else Color(0.7, 0.1, 0.1)
		UnitType.ARCHER:
			mesh.material.albedo_color = Color(0.3, 0.6, 0.1) if team == "player" else Color(0.6, 0.1, 0.1)
		UnitType.SPECIAL:
			mesh.material.albedo_color = Color(0.9, 0.7, 0.1) if team == "player" else Color(0.9, 0.1, 0.1)
	
	selection_indicator.visible = false

func _process(delta):
	if current_state == UnitState.DEAD:
		return
	
	# Saldırı cooldown
	if attack_timer > 0:
		attack_timer -= delta
	
	# Hedef takibi
	if target and is_instance_valid(target):
		if target.current_state == UnitState.DEAD:
			target = null
			current_state = UnitState.IDLE
	
	_update_health_bar()

func _physics_process(delta):
	if current_state == UnitState.MOVING and target:
		move_to_target(delta)

func _input(event):
	# Mobil için dokunmatik seçim
	pass

func move_to_target(delta: float):
	if not target:
		current_state = UnitState.IDLE
		return
	
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	
	var distance = global_position.distance_to(target.global_position)
	
	if distance > attack_range:
		velocity = direction * speed
		move_and_slide()
		current_state = UnitState.MOVING
	else:
		velocity = Vector3.ZERO
		if attack_timer <= 0:
			perform_attack()

func set_target_position(pos: Vector3):
	target = null
	formation_position = pos
	current_state = UnitState.MOVING
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", pos, 1.0 / speed)
	tween.tween_callback(_on_reached_destination)

func perform_attack():
	if not target or attack_timer > 0:
		return
	
	attack_timer = attack_cooldown
	current_state = UnitState.ATTACKING
	
	# Hasar hesaplama
	var actual_damage = max(1, damage - target.defense / 2 + randi() % 5)
	target.take_damage(actual_damage)
	
	unit_attacked.emit(self, target)
	
	# Animasyon
	_play_attack_animation()

func take_damage(amount: int):
	health -= amount
	_show_damage_number(amount)
	
	if health <= 0:
		die()
	else:
		_play_hit_animation()

func die():
	current_state = UnitState.DEAD
	_play_death_animation()
	
	# Ceset sahnesinde kalır
	await get_tree().create_timer(3.0).timeout
	queue_free()
	
	unit_died.emit(self)

func _show_damage_number(amount: int):
	var label = Label3D.new()
	label.text = str(amount)
	label.font_size = 24
	label.position = Vector3(0, 1.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", 3.0, 1.0)
	tween.tween_callback(label.queue_free)

func _update_health_bar():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = health < max_health

func select_unit():
	if current_state == UnitState.DEAD:
		return
	is_selected = true
	selection_indicator.visible = true
	unit_selected.emit(self)

func deselect_unit():
	is_selected = false
	selection_indicator.visible = false
	unit_deselected.emit(self)

func _play_attack_animation():
	# Saldırı animasyonu
	var tween = create_tween()
	tween.tween_property(mesh, "position:z", 0.5, 0.1)
	tween.tween_property(mesh, "position:z", 0.0, 0.1)

func _play_hit_animation():
	var tween = create_tween()
	tween.tween_property(mesh, "self_modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(mesh, "self_modulate", Color(1, 1, 1), 0.2)

func _play_death_animation():
	var tween = create_tween()
	tween.tween_property(mesh, "rotation_degrees:x", 90, 0.5)
	tween.tween_property(self, "scale", Vector3(1, 0.5, 1), 0.3)

func _on_reached_destination():
	current_state = UnitState.IDLE
	unit_moved.emit(self, global_position)

func get_save_data() -> Dictionary:
	return {
		"unit_name": unit_name,
		"unit_type": unit_type,
		"health": health,
		"max_health": max_health,
		"team": team,
		"position": global_position
	}