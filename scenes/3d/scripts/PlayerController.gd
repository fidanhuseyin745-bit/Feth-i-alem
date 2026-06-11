extends CharacterBody3D
class_name PlayerController

## Genshin Impact tarzı oyuncu kontrol sistemi

const ProfessionSystem = preload("res://scenes/3d/scripts/ProfessionSystem.gd")

signal health_changed(new_health: int, max_health: int)
signal stamina_changed(new_stamina: int, max_stamina: int)
signal died()
signal leveled_up(level: int)
signal profession_changed(profession: String)

# Hareket
var move_speed: float = 5.0
var sprint_speed: float = 8.0
var jump_velocity: float = 4.5
var gravity: float = 9.8

# Yetenekler
var can_jump: bool = true
var can_sprint: bool = true
var can_attack: bool = true
var is_combat_mode: bool = false

# Durumlar
var is_running: bool = false
var is_jumping: bool = false
var is_attacking: bool = false
var is_blocking: bool = false

# İstatistikler
var health: int = 100
var max_health: int = 100
var stamina: int = 100
var max_stamina: int = 100
var exp: int = 0
var level: int = 1

# Meslek sistemi
var profession_system: ProfessionSystem
var current_profession: int = ProfessionSystem.Profession.WARRIOR

# Animasyon
@onready var animation_player: AnimationPlayer
@onready var skeleton: Skeleton3D

# Kamera
var camera_pivot: Node3D
var camera_rotation_speed: float = 0.005

# Kontroller
var joystick_input: Vector2 = Vector2.ZERO
var mouse_sensitivity: float = 0.3
var touch_camera_delta: Vector2 = Vector2.ZERO

# Ses efektleri
var footstep_audio: AudioStreamPlayer
var attack_audio: AudioStreamPlayer

func _ready() -> void:
	_setup_player()
	_setup_camera()
	_setup_collision()
	_setup_profession()
	_setup_input()

func _setup_player() -> void:
	# Oyuncu görünümü
	var body = _create_body_mesh()
	add_child(body)
	
	# Vuruş alanı
	var hitbox = Area3D.new()
	hitbox.name = "HitBox"
	add_child(hitbox)
	
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.0
	collision.shape = shape
	hitbox.add_child(collision)

func _create_body_mesh() -> MeshInstance3D:
	var body = MeshInstance3D.new()
	
	# Genshin tarzı karakter
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	body.mesh = capsule
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.15, 0.4)  # Lacivert kıyafet
	mat.roughness = 0.7
	mat.metallic = 0.1
	body.material = mat
	
	# Kafa
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.2
	head.mesh = head_mesh
	head.transform.origin = Vector3(0, 1.3, 0)
	
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.9, 0.75, 0.65)
	head.material = skin_mat
	body.add_child(head)
	
	# Şapka/Başlık
	var hat = MeshInstance3D.new()
	var hat_mesh = CylinderMesh.new()
	hat_mesh.top_radius = 0.15
	hat_mesh.bottom_radius = 0.25
	hat_mesh.height = 0.2
	hat.mesh = hat_mesh
	hat.transform.origin = Vector3(0, 1.5, 0)
	
	var hat_mat = StandardMaterial3D.new()
	hat_mat.albedo_color = Color(0.9, 0.7, 0.1)  # Altın
	hat_mat.emission_enabled = true
	hat_mat.emission = Color(0.9, 0.7, 0.1) * 0.2
	hat.material = hat_mat
	body.add_child(hat)
	
	# Kılıç (sırtta)
	var sword = MeshInstance3D.new()
	var sword_mesh = BoxMesh.new()
	sword_mesh.size = Vector3(0.05, 0.8, 0.02)
	sword.mesh = sword_mesh
	sword.transform.origin = Vector3(0.3, 1.0, -0.2)
	sword.transform.basis = Basis.from_euler(Vector3(0, 0.3, 0.2))
	
	var sword_mat = StandardMaterial3D.new()
	sword_mat.albedo_color = Color(0.8, 0.8, 0.9)
	sword_mat.metallic = 0.9
	sword_mat.roughness = 0.2
	sword.material = sword_mat
	body.add_child(sword)
	
	return body

func _setup_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	
	var camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.fov = 60
	camera.far = 500
	camera.position = Vector3(0, 2, 4)
	camera_pivot.add_child(camera)

func _setup_collision() -> void:
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.35
	collision.shape = shape
	add_child(collision)

func _setup_profession() -> void:
	profession_system = ProfessionSystem.new()

func _setup_input() -> void:
	# Mouse capture
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Yerçekimi
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Hareket
	var input_dir = _get_input_direction()
	
	if input_dir.length() > 0.1:
		# Yürüme
		var target_velocity = input_dir * move_speed
		
		if Input.is_action_pressed("sprint"):
			target_velocity = input_dir * sprint_speed
			is_running = true
			_consume_stamina(delta * 0.5)
		else:
			is_running = false
		
		# Yön hizalama
		var look_dir = Vector3(input_dir.x, 0, input_dir.y)
		transform.basis = transform.basis.slerp(Basis.looking_at(look_dir), delta * 10)
		
		velocity.x = target_velocity.x
		velocity.z = target_velocity.z
		
		# Koşma animasyonu
		_play_animation("run" if is_running else "walk")
	else:
		velocity.x = move_toward(velocity.x, 0, delta * 10)
		velocity.z = move_toward(velocity.z, 0, delta * 10)
		
		if not is_attacking:
			_play_animation("idle")
	
	# Zıplama
	if Input.is_action_just_pressed("jump") and is_on_floor() and can_jump:
		velocity.y = jump_velocity
		is_jumping = true
		_play_animation("jump")
	
	# Hareket et
	move_and_slide()

func _get_input_direction() -> Vector2:
	var input = Vector2.ZERO
	
	# Keyboard
	if Input.is_action_pressed("move_forward"):
		input.y -= 1
	if Input.is_action_pressed("move_backward"):
		input.y += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1
	
	# Joystick
	input += joystick_input
	
	return input.normalized()

func _input(event: InputEvent) -> void:
	# Kamera kontrolü
	if event is InputEventMouseMotion:
		_rotate_camera(event.relative * mouse_sensitivity)
	
	# Touch kamera
	if event is InputEventScreenDrag:
		if event.index == 1:  # İkinci parmak
			_rotate_camera(event.relative * 0.01)
	
	# Saldırı
	if event.is_action_pressed("attack"):
		perform_attack()
	
	# Yetenekler
	if event.is_action_pressed("skill_1"):
		use_skill(1)
	if event.is_action_pressed("skill_2"):
		use_skill(2)
	if event.is_action_pressed("skill_3"):
		use_skill(3)
	
	# Sprint
	if event.is_action_pressed("sprint"):
		is_running = true
	
	# Blok
	if event.is_action_pressed("block"):
		is_blocking = true
		_play_animation("block")
	elif event.is_action_released("block"):
		is_blocking = false

func _rotate_camera(delta: Vector2) -> void:
	camera_pivot.rotate_y(-delta.x)
	
	# Yukarı/aşağı sınırı
	var current_rot = camera_pivot.rotation.x
	current_rot += delta.y
	current_rot = clamp(current_rot, -PI/4, PI/3)
	camera_pivot.rotation.x = current_rot

func perform_attack() -> void:
	if not can_attack or is_attacking:
		return
	
	if stamina < 10:
		return  # Yetersiz stamina
	
	is_attacking = true
	can_attack = false
	
	_consume_stamina(10)
	_play_animation("attack")
	
	# Saldırı Hasarı
	var damage = _calculate_damage()
	var attack_range = 2.0
	
	# Alan kontrolü
	var hitbox = get_node_or_null("HitBox")
	if hitbox:
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = SphereShape3D.new()
		query.shape.radius = attack_range
		query.transform = global_transform
		
		var results = space_state.intersect_shape(query, 10)
		
		for result in results:
			if result["collider"] != self:
				_apply_damage_to_target(result["collider"], damage)
	
	# Saldırı sonu
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	can_attack = true

func _calculate_damage() -> int:
	var base_damage = profession_system.stats["attack"]
	var profession_bonus = profession_system.get_damage_bonus()
	
	return int(base_damage * (1.0 + profession_bonus))

func _apply_damage_to_target(target, damage: int) -> void:
	# Hasar uygula
	if target.has_method("take_damage"):
		target.take_damage(damage)

func use_skill(skill_index: int) -> void:
	var skills = profession_system.get_all_skills()
	if skill_index >= skills.size():
		return
	
	var stamina_cost = [15, 25, 35][skill_index] if skill_index < 3 else 20
	if stamina < stamina_cost:
		return
	
	_consume_stamina(stamina_cost)
	
	match skill_index:
		0:  # Skill 1 - Hızlı vuruş
			_skill_quick_strike()
		1:  # Skill 2 - Güçlü vuruş
			_skill_power_strike()
		2:  # Skill 3 - Özel yetenek
			_skill_ultimate()

func _skill_quick_strike() -> void:
	_play_animation("skill_1")
	move_speed *= 1.5
	await get_tree().create_timer(2.0).timeout
	move_speed /= 1.5

func _skill_power_strike() -> void:
	_play_animation("skill_2")
	# Güçlü saldırı
	var damage = _calculate_damage() * 2
	# Alan hasarı
	_apply_area_damage(global_transform.origin, 3.0, damage)

func _skill_ultimate() -> void:
	_play_animation("skill_3")
	# Ultimate - tüm düşmanlara hasar
	var damage = _calculate_damage() * 3
	_apply_area_damage(global_transform.origin, 10.0, damage)
	
	# Stamina yenileme
	restore_stamina(30)

func _apply_area_damage(origin: Vector3, radius: float, damage: int) -> void:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = SphereShape3D.new()
	query.shape.radius = radius
	query.transform.origin = origin
	
	var results = space_state.intersect_shape(query, 20)
	
	for result in results:
		if result["collider"] != self:
			_apply_damage_to_target(result["collider"], damage)

func _consume_stamina(amount: float) -> void:
	stamina = max(0, stamina - int(amount))
	stamina_changed.emit(stamina, max_stamina)

func restore_stamina(amount: int) -> void:
	stamina = min(max_stamina, stamina + amount)
	stamina_changed.emit(stamina, max_stamina)

func take_damage(amount: int) -> void:
	# Savunma hesapla
	var defense = profession_system.stats["defense"]
	var defense_bonus = profession_system.get_defense_bonus()
	var reduction = defense * (1.0 + defense_bonus) * 0.1
	
	var final_damage = max(1, amount - int(reduction))
	
	health -= final_damage
	health_changed.emit(health, max_health)
	
	_play_animation("hit")
	
	if health <= 0:
		die()

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

func gain_exp(amount: int) -> void:
	exp += amount
	profession_system.add_exp(amount)
	
	while exp >= level * 100:
		level_up()

func level_up() -> void:
	level += 1
	exp -= level * 100
	
	max_health += 20
	max_stamina += 10
	health = max_health
	stamina = max_stamina
	
	leveled_up.emit(level)
	_play_animation("level_up")

func die() -> void:
	_play_animation("death")
	died.emit()

func change_profession(profession_id: int) -> void:
	if profession_system.unlock_profession(profession_id, 0):
		profession_system.change_profession(profession_id)
		current_profession = profession_id
		
		# İstatistik güncelleme
		_apply_profession_stats()
		
		profession_changed.emit(profession_system.get_profession_name())

func _apply_profession_stats() -> void:
	move_speed = 5.0 + profession_system.stats["speed"] * 0.1
	max_health = 100 + profession_system.stats["health"]
	max_stamina = 100 + profession_system.stats["stamina"] * 0.5

func _play_animation(anim_name: String) -> void:
	# Animasyon oynat (placeholder - gerçek animasyonlar eklenecek)
	pass

func set_joystick_input(input: Vector2) -> void:
	joystick_input = input

func get_current_stats() -> Dictionary:
	return {
		"health": health,
		"max_health": max_health,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"level": level,
		"exp": exp,
		"profession": profession_system.get_profession_name(),
		"attack": profession_system.stats["attack"],
		"defense": profession_system.stats["defense"]
	}