extends CharacterBody3D
class_name PlayerCharacter

## Ana oyuncu karakteri - 3D açık dünya kontrolü

signal player_moved(pos: Vector3)
signal player_state_changed(state: String)
signal level_up(level: int)
signal health_changed(current: int, max: int)
signal energy_changed(current: int, max: int)

const ProfessionSystem = preload("res://scenes/3d/scripts/ProfessionSystem.gd")

# Temel özellikler
@export var player_name: String = "Savaşçı"

# Sağlık ve Enerji
var health: int = 100
var max_health: int = 100
var energy: int = 100
var max_energy: int = 100

# Seviye ve deneyim
var level: int = 1
var experience: int = 0
var experience_to_next: int = 100

# Altın ve envanter
var gold: int = 100
var inventory: Array[Dictionary] = []

# Meslek sistemi
var profession_system: ProfessionSystem
var current_profession: int = ProfessionSystem.Profession.NONE

# Durumlar
enum PlayerState { IDLE, WALKING, RUNNING, FIGHTING, TRADING, CRAFTING, RESTING }
var current_state: PlayerState = PlayerState.IDLE

# Hareket
@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0
@export var jump_force: float = 8.0
@export var gravity: float = 20.0

var velocity: Vector3 = Vector3.ZERO
var is_grounded: bool = false
var is_running: bool = false

# Referanslar
@onready var mesh: MeshInstance3D = $Mesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Mobil kontrol
var joystick_input: Vector2 = Vector2.ZERO
var camera_target: Vector3 = Vector3.ZERO

# Yetenekler
var unlocked_skills: Array[String] = []
var cooldowns: Dictionary = {}

func _ready():
	_setup_player()
	_setup_profession_system()

func _setup_player():
	# Varsayılan mesh
	if not mesh:
		var mesh_node = MeshInstance3D.new()
		var capsule = CapsuleMesh.new()
		capsule.material = StandardMaterial3D.new()
		capsule.material.albedo_color = Color(0.9, 0.7, 0.1)  # Osmanlı sarı
		mesh_node.mesh = capsule
		mesh_node.name = "Mesh"
		add_child(mesh_node)
		mesh = mesh_node
	
	# Çarpışma
	if not collision_shape:
		var shape = CapsuleShape3D.new()
		shape.height = 1.8
		shape.radius = 0.4
		collision_shape = CollisionShape3D.new()
		collision_shape.shape = shape
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)
	
	# Animasyon
	if not animation_player:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		add_child(animation_player)
	
	health_changed.emit(health, max_health)
	energy_changed.emit(energy, max_energy)

func _setup_profession_system():
	profession_system = ProfessionSystem.new()
	add_child(profession_system)

func _physics_process(delta):
	_handle_movement(delta)
	_update_animations()
	_regenerate_resources(delta)

func _handle_movement(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var input_dir = Vector2.ZERO
	
	# Mobil joystick
	if joystick_input != Vector2.ZERO:
		input_dir = joystick_input
	else:
		# Klavye
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	var speed = run_speed if is_running else walk_speed
	
	# Yön hesaplama
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		
		# Kameraya göre yön
		var camera = get_viewport().get_camera_3d()
		if camera:
			var cam_forward = camera.global_transform.basis.z
			var cam_right = camera.global_transform.basis.x
			cam_forward.y = 0
			cam_right.y = 0
			cam_forward = cam_forward.normalized()
			cam_right = cam_right.normalized()
			
			velocity.x = (cam_right.x * input_dir.x + cam_forward.x * input_dir.y) * speed
			velocity.z = (cam_right.z * input_dir.x + cam_forward.z * input_dir.y) * speed
		
		current_state = PlayerState.RUNNING if is_running else PlayerState.WALKING
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 10)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 10)
		
		if velocity.x == 0 and velocity.z == 0:
			current_state = PlayerState.IDLE
	
	move_and_slide()
	player_moved.emit(global_position)

func _update_animations():
	match current_state:
		PlayerState.IDLE:
			_play_animation("idle")
		PlayerState.WALKING:
			_play_animation("walk")
		PlayerState.RUNNING:
			_play_animation("run")
		PlayerState.FIGHTING:
			_play_animation("attack")
		_:
			_play_animation("idle")

func _play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		# Basit tween animasyonu
		pass

func _regenerate_resources(delta: float):
	# Enerji yenileme
	if current_state == PlayerState.IDLE or current_state == PlayerState.RESTING:
		energy = min(energy + 5 * delta, max_energy)
		energy_changed.emit(energy, max_energy)
	
	# Sağlık yenileme (dinlenirken)
	if current_state == PlayerState.RESTING:
		health = min(health + 2 * delta, max_health)
		health_changed.emit(health, max_health)

# ── Eylemler ──────────────────────────────────────────────────────────────

func take_damage(amount: int):
	var actual_damage = profession_system.get_total_defense(amount)
	health -= actual_damage
	health_changed.emit(health, max_health)
	
	if health <= 0:
		die()
	
	# Hasar efekti
	_play_damage_effect()

func heal(amount: int):
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func use_energy(amount: int) -> bool:
	if energy >= amount:
		energy -= amount
		energy_changed.emit(energy, max_energy)
		return true
	return false

func gain_experience(amount: int):
	experience += amount
	while experience >= experience_to_next:
		experience -= experience_to_next
		level_up_internal()

func level_up_internal():
	level += 1
	experience_to_next = 100 + (level * 50)
	
	# Bonuslar
	max_health += 10
	max_energy += 5
	health = max_health
	energy = max_energy
	
	level_up.emit(level)
	health_changed.emit(health, max_health)
	energy_changed.emit(energy, max_energy)

func die():
	current_state = PlayerState.RESTING
	health = max_health * 0.5  # Yarı canla yeniden doğma
	health_changed.emit(health, max_health)
	position = Vector3(0, 2, 0)  # Başlangıç noktası

# ── Meslek Eylemleri ───────────────────────────────────────────────────────

func set_profession(prof: int) -> bool:
	if profession_system.set_profession(prof):
		current_profession = prof
		return true
	return false

func get_profession_name() -> String:
	return profession_system.get_current_profession_name()

func get_profession_stats() -> Dictionary:
	return profession_system.stat_bonuses

# ── Envanter ──────────────────────────────────────────────────────────────

func add_item(item: Dictionary):
	inventory.append(item)

func remove_item(item_name: String) -> bool:
	for i in inventory.size():
		if inventory[i].get("name") == item_name:
			inventory.remove_at(i)
			return true
	return false

func has_item(item_name: String) -> bool:
	for item in inventory:
		if item.get("name") == item_name:
			return true
	return false

func get_item_count(item_name: String) -> int:
	var count = 0
	for item in inventory:
		if item.get("name") == item_name:
			count += item.get("count", 1)
	return count

func add_gold(amount: int):
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

# ── Yetenekler ────────────────────────────────────────────────────────────

func use_skill(skill_name: String) -> bool:
	if cooldowns.has(skill_name) and cooldowns[skill_name] > 0:
		return false
	
	if skill_name in unlocked_skills:
		_cooldown_skill(skill_name, 5.0)
		return true
	return false

func _cooldown_skill(skill_name: String, duration: float):
	cooldowns[skill_name] = duration

func _process(delta: float):
	# Yetenek cooldown güncelleme
	for skill in cooldowns:
		cooldowns[skill] = max(0, cooldowns[skill] - delta)

# ── Durum Değişiklikleri ───────────────────────────────────────────────────

func set_state(state: PlayerState):
	current_state = state
	player_state_changed.emit(_get_state_name(state))

func _get_state_name(state: PlayerState) -> String:
	match state:
		PlayerState.IDLE: return "Bekliyor"
		PlayerState.WALKING: return "Yürüyor"
		PlayerState.RUNNING: return "Koşuyor"
		PlayerState.FIGHTING: return "Savaşıyor"
		PlayerState.TRADING: return "Ticaret"
		PlayerState.CRAFTING: return "Üretim"
		PlayerState.RESTING: return "Dinleniyor"
		_: return "Bilinmiyor"

func start_fighting():
	set_state(PlayerState.FIGHTING)

func stop_fighting():
	set_state(PlayerState.IDLE)

func start_trading():
	set_state(PlayerState.TRADING)

func start_crafting():
	set_state(PlayerState.CRAFTING)

func rest():
	set_state(PlayerState.RESTING)

# ── Hareket Kontrolü ──────────────────────────────────────────────────────

func set_joystick_input(input: Vector2):
	joystick_input = input

func toggle_run():
	is_running = !is_running

func move_to(target: Vector3):
	var direction = (target - global_position).normalized()
	look_at(target)
	velocity = direction * run_speed

# ── Bilgi ─────────────────────────────────────────────────────────────────

func get_info() -> Dictionary:
	return {
		"name": player_name,
		"level": level,
		"profession": get_profession_name(),
		"health": "%d/%d" % [health, max_health],
		"energy": "%d/%d" % [energy, max_energy],
		"gold": gold,
		"experience": "%d/%d" % [experience, experience_to_next],
		"state": _get_state_name(current_state)
	}

func get_save_data() -> Dictionary:
	return {
		"player_name": player_name,
		"position": global_position,
		"health": health,
		"max_health": max_health,
		"energy": energy,
		"max_energy": max_energy,
		"level": level,
		"experience": experience,
		"gold": gold,
		"inventory": inventory,
		"current_profession": current_profession
	}

func load_save_data(data: Dictionary):
	player_name = data.get("player_name", "Savaşçı")
	global_position = data.get("position", Vector3.ZERO)
	health = data.get("health", 100)
	max_health = data.get("max_health", 100)
	energy = data.get("energy", 100)
	max_energy = data.get("max_energy", 100)
	level = data.get("level", 1)
	experience = data.get("experience", 0)
	gold = data.get("gold", 100)
	inventory = data.get("inventory", [])
	current_profession = data.get("current_profession", ProfessionSystem.Profession.NONE)
	
	if current_profession != ProfessionSystem.Profession.NONE:
		profession_system.set_profession(current_profession)

func _play_damage_effect():
	var tween = create_tween()
	tween.tween_property(mesh, "self_modulate", Color(1, 0, 0), 0.1)
	tween.tween_property(mesh, "self_modulate", Color(1, 1, 1), 0.2)