extends Node3D

var gold = 5000
var turn = 1
var cities = []
var units = []

var camera_h_speed = 0.005
var camera_v_speed = 0.005
var move_speed = 100.0
var touch_look_id = -1
@onready var camera_pivot = $CameraPivot # This will need to be added to the scene later

@onready var ground = $Ground/Mesh
@onready var cities_node = $Cities
@onready var units_node = $Units
@onready var ui = $UI

func _ready():
	Engine.max_fps = 30
	generate_terrain()
	build_medieval_metropolis()
	call_deferred("setup_cities")
	call_deferred("spawn_units")
	update_ui()
	# Initialize camera pivot for open-world exploration
	if camera_pivot:
		camera_pivot.global_position = Vector3(0, 50, 0)
	else:
		print("Hata: camera_pivot sahneye eklenmemiş!") # Hata mesajı

func build_medieval_metropolis():
	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_texture = load("res://assets/textures/stone_4k.png")
	stone_mat.uv1_scale = Vector3(0.1, 0.1, 0.1)
	stone_mat.uv1_triplanar = true
	
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.3, 0.1)
	
	# World positions with height adjustment
	var castle_pos = [Vector2(500, 500), Vector2(-600, -400), Vector2(800, -800)]
	for pos_2d in castle_pos:
		var cp = Vector3(pos_2d.x, 0, pos_2d.y)
		
		# Find height
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = Vector3(cp.x, 1000, cp.z)
		query.to = Vector3(cp.x, -1000, cp.z)
		var result = space_state.intersect_ray(query)
		if result: cp.y = result.position.y

		var castle = Node3D.new()
		castle.position = cp
		add_child(castle)
		# Ana Kule
		var keep = MeshInstance3D.new()
		keep.mesh = BoxMesh.new(); keep.mesh.size = Vector3(60, 120, 60)
		keep.position = Vector3(0, 60, 0); keep.material_override = stone_mat
		castle.add_child(keep)
		# 4 Köşe Kulesi
		for i in range(4):
			var tower = MeshInstance3D.new()
			tower.mesh = CylinderMesh.new(); tower.mesh.top_radius = 20; tower.mesh.bottom_radius = 20; tower.mesh.height = 80
			tower.position = Vector3(cos(i * PI/2) * 80, 40, sin(i * PI/2) * 80)
			tower.material_override = stone_mat
			castle.add_child(tower)
		# Duvarlar
		for i in range(4):
			var wall = MeshInstance3D.new()
			wall.mesh = BoxMesh.new(); wall.mesh.size = Vector3(120, 60, 20)
			wall.position = Vector3(cos(i * PI/2 + PI/4) * 50, 30, sin(i * PI/2 + PI/4) * 50)
			wall.rotation_degrees.y = i * 90 + 45
			wall.material_override = stone_mat
			castle.add_child(wall)

	# Şablon 2: Küçük Köy (Village Template)
	var village_pos = [Vector2(-500, 500), Vector2(600, -400)]
	for pos_2d in village_pos:
		var vp = Vector3(pos_2d.x, 0, pos_2d.y)
		
		# Find height
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = Vector3(vp.x, 1000, vp.z)
		query.to = Vector3(vp.x, -1000, vp.z)
		var result = space_state.intersect_ray(query)
		if result: vp.y = result.position.y

		var village = Node3D.new()
		village.position = vp
		add_child(village)
		for i in range(8):
			var house = MeshInstance3D.new()
			house.mesh = BoxMesh.new(); house.mesh.size = Vector3(20, 20, 20)
			house.position = Vector3(randf_range(-60, 60), 10, randf_range(-60, 60))
			house.material_override = wood_mat
			village.add_child(house)
			# Çatı
			var roof = MeshInstance3D.new()
			var r_mesh = CylinderMesh.new(); r_mesh.top_radius = 0; r_mesh.bottom_radius = 15; r_mesh.height = 15
			roof.mesh = r_mesh; roof.position = house.position + Vector3(0, 17.5, 0)
			var r_mat = StandardMaterial3D.new(); r_mat.albedo_color = Color(0.5, 0.1, 0.1)
			roof.material_override = r_mat
			village.add_child(roof)

func setup_cities():
	cities = [
		{"name": "İstanbul", "x": 0, "y": 0, "owner": "byzantine", "troops": 3000, "income": 500},
		{"name": "Edirne", "x": -80, "y": -30, "owner": "ottoman", "troops": 5000, "income": 300},
		{"name": "Bursa", "x": 50, "y": 60, "owner": "ottoman", "troops": 2000, "income": 200},
		{"name": "Selanik", "x": -60, "y": 50, "owner": "ottoman", "troops": 1500, "income": 180},
		{"name": "Karaman", "x": 100, "y": 80, "owner": "karamanid", "troops": 2500, "income": 160},
	]
	
	for c in cities:
		var m = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(8, 5, 8)
		m.mesh = box
		m.position = Vector3(c["x"], 2.5, c["y"])
		
		var mat = StandardMaterial3D.new()
		if c["owner"] == "ottoman":
			mat.albedo_color = Color(0.9, 0.7, 0.1)
		elif c["owner"] == "byzantine":
			mat.albedo_color = Color(0.3, 0.5, 0.9)
		else:
			mat.albedo_color = Color(0.2, 0.7, 0.4)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.material = mat
		
		var l = Label3D.new()
		l.text = c["name"]
		l.font_size = 32
		l.position = Vector3(0, 6, 0)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		m.add_child(l)
		
		cities_node.add_child(m)

func spawn_units():
	for i in range(5):
		var u = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1, 1.5, 1)
		u.mesh = box
		u.position = Vector3(-80 + randf() * 20, 0.75, -30 + randf() * 20)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.6, 0.2)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		u.material = mat
		
		units_node.add_child(u)
		units.append(u)

func end_turn():
	turn += 1
	var income = 0
	for c in cities:
		if c["owner"] == "ottoman":
			income += c["income"]
	gold += income
	update_ui()
	show_msg("Tur %d +%d altın" % [turn, income])

func update_ui():
	ui.get_node("Gold").text = "🪙 %d" % gold
	ui.get_node("Turn").text = "Tur: %d" % turn

func show_msg(m):
	ui.get_node("Msg").text = m
	ui.get_node("Msg").visible = true
	await get_tree().create_timer(3).timeout
	ui.get_node("Msg").visible = false


func _on_end_turn_pressed():
	end_turn()

func _process(delta):
	var dir = Vector3.ZERO
	var cam_basis = camera_pivot.global_transform.basis
	if Input.is_action_pressed("move_forward"): dir -= cam_basis.z
	if Input.is_action_pressed("move_backward"): dir += cam_basis.z
	if Input.is_action_pressed("move_left"): dir -= cam_basis.x
	if Input.is_action_pressed("move_right"): dir += cam_basis.x
	
	dir.y = 0
	if dir != Vector3.ZERO:
		camera_pivot.global_position += dir.normalized() * move_speed * delta
	
	# Keep camera above terrain
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = camera_pivot.global_position + Vector3(0, 1000, 0)
	query.to = camera_pivot.global_position + Vector3(0, -1000, 0)
	var result = space_state.intersect_ray(query)
	
	if result:
		var target_y = result.position.y + 50.0 # Height above ground
		camera_pivot.global_position.y = lerp(camera_pivot.global_position.y, target_y, 0.1)

func _input(event):
	# Bakış kontrolü için ekranın sağ yarısını kullan
	if event is InputEventScreenTouch:
		if event.pressed:
			# Eğer dokunma ekranın sağ yarısındaysa, bakış kontrolünü başlat
			if event.position.x > get_viewport().size.x / 2:
				touch_look_id = event.index
		else:
			# Dokunma bırakıldığında eğer bu bakış ID'siyse sıfırla
			if event.index == touch_look_id:
				touch_look_id = -1
				
	if event is InputEventScreenDrag:
		# Sadece bakış kontrolü için atanmış dokunma ID'si ile sürükleme yapılıyorsa kamerayı döndür
		if event.index == touch_look_id:
			# Yatay dönüş (Dünya ekseninde Y)
			camera_pivot.rotate_y(-event.relative.x * camera_h_speed)
			# Dikey dönüş (Kendi ekseninde X)
			var new_rot_x = camera_pivot.rotation.x - event.relative.y * camera_v_speed
			camera_pivot.rotation.x = clamp(new_rot_x, deg_to_rad(-70), deg_to_rad(30))

